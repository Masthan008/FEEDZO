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

// ── FUNCTION 2: Driver assigned → notify driver ───────────────────────────────
exports.onOrderUpdated = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const orderId = context.params.orderId;

    // Driver assigned
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
