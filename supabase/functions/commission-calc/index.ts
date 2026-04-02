import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders, jsonResponse, errorResponse } from "../_shared/onesignal.ts";

/**
 * POST /commission-calc
 * Body: {
 *   orderId: string,
 *   totalAmount: number,
 *   commissionPercent: number,   // e.g. 10 for 10%
 *   paymentType?: "cod" | "online"
 * }
 *
 * Returns a full commission breakdown.
 * Frontend can use this to display or store the result in Firestore.
 *
 * Example:
 *   totalAmount: 1000, commissionPercent: 10
 *   → commission: 100, restaurantAmount: 900
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders() });
  }

  try {
    const { orderId, totalAmount, commissionPercent, paymentType } = await req.json();

    if (!orderId) return errorResponse("orderId is required");
    if (totalAmount == null || isNaN(Number(totalAmount))) {
      return errorResponse("totalAmount must be a number");
    }
    if (commissionPercent == null || isNaN(Number(commissionPercent))) {
      return errorResponse("commissionPercent must be a number");
    }

    const total = Number(totalAmount);
    const pct = Number(commissionPercent);

    if (pct < 0 || pct > 100) return errorResponse("commissionPercent must be between 0 and 100");

    const commission = Math.round(total * pct) / 100;
    const restaurantAmount = Math.round((total - commission) * 100) / 100;

    return jsonResponse({
      success: true,
      orderId,
      breakdown: {
        totalAmount: total,
        commissionPercent: pct,
        commission,
        restaurantAmount,
        paymentType: paymentType ?? "online",
        // Formatted for display
        display: {
          total: `₹${total.toFixed(2)}`,
          commission: `₹${commission.toFixed(2)} (${pct}%)`,
          restaurantGets: `₹${restaurantAmount.toFixed(2)}`,
        },
      },
    });
  } catch (err) {
    return errorResponse(`Error: ${err}`, 500);
  }
});
