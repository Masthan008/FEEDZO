import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  sendPushNotification,
  corsHeaders,
  jsonResponse,
  errorResponse,
} from "../_shared/onesignal.ts";

/**
 * POST /order-created
 * Body: {
 *   orderId: string,
 *   restaurantId: string,       // Firebase UID of restaurant owner
 *   restaurantName: string,
 *   customerName: string,
 *   totalAmount: number,
 *   paymentType: "cod" | "online"
 * }
 *
 * Called by Customer App immediately after placing an order.
 * Notifies the restaurant owner.
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders() });
  }

  try {
    const { orderId, restaurantId, restaurantName, customerName, totalAmount, paymentType } =
      await req.json();

    if (!orderId || !restaurantId) {
      return errorResponse("orderId and restaurantId are required");
    }

    const shortId = orderId.slice(-6).toUpperCase();
    const payLabel = paymentType === "cod" ? "💵 COD" : "💳 Online";

    const ok = await sendPushNotification({
      userIds: [restaurantId],
      title: "🍽️ New Order Received!",
      body: `Order #${shortId} from ${customerName} — ₹${totalAmount} (${payLabel}). Tap to accept.`,
      data: { orderId, type: "new_order", restaurantName: restaurantName ?? "" },
    });

    return jsonResponse({ success: ok, orderId, notifiedRestaurant: restaurantId });
  } catch (err) {
    return errorResponse(`Error: ${err}`, 500);
  }
});
