// Shared OneSignal helper used by all edge functions
const ONESIGNAL_APP_ID = "90f7c5c6-b51f-466a-acdb-a4829b419363";
const ONESIGNAL_API_KEY =
  "os_v2_app_sd34lrvvd5dgvlg3usbjwqmtmnkyn3llzrou5amwfr35ndpvxhxqxagknlesssypciia4ds5chlbmggfvji74wc5cuu3dtfgdftcnnq";

export interface NotificationPayload {
  userIds: string[];       // Firebase UIDs (mapped as external_user_ids in OneSignal)
  title: string;
  body: string;
  data?: Record<string, string>;
}

export async function sendPushNotification(payload: NotificationPayload): Promise<boolean> {
  try {
    const res = await fetch("https://onesignal.com/api/v1/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Basic ${ONESIGNAL_API_KEY}`,
      },
      body: JSON.stringify({
        app_id: ONESIGNAL_APP_ID,
        include_external_user_ids: payload.userIds,
        headings: { en: payload.title },
        contents: { en: payload.body },
        data: payload.data ?? {},
      }),
    });
    const json = await res.json();
    console.log("OneSignal response:", JSON.stringify(json));
    return res.ok;
  } catch (err) {
    console.error("OneSignal error:", err);
    return false;
  }
}

// Standard CORS + JSON response helpers
export function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };
}

export function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders(), "Content-Type": "application/json" },
  });
}

export function errorResponse(message: string, status = 400): Response {
  return jsonResponse({ success: false, error: message }, status);
}
