import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  sendPushNotification,
  corsHeaders,
  jsonResponse,
  errorResponse,
} from "../_shared/onesignal.ts";

/**
 * POST /driver-assigned
 * Body: {
 *   orderId: string,
 *   driverId: string,           // Firebase UID of driver
 *   driverName: string,
 *   restaurantName: string,
 *   restaurantAddress: string,
 *   customerAddress: string,
 *   totalAmount: number,
 *   paymentType: "cod" | "online"
 * }
 *
 * Called by Admin Panel when a driver is assigned to an order.
 * Notifies the driver.
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders() });
  }

  try {
    const {
      orderId,
      driverId,
      driverName,
      restaurantName,
      restaurantAddress,
      customerAddress,
      totalAmount,
      paymentType,
    } = await req.json();

    if (!orderId || !driverId) {
      return errorResponse("orderId and driverId are required");
    }

    const shortId = orderId.slice(-6).toUpperCase();
    const isCod = paymentType === "cod";

    const ok = await sendPushNotification({
      userIds: [driverId],
      title: "🚚 New Delivery Assigned!",
      body: `Order #${shortId} from ${restaurantName}. ${isCod ? `Collect ₹${totalAmount} cash.` : "Online payment."} Tap to view.`,
      data: {
        orderId,
        type: "driver_assigned",
        restaurantName: restaurantName ?? "",
        restaurantAddress: restaurantAddress ?? "",
        customerAddress: customerAddress ?? "",
        paymentType: paymentType ?? "online",
        totalAmount: String(totalAmount ?? 0),
      },
    });

    return jsonResponse({ success: ok, orderId, notifiedDriver: driverId, driverName });
  } catch (err) {
    return errorResponse(`Error: ${err}`, 500);
  }
});
