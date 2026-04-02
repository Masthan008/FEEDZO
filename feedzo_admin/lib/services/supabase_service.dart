import 'dart:convert';
import 'package:http/http.dart' as http;

/// Supabase Edge Functions client.
/// Replace SUPABASE_URL and SUPABASE_ANON_KEY with your project values from:
/// https://supabase.com/dashboard → Project Settings → API
class SupabaseService {
  static const _baseUrl =
      'https://iuunpzrewtugdvvhycyx.supabase.co/functions/v1';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1dW5wenJld3R1Z2R2dmh5Y3l4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ5NjczNzUsImV4cCI6MjA5MDU0MzM3NX0.8U1SvJqsrN4VJeqkO6STCrhc37f8vvZXrRSFUAUQNrg';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_anonKey',
  };

  static Future<Map<String, dynamic>?> _post(
    String function,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/$function'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'success': false, 'error': res.body};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── Notification ──────────────────────────────────────────────────────────

  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) => _post('send-notification', {
    'userId': userId,
    'title': title,
    'body': body,
    'data': ?data,
  });

  // ── Order Created → notify restaurant ────────────────────────────────────

  static Future<void> onOrderCreated({
    required String orderId,
    required String restaurantId,
    required String restaurantName,
    required String customerName,
    required double totalAmount,
    required String paymentType,
  }) => _post('order-created', {
    'orderId': orderId,
    'restaurantId': restaurantId,
    'restaurantName': restaurantName,
    'customerName': customerName,
    'totalAmount': totalAmount,
    'paymentType': paymentType,
  });

  // ── Driver Assigned → notify driver ──────────────────────────────────────

  static Future<void> onDriverAssigned({
    required String orderId,
    required String driverId,
    required String driverName,
    required String restaurantName,
    String restaurantAddress = '',
    String customerAddress = '',
    required double totalAmount,
    required String paymentType,
  }) => _post('driver-assigned', {
    'orderId': orderId,
    'driverId': driverId,
    'driverName': driverName,
    'restaurantName': restaurantName,
    'restaurantAddress': restaurantAddress,
    'customerAddress': customerAddress,
    'totalAmount': totalAmount,
    'paymentType': paymentType,
  });

  // ── Order Status Update → notify customer / trigger commission ────────────

  static Future<Map<String, dynamic>?> onOrderStatusUpdate({
    required String orderId,
    required String status,
    required String customerId,
    required String restaurantId,
    required String driverId,
    required double totalAmount,
    required double commissionPercent,
    required String paymentType,
  }) => _post('order-status', {
    'orderId': orderId,
    'status': status,
    'customerId': customerId,
    'restaurantId': restaurantId,
    'driverId': driverId,
    'totalAmount': totalAmount,
    'commissionPercent': commissionPercent,
    'paymentType': paymentType,
  });

  // ── Commission Calculation ────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> calculateCommission({
    required String orderId,
    required double totalAmount,
    required double commissionPercent,
    String paymentType = 'online',
  }) => _post('commission-calc', {
    'orderId': orderId,
    'totalAmount': totalAmount,
    'commissionPercent': commissionPercent,
    'paymentType': paymentType,
  });
}
