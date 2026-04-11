const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();

// ── Config ────────────────────────────────────────────────────────────────────
const ONESIGNAL_APP_ID = "90f7c5c6-b51f-466a-acdb-a4829b419363";
const ONESIGNAL_API_KEY = "os_v2_app_sd34lrvvd5dgvlg3usbjwqmtmnkyn3llzrou5amwfr35ndpvxhxqxagknlesssypciia4ds5chlbmggfvji74wc5cuu3dtfgdftcnnq";

// Cloudinary
const CLOUDINARY_CLOUD_NAME = "dxbpni461";
const CLOUDINARY_API_KEY = "584585347671137";
const CLOUDINARY_API_SECRET = "9SBKvRpGYq4Ou6MLPxwplSxD2n8";

// ── Helper: send OneSignal notification ───────────────────────────────────────
async function sendNotification(externalUserIds, title, body, data = {}) {
  try {
    await axios.post(
      "https://onesignal.com/api/v1/notifications",
      {
        app_id: ONESIGNAL_APP_ID,
        include_external_user_ids: externalUserIds,
        contents: { en: body },
        headings: { en: title },
        data,
      },
      { headers: { Authorization: `Basic ${ONESIGNAL_API_KEY}` } }
    );
  } catch (e) {
    console.error("OneSignal error:", e.response?.data || e.message);
  }
}

// ── FUNCTION 1: New order → notify restaurant ─────────────────────────────────
exports.onOrderCreated = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const orderId = context.params.orderId;

    if (!order.restaurantId) return;

    await sendNotification(
      [order.restaurantId],
      "🍽️ New Order Received!",
      `Order #${orderId.slice(-6).toUpperCase()} — ₹${order.totalAmount}. Tap to accept.`,
      { orderId, type: "new_order" }
    );

    console.log(`Notified restaurant ${order.restaurantId} for order ${orderId}`);
  });

// ── FUNCTION 2: Order status changes → send notifications ───────────────────────
exports.onOrderUpdated = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const orderId = context.params.orderId;

    // Restaurant accepts order (placed → preparing) → notify customer
    if (before.status === "placed" && after.status === "preparing") {
      await sendNotification(
        [after.customerId],
        "🍳 Order Accepted!",
        `${after.restaurantName} has accepted your order. Preparing your food now.`,
        { orderId, type: "order_accepted" }
      );
    }

    // Driver assigned → notify driver
    if (!before.driverId && after.driverId) {
      await sendNotification(
        [after.driverId],
        "🚚 New Delivery Assigned!",
        `Order #${orderId.slice(-6).toUpperCase()} from ${after.restaurantName}. Tap to view.`,
        { orderId, type: "driver_assigned" }
      );
    }

    // Out for delivery → notify customer
    if (before.status !== "picked" && after.status === "picked") {
      await sendNotification(
        [after.customerId],
        "🛵 Order On The Way!",
        `Your order is out for delivery. Estimated 20-30 mins.`,
        { orderId, type: "out_for_delivery" }
      );
    }

    // Delivered → notify customer
    if (before.status !== "delivered" && after.status === "delivered") {
      await sendNotification(
        [after.customerId],
        "✅ Order Delivered!",
        `Your order has been delivered. Enjoy your meal!`,
        { orderId, type: "delivered" }
      );

      // Trigger commission calculation
      await calculateCommission(orderId, after);
    }
  });

// ── FUNCTION 3: Commission calculation on delivery ────────────────────────────
async function calculateCommission(orderId, order) {
  try {
    const restaurantSnap = await db.collection("restaurants").doc(order.restaurantId).get();
    if (!restaurantSnap.exists) return;

    const commission = restaurantSnap.data().commission || 10; // percent
    const commissionAmount = order.totalAmount * (commission / 100);
    const restaurantAmount = order.totalAmount - commissionAmount;

    // Write transaction
    await db.collection("transactions").add({
      orderId,
      restaurantId: order.restaurantId,
      commission: commissionAmount,
      restaurantAmount,
      totalAmount: order.totalAmount,
      type: "commission",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Credit restaurant wallet
    await db.collection("restaurants").doc(order.restaurantId).update({
      wallet: admin.firestore.FieldValue.increment(restaurantAmount),
    });

    // If COD: update driver settlement
    if (order.paymentType === "cod" && order.driverId) {
      await db.collection("settlements").doc(order.driverId).set(
        {
          driverId: order.driverId,
          codCollected: admin.firestore.FieldValue.increment(order.totalAmount),
          pending: admin.firestore.FieldValue.increment(order.totalAmount),
          submitted: admin.firestore.FieldValue.increment(0),
        },
        { merge: true }
      );
      // Update driver today stats
      await db.collection("drivers").doc(order.driverId).update({
        todayOrders: admin.firestore.FieldValue.increment(1),
        codCollected: admin.firestore.FieldValue.increment(order.totalAmount),
      });
    } else if (order.driverId) {
      await db.collection("drivers").doc(order.driverId).update({
        todayOrders: admin.firestore.FieldValue.increment(1),
      });
    }

    console.log(`Commission calculated for order ${orderId}: ₹${commissionAmount} commission, ₹${restaurantAmount} to restaurant`);
  } catch (e) {
    console.error("Commission calculation error:", e);
  }
}

// ── FUNCTION 4: New user registered → notify admin ───────────────────────────
exports.onUserCreated = functions.firestore
  .document("users/{userId}")
  .onCreate(async (snap) => {
    const user = snap.data();
    if (user.role === "customer") return; // customers don't need approval

    // Notify all admins
    const adminsSnap = await db.collection("users").where("role", "==", "admin").get();
    const adminIds = adminsSnap.docs.map((d) => d.id);
    if (adminIds.length === 0) return;

    const roleLabel = user.role === "driver" ? "Driver" : "Restaurant";
    await sendNotification(
      adminIds,
      `🆕 New ${roleLabel} Registration`,
      `${user.name || user.phone} has registered as a ${user.role}. Review and approve.`,
      { userId: snap.id, type: "new_registration", role: user.role }
    );
  });

// ── LOYALTY PROGRAM FUNCTIONS ─────────────────────────────────────────────────

// Helper: Determine loyalty tier based on total points
function getTierFromPoints(totalPoints) {
  if (totalPoints >= 10000) return "Platinum";
  if (totalPoints >= 3000) return "Gold";
  if (totalPoints >= 1000) return "Silver";
  return "Bronze";
}

// Helper: Calculate tier-specific bonus
function getTierBonus(tier) {
  switch (tier) {
    case "Platinum": return 0.10; // 10% bonus
    case "Gold": return 0.05; // 5% bonus
    case "Silver": return 0.0; // No bonus
    case "Bronze": return 0.0;
    default: return 0.0;
  }
}

// ── FUNCTION 5: Calculate loyalty points on order delivery ───────────────────
exports.calculateLoyaltyPoints = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const orderId = context.params.orderId;

    // Only process when status changes to "delivered"
    if (before.status === "delivered" || after.status !== "delivered") {
      return;
    }

    try {
      const customerId = after.customerId;
      const orderAmount = after.totalAmount || 0;
      
      if (!customerId) {
        console.error(`calculateLoyaltyPoints: Missing customerId for order ${orderId}`);
        return;
      }

      if (orderAmount <= 0) {
        console.error(`calculateLoyaltyPoints: Invalid order amount ${orderAmount} for order ${orderId}`);
        return;
      }

      // Fetch user's loyalty document (create if doesn't exist)
      const loyaltyRef = db.collection("loyalty_points").doc(customerId);
      const loyaltySnap = await loyaltyRef.get();
      
      // Calculate points (1 point per ₹1 spent)
      const basePoints = Math.floor(orderAmount);
      
      // Get current tier
      let currentTier = "Bronze";
      let currentPoints = 0;
      if (loyaltySnap.exists) {
        const loyaltyData = loyaltySnap.data();
        currentTier = loyaltyData.tier || "Bronze";
        currentPoints = loyaltyData.balance || 0;
      }

      // Apply tier bonus
      const bonusMultiplier = getTierBonus(currentTier);
      const bonusPoints = Math.floor(basePoints * bonusMultiplier);
      const totalPointsEarned = basePoints + bonusPoints;

      // Write transaction with batched writes
      const batch = db.batch();
      
      // Update loyalty points document
      batch.set(loyaltyRef, {
        userId: customerId,
        balance: admin.firestore.FieldValue.increment(totalPointsEarned),
        lifetimePoints: admin.firestore.FieldValue.increment(totalPointsEarned),
        tier: currentTier,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });

      // Create point transaction record
      const transactionRef = db.collection("point_transactions").doc();
      batch.set(transactionRef, {
        userId: customerId,
        orderId: orderId,
        points: totalPointsEarned,
        orderAmount: orderAmount,
        basePoints: basePoints,
        bonusPoints: bonusPoints,
        tier: currentTier,
        transactionType: "earn",
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      await batch.commit();

      console.log(`Loyalty points calculated: Order ${orderId}, User ${customerId}, Points ${totalPointsEarned} (Base: ${basePoints}, Bonus: ${bonusPoints})`);

      // Check for tier upgrade in a separate operation (after loyalty doc updated)
      await checkTierUpgrade(customerId);

    } catch (error) {
      console.error(`calculateLoyaltyPoints error for order ${orderId}:`, error);
    }
  });

// Helper: Check and upgrade user tier
async function checkTierUpgrade(userId) {
  try {
    const loyaltyRef = db.collection("loyalty_points").doc(userId);
    const loyaltySnap = await loyaltyRef.get();
    
    if (!loyaltySnap.exists) return;
    
    const loyaltyData = loyaltySnap.data();
    const lifetimePoints = loyaltyData.lifetimePoints || 0;
    const currentTier = loyaltyData.tier || "Bronze";
    
    const newTier = getTierFromPoints(lifetimePoints);
    
    if (newTier !== currentTier) {
      await loyaltyRef.update({
        tier: newTier,
        tierUpgradedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`Tier upgrade: User ${userId} upgraded from ${currentTier} to ${newTier}`);
      
      // Send notification about tier upgrade
      await sendNotification(
        [userId],
        `🎉 Tier Upgrade: ${newTier}!`,
        `Congratulations! You've been upgraded to ${newTier} tier with ${lifetimePoints} points.`,
        { tier: newTier, userId, type: "tier_upgrade" }
      );
    }
  } catch (error) {
    console.error(`checkTierUpgrade error for user ${userId}:`, error);
  }
}

// ── FUNCTION 6: Process reward redemption (HTTP) ───────────────────────────────
exports.processRewardRedemption = functions.https.onRequest(async (req, res) => {
  // CORS headers
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  
  if (req.method === "OPTIONS") {
    res.status(200).end();
    return;
  }
  
  try {
    // Verify authentication
    if (!req.headers.authorization) {
      res.status(401).json({ error: "Unauthorized: Missing authentication" });
      return;
    }

    const idToken = req.headers.authorization.split("Bearer ")[1];
    if (!idToken) {
      res.status(401).json({ error: "Unauthorized: Invalid token format" });
      return;
    }

    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const userId = decodedToken.uid;

    // Validate request body
    const { rewardId, pointsRequired } = req.body;
    
    if (!rewardId || typeof rewardId !== "string") {
      res.status(400).json({ error: "Invalid rewardId" });
      return;
    }

    if (!pointsRequired || isNaN(parseInt(pointsRequired)) || parseInt(pointsRequired) <= 0) {
      res.status(400).json({ error: "Invalid pointsRequired" });
      return;
    }

    const pointsNeeded = parseInt(pointsRequired);

    // Check user's point balance
    const loyaltyRef = db.collection("loyalty_points").doc(userId);
    const loyaltySnap = await loyaltyRef.get();
    
    if (!loyaltySnap.exists) {
      res.status(400).json({ error: "User has no loyalty points account" });
      return;
    }

    const userPoints = loyaltySnap.data().balance || 0;
    
    if (userPoints < pointsNeeded) {
      res.status(400).json({ 
        error: "Insufficient points", 
        required: pointsNeeded, 
        available: userPoints 
      });
      return;
    }

    // Perform redemption with batched writes
    const redemptionId = db.collection("redemptions").doc().id;
    const batch = db.batch();
    
    // Deduct points from user
    batch.update(loyaltyRef, {
      balance: admin.firestore.FieldValue.increment(-pointsNeeded),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Create redemption record
    const redemptionRef = db.collection("redemptions").doc(redemptionId);
    batch.set(redemptionRef, {
      userId: userId,
      rewardId: rewardId,
      pointsRedeemed: pointsNeeded,
      status: "completed",
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await batch.commit();

    console.log(`Reward redeemed: User ${userId}, Reward ${rewardId}, Points ${pointsNeeded}`);

    res.status(200).json({
      success: true,
      redemptionId: redemptionId,
      remainingPoints: userPoints - pointsNeeded,
      message: "Reward redeemed successfully"
    });

  } catch (error) {
    console.error("processRewardRedemption error:", error);
    
    if (error.code === "auth/id-token-expired") {
      res.status(401).json({ error: "Unauthorized: Token expired" });
    } else if (error.code === "auth/argument-error") {
      res.status(401).json({ error: "Unauthorized: Invalid token" });
    } else {
      res.status(500).json({ error: "Internal server error", details: error.message });
    }
  }
});

// ── FUNCTION 7: Expire points older than 365 days (Weekly) ─────────────────────
exports.expirePoints = functions.pubsub.schedule("0 2 * * 0") // Every Sunday at 2 AM
  .timeZone("Asia/Kolkata")
  .onRun(async (context) => {
    try {
      console.log("Starting weekly points expiration check");
      
      const oneYearAgo = new Date();
      oneYearAgo.setDate(oneYearAgo.getDate() - 365);
      
      // Find earned point transactions older than 365 days that haven't been expired
      const oldTransactionsSnap = await db.collection("point_transactions")
        .where("transactionType", "==", "earn")
        .where("createdAt", "<=", oneYearAgo)
        .where("expired", "!=", true)
        .get();
      
      const batch = db.batch();
      let expiredCount = 0;
      let totalPointsExpired = 0;
      
      for (const doc of oldTransactionsSnap.docs) {
        const transactionData = doc.data();
        const userId = transactionData.userId;
        const points = transactionData.points || 0;
        
        // Mark transaction as expired
        batch.update(doc.ref, {
          expired: true,
          expiredAt: admin.firestore.FieldValue.serverTimestamp()
        });
        
        // Decrement user's balance
        const loyaltyRef = db.collection("loyalty_points").doc(userId);
        batch.update(loyaltyRef, {
          balance: admin.firestore.FieldValue.increment(-points),
          pointsExpired: admin.firestore.FieldValue.increment(points)
        });
        
        expiredCount++;
        totalPointsExpired += points;
      }
      
      if (expiredCount > 0) {
        await batch.commit();
        console.log(`Expired ${expiredCount} transactions, total points ${totalPointsExpired}`);
      } else {
        console.log("No points needed expiration this run");
      }
      
      return null;
      
    } catch (error) {
      console.error("expirePoints error:", error);
      throw error;
    }
  });

// ── FUNCTION 8: Cleanup search history older than 30 days (Daily) ────────────
exports.cleanupSearchHistory = functions.pubsrc.schedule("0 3 * * *") // Every day at 3 AM
  .timeZone("Asia/Kolkata")
  .onRun(async (context) => {
    try {
      console.log("Starting daily search history cleanup");
      
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      // Find and delete old search history records
      const oldSearchSnap = await db.collection("search_history")
        .where("timestamp", "<=", thirtyDaysAgo)
        .get();
      
      let deletedCount = 0;
      const batch = db.batch();
      
      for (const doc of oldSearchSnap.docs) {
        batch.delete(doc.ref);
        deletedCount++;
        
        // Commit in batches of 500 (Firestore limit)
        if (deletedCount % 500 === 0) {
          await batch.commit();
          console.log(`Deleted ${deletedCount} search history records so far`);
        }
      }
      
      if (deletedCount > 0) {
        await batch.commit();
        console.log(`Total search history records deleted: ${deletedCount}`);
      } else {
        console.log("No search history records needed cleanup");
      }
      
      return null;
      
    } catch (error) {
      console.error("cleanupSearchHistory error:", error);
      throw error;
    }
  });
