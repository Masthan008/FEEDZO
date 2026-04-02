import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  sendPushNotification,
  corsHeaders,
  jsonResponse,
  errorResponse,
} from "../_shared/onesignal.ts";

/**
 * POST /send-notification
 * Body: { userId: string, title: string, body: string, data?: object }
 *
 * Sends a push notification to a single user via OneSignal.
 */
serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders() });
  }

  try {
    const { userId, userIds, title, body, data } = await req.json();

    // Accept either a single userId or an array
    const targets: string[] = userIds ?? (userId ? [userId] : []);

    if (targets.length === 0) {
      return errorResponse("userId or userIds is required");
    }
    if (!title || !body) {
      return errorResponse("title and body are required");
    }

    const ok = await sendPushNotification({ userIds: targets, title, body, data });

    return jsonResponse({ success: ok, sentTo: targets.length });
  } catch (err) {
    return errorResponse(`Invalid request: ${err}`, 500);
  }
});
