// Loyalty points calculation - triggered when order status changes to "delivered"

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const onesignalAppId = Deno.env.get("ONESIGNAL_APP_ID")!;
const onesignalApiKey = Deno.env.get("ONESIGNAL_API_KEY")!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { orderId, userId } = await req.json();

    console.log(`Processing loyalty points for order: ${orderId}, user: ${userId}`);

    // Fetch order details
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("totalAmount, id, restaurantName")
      .eq("id", orderId)
      .single();

    if (orderError) {
      console.error("Order fetch error:", orderError);
      return new Response(JSON.stringify({ error: "Order not found" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Fetch user loyalty data
    const { data: loyaltyData, error: loyaltyError } = await supabase
      .from("loyalty_points")
      .select("totalPoints, currentTier")
      .eq("userId", userId)
      .single();

    let currentPoints = 0;
    let currentTier = "Bronze";

    if (!loyaltyError && loyaltyData) {
      currentPoints = loyaltyData.totalPoints || 0;
      currentTier = loyaltyData.currentTier || "Bronze";
    }

    // Calculate points (1 per rupee + tier bonus)
    const basePoints = Math.floor(order.totalAmount);
    const tierBonus = getTierBonus(currentTier);
    const bonusPoints = Math.floor(basePoints * tierBonus);
    const totalPointsEarned = basePoints + bonusPoints;

    // Determine new tier
    const newPointsTotal = currentPoints + totalPointsEarned;
    const newTier = getTierFromPoints(newPointsTotal);

    // Update or create loyalty points record
    const upsertData = {
      userId: userId,
      totalPoints: newPointsTotal,
      currentTier: newTier,
      lastUpdatedAt: new Date().toISOString(),
    };

    const { error: upsertError } = await supabase
      .from("loyalty_points")
      .upsert(upsertData, { onConflict: "userId" });

    if (upsertError) {
      console.error("Loyalty upsert error:", upsertError);
      throw upsertError;
    }

    // Create transaction record
    const transactionData = {
      userId: userId,
      type: "earned",
      amount: totalPointsEarned,
      description: `Order #${orderId.substring(orderId.length - 6)} - ${order.restaurantName}`,
      timestamp: new Date().toISOString(),
      orderId: orderId,
    };

    const { error: txError } = await supabase
      .from("point_transactions")
      .insert(transactionData);

    if (txError) {
      console.error("Transaction insert error:", txError);
      throw txError;
    }

    // Check for tier upgrade and send notification
    if (newTier !== currentTier) {
      await sendTierUpgradeNotification(userId, currentTier, newTier);
    }

    return new Response(
      JSON.stringify({
        success: true,
        pointsEarned: totalPointsEarned,
        totalPoints: newPointsTotal,
        tier: newTier,
        tierUpgraded: newTier !== currentTier,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    console.error("Loyalty calculation error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

// Helper functions
function getTierBonus(tier: string): number {
  switch (tier) {
    case "Silver":
      return 0.05; // 5% bonus
    case "Gold":
      return 0.10; // 10% bonus
    case "Platinum":
      return 0.15; // 15% bonus
    default:
      return 0;
  }
}

function getTierFromPoints(points: number): string {
  if (points >= 10000) return "Platinum";
  if (points >= 3000) return "Gold";
  if (points >= 1000) return "Silver";
  return "Bronze";
}

async function sendTierUpgradeNotification(userId: string, oldTier: string, newTier: string) {
  try {
    // Get user's OneSignal player ID
    const { data: devices, error: deviceError } = await supabase
      .from("devices")
      .select("playerId")
      .eq("userId", userId)
      .limit(1);

    if (deviceError || !devices || devices.length === 0) {
      console.log("No device found for user, skipping notification");
      return;
    }

    const playerId = devices[0].playerId;

    const res = await fetch("https://onesignal.com/api/v1/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Basic ${onesignalApiKey}`,
      },
      body: JSON.stringify({
        app_id: onesignalAppId,
        include_player_ids: [playerId],
        contents: {
          en: `🎉 Congratulations! You've been upgraded from ${oldTier} to ${newTier} tier! Enjoy exclusive benefits.`,
        },
      }),
    });

    if (res.ok) {
      console.log("Tier upgrade notification sent successfully");
    } else {
      const err = await res.text();
      console.error("Failed to send tier notification:", err);
    }

  } catch (error) {
    console.error("Failed to send tier notification:", error);
  }
}
