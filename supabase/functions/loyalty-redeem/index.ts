// Process loyalty reward redemption

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(supabaseUrl, supabaseServiceKey);

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { rewardId, userId } = await req.json();

    if (!rewardId || !userId) {
      return new Response(JSON.stringify({ error: "Missing required parameters" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    console.log(`Processing reward redemption: ${rewardId} for user: ${userId}`);

    // Fetch reward details
    const { data: reward, error: rewardError } = await supabase
      .from("rewards")
      .select("*")
      .eq("id", rewardId)
      .eq("isActive", true)
      .single();

    if (rewardError || !reward) {
      return new Response(JSON.stringify({ error: "Reward not found or inactive" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }

    const pointsRequired = reward.pointsRequired;

    // Check user has enough points using a transaction
    const { data: loyaltyData, error: loyaltyError } = await supabase
      .from("loyalty_points")
      .select("totalPoints")
      .eq("userId", userId)
      .single();

    const currentPoints = loyaltyData?.totalPoints || 0;

    if (currentPoints < pointsRequired) {
      return new Response(
        JSON.stringify({
          error: "Insufficient points",
          required: pointsRequired,
          current: currentPoints,
        }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // Process redemption in a transaction (batched operations)
    const newBalance = currentPoints - pointsRequired;

    // 1. Update loyalty points
    const { error: updateError } = await supabase
      .from("loyalty_points")
      .update({
        totalPoints: newBalance,
        lastUpdatedAt: new Date().toISOString(),
      })
      .eq("userId", userId);

    if (updateError) {
      console.error("Failed to update loyalty points:", updateError);
      throw updateError;
    }

    // 2. Create redemption record
    const redemptionData = {
      userId: userId,
      rewardId: rewardId,
      rewardName: reward.name,
      pointsRedeemed: pointsRequired,
      redeemedAt: new Date().toISOString(),
      status: "completed",
    };

    const { data: redemption, error: redemptionError } = await supabase
      .from("reward_redemptions")
      .insert(redemptionData)
      .select()
      .single();

    if (redemptionError) {
      console.error("Failed to create redemption record:", redemptionError);
      throw redemptionError;
    }

    // 3. Create point transaction for redemption
    const transactionData = {
      userId: userId,
      type: "redeemed",
      amount: pointsRequired,
      description: `Redeemed: ${reward.name}`,
      timestamp: new Date().toISOString(),
      redemptionId: redemption.id,
    };

    const { error: txError } = await supabase
      .from("point_transactions")
      .insert(transactionData);

    if (txError) {
      console.error("Failed to create transaction record:", txError);
      throw txError;
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Successfully redeemed ${reward.name}`,
        newBalance: newBalance,
        redemption: redemption,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    console.error("Redemption error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
