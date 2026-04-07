import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models.dart';

/// Service for admin to manage driver assignments including multi-order support
class DriverAssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _driversCollection => _firestore.collection('drivers');
  CollectionReference get _ordersCollection => _firestore.collection('orders');
  CollectionReference get _driverNotificationsCollection => _firestore.collection('driverNotifications');

  /// Get all available drivers including those who can accept more orders
  Stream<List<Driver>> getAvailableDrivers() {
    return _driversCollection
        .where('status', whereIn: ['available', 'busy', 'multiOrder'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Driver.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    });
  }

  /// Check if driver can accept more orders
  Future<bool> canDriverAcceptMoreOrders(String driverId) async {
    final doc = await _driversCollection.doc(driverId).get();
    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>;
    final activeOrderIds = List<String>.from(data['activeOrderIds'] ?? []);
    final maxConcurrentOrders = (data['maxConcurrentOrders'] as num?)?.toInt() ?? 3;
    final allowMultiOrder = data['allowMultiOrderAssignment'] as bool? ?? true;

    return allowMultiOrder && activeOrderIds.length < maxConcurrentOrders;
  }

  /// Assign order to driver (supports busy drivers with multi-order capability)
  Future<void> assignOrderToDriver({
    required String orderId,
    required String driverId,
    required String driverName,
    required String assignedBy, // admin user ID
    bool isAdminOverride = false,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    // Get driver data
    final driverDoc = await _driversCollection.doc(driverId).get();
    if (!driverDoc.exists) throw Exception('Driver not found');

    final driverData = driverDoc.data() as Map<String, dynamic>;
    final activeOrderIds = List<String>.from(driverData['activeOrderIds'] ?? []);
    final maxConcurrentOrders = (driverData['maxConcurrentOrders'] as num?)?.toInt() ?? 3;

    // Validate capacity
    if (activeOrderIds.length >= maxConcurrentOrders) {
      throw Exception('Driver is at maximum capacity ($maxConcurrentOrders orders)');
    }

    // Update order
    final orderRef = _ordersCollection.doc(orderId);
    batch.update(orderRef, {
      'driverId': driverId,
      'driverName': driverName,
      'status': 'outForDelivery',
      'assignedAt': Timestamp.fromDate(now),
      'assignedBy': assignedBy,
      'isAdminOverride': isAdminOverride,
      'updatedAt': Timestamp.fromDate(now),
    });

    // Update driver - add to active orders
    final driverRef = _driversCollection.doc(driverId);
    final newActiveOrderIds = [...activeOrderIds, orderId];
    
    DriverStatus newStatus;
    if (newActiveOrderIds.length >= maxConcurrentOrders) {
      newStatus = DriverStatus.multiOrder;
    } else if (newActiveOrderIds.length > 1) {
      newStatus = DriverStatus.multiOrder;
    } else {
      newStatus = DriverStatus.busy;
    }

    batch.update(driverRef, {
      'currentOrderId': newActiveOrderIds.first, // Primary order
      'activeOrderIds': newActiveOrderIds,
      'status': newStatus.name,
      'lastAssignmentAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    // Create driver notification
    final notificationRef = _driverNotificationsCollection.doc();
    batch.set(notificationRef, {
      'id': notificationRef.id,
      'driverId': driverId,
      'type': 'newOrderAssigned',
      'title': 'New Order Assigned',
      'message': 'You have been assigned a new order. Total active orders: ${newActiveOrderIds.length}',
      'orderId': orderId,
      'isRead': false,
      'createdAt': Timestamp.fromDate(now),
      'priority': 'high',
      'actions': ['accept', 'view'],
    });

    // Create assignment log
    final logRef = _firestore.collection('driverAssignmentLogs').doc();
    batch.set(logRef, {
      'orderId': orderId,
      'driverId': driverId,
      'driverName': driverName,
      'assignedAt': Timestamp.fromDate(now),
      'assignedBy': assignedBy,
      'isAdminOverride': isAdminOverride,
      'previousOrderCount': activeOrderIds.length,
      'newOrderCount': newActiveOrderIds.length,
    });

    await batch.commit();
  }

  /// Remove order from driver's active orders (when delivered/cancelled)
  Future<void> removeOrderFromDriver({
    required String orderId,
    required String driverId,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    // Get driver data
    final driverDoc = await _driversCollection.doc(driverId).get();
    if (!driverDoc.exists) return;

    final driverData = driverDoc.data() as Map<String, dynamic>;
    final activeOrderIds = List<String>.from(driverData['activeOrderIds'] ?? []);

    // Remove order from active list
    final newActiveOrderIds = activeOrderIds.where((id) => id != orderId).toList();

    // Update driver status
    final driverRef = _driversCollection.doc(driverId);
    
    DriverStatus newStatus;
    if (newActiveOrderIds.isEmpty) {
      newStatus = DriverStatus.available;
    } else if (newActiveOrderIds.length == 1) {
      newStatus = DriverStatus.busy;
    } else {
      newStatus = DriverStatus.multiOrder;
    }

    batch.update(driverRef, {
      'currentOrderId': newActiveOrderIds.isNotEmpty ? newActiveOrderIds.first : null,
      'activeOrderIds': newActiveOrderIds,
      'status': newStatus.name,
      'updatedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  /// Update driver's multi-order settings
  Future<void> updateDriverMultiOrderSettings({
    required String driverId,
    required int maxConcurrentOrders,
    required bool allowMultiOrderAssignment,
    required String updatedBy,
  }) async {
    await _driversCollection.doc(driverId).update({
      'maxConcurrentOrders': maxConcurrentOrders,
      'allowMultiOrderAssignment': allowMultiOrderAssignment,
      'settingsUpdatedAt': Timestamp.fromDate(DateTime.now()),
      'settingsUpdatedBy': updatedBy,
    });
  }

  /// Get driver's active orders
  Future<List<String>> getDriverActiveOrders(String driverId) async {
    final doc = await _driversCollection.doc(driverId).get();
    if (!doc.exists) return [];

    final data = doc.data() as Map<String, dynamic>;
    return List<String>.from(data['activeOrderIds'] ?? []);
  }

  /// Get all drivers eligible for multi-order assignment
  Stream<List<Driver>> getMultiOrderCapableDrivers() {
    return _driversCollection
        .where('allowMultiOrderAssignment', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Driver.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((driver) => driver.canAcceptMoreOrders)
          .toList();
    });
  }
}
