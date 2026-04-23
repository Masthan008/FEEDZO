import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recurring_order_model.dart';

class RecurringOrderService {
  static final _db = FirebaseFirestore.instance;

  /// Create a new recurring order
  static Future<String> createRecurringOrder({
    required String userId,
    required String restaurantId,
    required String restaurantName,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String frequency, // 'daily', 'weekly', 'monthly'
    required DateTime startDate,
    String? deliveryAddress,
    String? deliveryInstructions,
  }) async {
    final docRef = await _db.collection('recurringOrders').add({
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'items': items,
      'totalAmount': totalAmount,
      'frequency': frequency,
      'startDate': Timestamp.fromDate(startDate),
      'nextOrderDate': Timestamp.fromDate(startDate),
      'deliveryAddress': deliveryAddress,
      'deliveryInstructions': deliveryInstructions,
      'isActive': true,
      'orderCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Get user's recurring orders
  static Stream<List<RecurringOrderModel>> getUserRecurringOrders(String userId) {
    return _db
        .collection('recurringOrders')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('nextOrderDate', ascending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RecurringOrderModel.fromFirestore(doc))
            .toList());
  }

  /// Update recurring order
  static Future<void> updateRecurringOrder(String recurringOrderId, Map<String, dynamic> data) async {
    await _db.collection('recurringOrders').doc(recurringOrderId).update(data);
  }

  /// Pause recurring order
  static Future<void> pauseRecurringOrder(String recurringOrderId) async {
    await _db.collection('recurringOrders').doc(recurringOrderId).update({
      'isActive': false,
      'pausedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Resume recurring order
  static Future<void> resumeRecurringOrder(String recurringOrderId) async {
    await _db.collection('recurringOrders').doc(recurringOrderId).update({
      'isActive': true,
      'resumedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete recurring order
  static Future<void> deleteRecurringOrder(String recurringOrderId) async {
    await _db.collection('recurringOrders').doc(recurringOrderId).delete();
  }

  /// Calculate next order date based on frequency
  static DateTime calculateNextOrderDate(DateTime lastDate, String frequency) {
    switch (frequency) {
      case 'daily':
        return lastDate.add(const Duration(days: 1));
      case 'weekly':
        return lastDate.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
      default:
        return lastDate.add(const Duration(days: 1));
    }
  }

  /// Place order from recurring order (called by cloud function or scheduled job)
  static Future<void> placeOrderFromRecurring(String recurringOrderId) async {
    final doc = await _db.collection('recurringOrders').doc(recurringOrderId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final isActive = data['isActive'] as bool? ?? false;
    final nextOrderDate = (data['nextOrderDate'] as Timestamp).toDate();

    // Check if it's time to place the order
    if (!isActive || DateTime.now().isBefore(nextOrderDate)) return;

    // Create the order
    final orderData = {
      'customerId': data['userId'],
      'restaurantId': data['restaurantId'],
      'restaurantName': data['restaurantName'],
      'items': data['items'],
      'totalAmount': data['totalAmount'],
      'address': data['deliveryAddress'],
      'deliveryInstructions': data['deliveryInstructions'],
      'status': 'placed',
      'driverId': null,
      'driverName': null,
      'paymentType': 'cod', // Default to COD for recurring orders
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isRecurring': true,
      'recurringOrderId': recurringOrderId,
    };

    // Place the order
    await _db.collection('orders').add(orderData);

    // Update recurring order
    final frequency = data['frequency'] as String;
    final newNextOrderDate = calculateNextOrderDate(DateTime.now(), frequency);
    
    await _db.collection('recurringOrders').doc(recurringOrderId).update({
      'nextOrderDate': Timestamp.fromDate(newNextOrderDate),
      'orderCount': FieldValue.increment(1),
      'lastOrderDate': FieldValue.serverTimestamp(),
    });
  }

  /// Get recurring order by ID
  static Future<RecurringOrderModel?> getRecurringOrder(String recurringOrderId) async {
    final doc = await _db.collection('recurringOrders').doc(recurringOrderId).get();
    if (!doc.exists) return null;
    return RecurringOrderModel.fromFirestore(doc);
  }
}
