import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  sendPushNotification,
  corsHeaders,
  jsonResponse,
  errorResponse,
} from "../_shared/onesignal.ts";

/**
 * POST /order-status
 * Body: {
 *   orderId: string,
 *   status: "preparing" | "picked" | "out_for_delivery" | "delivered" | "cancelled",
 *   customerId: string,         // Firebase UID of customer
 *   restaurantId: string,
 *   driverId: string,
 *   totalAmount: number,
 *   commissionPercent: number,  // e.g. 10 for 10%
 *   paymentType: "cod" | "online"
 * }
 *
 * Called by Driver App when order status changes.
 * - out_for_delivery → notify customer
 * - delivered → notify customer + trigger commission calc inline
 * - cancelled → notify customer + restaurant
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders() });
  }

  try {
    const {
      orderId,
      status,
      customerId,
      restaurantId,
      driverId,
      totalAmount,
      commissionPercent,
      paymentType,
    } = await req.json();

    if (!orderId || !status) {
      return errorResponse("orderId and status are required");
    }

    const shortId = orderId.slice(-6).toUpperCase();
    const notifications: Promise<boolean>[] = [];
    let commission: number | null = null;
    let restaurantAmount: number | null = null;

    if (status === "out_for_delivery" || status === "picked") {
      // Notify customer
      if (customerId) {
        notifications.push(
          sendPushNotification({
            userIds: [customerId],
            title: "🛵 Order On The Way!",
            body: `Your order #${shortId} is out for delivery. Estimated 20–30 mins.`,
            data: { orderId, type: "out_for_delivery" },
          })
        );
      }
    } else if (status === "delivered") {
      // Notify customer
      if (customerId) {
        notifications.push(
          sendPushNotification({
            userIds: [customerId],
            title: "✅ Order Delivered!",
            body: `Your order #${shortId} has been delivered. Enjoy your meal! 🍽️`,
            data: { orderId, type: "delivered" },
          })
        );
      }

      // Inline commission calculation
      if (totalAmount && commissionPercent != null) {
        const pct = Number(commissionPercent);
        commission = Math.round((totalAmount * pct) / 100 * 100) / 100;
        restaurantAmount = Math.round((totalAmount - commission) * 100) / 100;
      }
    } else if (status === "cancelled") {
      const targets = [customerId, restaurantId].filter(Boolean) as string[];
      if (targets.length > 0) {
        notifications.push(
          sendPushNotification({
            userIds: targets,
            title: "❌ Order Cancelled",
            body: `Order #${shortId} has been cancelled.`,
            data: { orderId, type: "cancelled" },
          })
        );
      }
    }

    await Promise.all(notifications);

    return jsonResponse({
      success: true,
      orderId,
      status,
      ...(commission !== null && {
        commission: { commission, restaurantAmount, totalAmount, commissionPercent },
      }),
    });
  } catch (err) {
    return errorResponse(`Error: ${err}`, 500);
  }
});
