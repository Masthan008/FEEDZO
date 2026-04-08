import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../data/models.dart';
import '../services/firestore_service.dart';

class AdminProvider extends ChangeNotifier {
  bool isLoggedIn = false;
  String adminEmail = '';
  String adminName = '';
  String adminUid = '';

  void login(String email) { isLoggedIn = true; adminEmail = email; initStreams(); notifyListeners(); }
  void logout() { isLoggedIn = false; adminEmail = ''; adminName = ''; adminUid = ''; disposeStreams(); notifyListeners(); }

  Future<void> logoutFirebase() async {
    await FirebaseAuth.instance.signOut();
    isLoggedIn = false;
    adminEmail = '';
    adminName = '';
    disposeStreams();
    notifyListeners();
  }

  /// Called by _AuthGate after Firebase confirms sign-in.
  /// Fetches the real name from Firestore.
  Future<void> loginWithFirebase(String uid, String email) async {
    isLoggedIn = true;
    adminUid = uid;
    adminEmail = email;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      adminName = (doc.data()?['name'] as String?) ?? email.split('@').first;
    } catch (_) {
      adminName = email.split('@').first;
    }
    initStreams();
    notifyListeners();
  }

  List<AdminOrder> orders = [];
  List<Driver> drivers = [];
  List<AdminRestaurant> restaurants = [];
  List<AppUser> users = [];
  List<AdminAlert> alerts = [];
  List<ActivityFeedItem> activityFeed = [];
  List<DriverDailySummary> driverSummaries = [];
  Map<String, List<DriverSettlementRecord>> settlementHistory = {};
  double commissionRate = 0.10;
  SystemSettings settings = SystemSettings();

  StreamSubscription? _ordersSub;
  StreamSubscription? _driversSub;
  StreamSubscription? _restaurantsSub;
  StreamSubscription? _usersSub;
  StreamSubscription? _alertsSub;
  StreamSubscription? _activitiesSub;
  StreamSubscription? _settlementsSub;

  void initStreams() {
    _ordersSub = AdminFirestoreService.watchAllOrders().listen((snapshot) {
      orders = snapshot.docs.map((doc) => AdminOrder.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
      notifyListeners();
    });
    _driversSub = AdminFirestoreService.watchAllDrivers().listen((snapshot) {
      drivers = snapshot.docs.map((doc) => Driver.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
      notifyListeners();
    });
    _restaurantsSub = AdminFirestoreService.watchAllRestaurants().listen((snapshot) {
      restaurants = snapshot.docs.map((doc) => AdminRestaurant.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
      notifyListeners();
    });
    _usersSub = AdminFirestoreService.watchAllUsers().listen((snapshot) {
      users = snapshot.docs.map((doc) => AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
      notifyListeners();
    });
    _alertsSub = AdminFirestoreService.watchAllAlerts().listen((snapshot) {
      alerts = snapshot.docs.map((doc) => AdminAlert.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
      notifyListeners();
    });
    _activitiesSub = AdminFirestoreService.watchActivityFeed().listen((snapshot) {
      activityFeed = snapshot.docs.map((doc) => ActivityFeedItem.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
      notifyListeners();
    });
    _settlementsSub = AdminFirestoreService.watchAllSettlements().listen((snapshot) {
      driverSummaries = snapshot.docs.map((doc) => DriverDailySummary.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
      notifyListeners();
    });
  }

  void disposeStreams() {
    _ordersSub?.cancel();
    _driversSub?.cancel();
    _restaurantsSub?.cancel();
    _usersSub?.cancel();
    _alertsSub?.cancel();
    _activitiesSub?.cancel();
    _settlementsSub?.cancel();
  }

  @override
  void dispose() {
    disposeStreams();
    super.dispose();
  }

  int get totalUsers => users.length;
  int get totalRestaurants => restaurants.length;
  int get totalDrivers => drivers.length;
  int get totalOrders => orders.length;
  double get totalRevenue => orders.where((o) => o.status == OrderStatus.delivered).fold(0, (s, o) => s + o.orderValue);
  double get totalCommission => orders.where((o) => o.status == OrderStatus.delivered).fold(0, (s, o) => s + o.commission);
  List<AdminOrder> get pendingOrders => orders.where((o) => o.status == OrderStatus.pending).toList();
  List<AdminOrder> get activeOrders => orders.where((o) => o.status == OrderStatus.preparing || o.status == OrderStatus.outForDelivery).toList();
  List<Driver> get availableDrivers => drivers.where((d) => d.status == DriverStatus.available).toList();
  int get unreadAlerts => alerts.where((a) => !a.isRead).length;
  List<AdminOrder> get delayedOrders => orders.where((o) => o.isDelayed).toList();
  double get totalPendingCash => driverSummaries.fold(0, (s, d) => s + d.pendingAmount);
  int get driversWithPendingCash => settings.driverSettlementEnabled ? driverSummaries.where((d) => d.pendingAmount > 0).length : 0;

  void assignDriver(String orderId, Driver driver) {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;
    orders[idx].assignedDriverId = driver.id;
    orders[idx].assignedDriverName = driver.name;
    if (orders[idx].status == OrderStatus.pending) orders[idx].status = OrderStatus.preparing;
    orders[idx].timeline.add(OrderTimelineEvent(label: 'Driver Assigned (${driver.name})', time: DateTime.now()));
    final dIdx = drivers.indexWhere((d) => d.id == driver.id);
    if (dIdx >= 0) { drivers[dIdx].status = DriverStatus.busy; drivers[dIdx].currentOrderId = orderId; }
    _addActivity(ActivityType.driverAssigned, '${driver.name} assigned to order #$orderId');
    _addAlert(AdminAlert(id: 'a${DateTime.now().millisecondsSinceEpoch}', title: 'Driver Assigned', description: '${driver.name} assigned to order #$orderId', severity: AlertSeverity.low, type: AlertType.systemEvent, createdAt: DateTime.now(), orderId: orderId));
    notifyListeners();
  }

  void reassignDriver(String orderId, Driver newDriver) {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;
    final oldDriverId = orders[idx].assignedDriverId;
    if (oldDriverId != null) {
      final dIdx = drivers.indexWhere((d) => d.id == oldDriverId);
      if (dIdx >= 0) { drivers[dIdx].status = DriverStatus.available; drivers[dIdx].currentOrderId = null; }
    }
    orders[idx].assignedDriverId = newDriver.id;
    orders[idx].assignedDriverName = newDriver.name;
    orders[idx].timeline.add(OrderTimelineEvent(label: 'Reassigned to ${newDriver.name}', time: DateTime.now()));
    final dIdx = drivers.indexWhere((d) => d.id == newDriver.id);
    if (dIdx >= 0) { drivers[dIdx].status = DriverStatus.busy; drivers[dIdx].currentOrderId = orderId; }
    _addActivity(ActivityType.driverAssigned, '${newDriver.name} reassigned to order #$orderId');
    notifyListeners();
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;
    orders[idx].status = status;
    orders[idx].timeline.add(OrderTimelineEvent(label: orders[idx].statusLabel, time: DateTime.now()));
    if (status == OrderStatus.delivered) {
      final driverId = orders[idx].assignedDriverId;
      if (driverId != null) {
        final dIdx = drivers.indexWhere((d) => d.id == driverId);
        if (dIdx >= 0) { drivers[dIdx].status = DriverStatus.available; drivers[dIdx].currentOrderId = null; }
      }
      final rIdx = restaurants.indexWhere((r) => r.id == orders[idx].restaurantId);
      if (rIdx >= 0) {
        restaurants[rIdx].walletBalance += orders[idx].restaurantPayout;
        restaurants[rIdx].transactions.insert(0, Transaction(
          id: 'tx${DateTime.now().millisecondsSinceEpoch}', orderId: orderId,
          amount: orders[idx].restaurantPayout, commission: orders[idx].commission,
          type: TransactionType.commission, date: DateTime.now(),
          note: 'Order payout (${(orders[idx].commissionRate * 100).toInt()}% commission deducted)',
        ));
      }
      _addActivity(ActivityType.orderDelivered, 'Order #$orderId delivered to ${orders[idx].customerName}');
    }
    notifyListeners();
  }

  void releaseOrderPayment(String orderId) {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;
    orders[idx].paymentReleased = true;
    _addActivity(ActivityType.paymentReleased, 'Payment released for order #$orderId');
    _addAlert(AdminAlert(id: 'a${DateTime.now().millisecondsSinceEpoch}', title: 'Payment Released', description: 'Payment of Rs.${orders[idx].restaurantPayout.toStringAsFixed(0)} released for order #$orderId', severity: AlertSeverity.medium, type: AlertType.systemEvent, createdAt: DateTime.now(), orderId: orderId));
    notifyListeners();
  }

  void toggleRestaurantStatus(String id) {
    final idx = restaurants.indexWhere((r) => r.id == id);
    if (idx < 0) return;
    restaurants[idx].status = restaurants[idx].status == RestaurantStatus.active ? RestaurantStatus.disabled : RestaurantStatus.active;
    notifyListeners();
  }

  void approveRestaurant(String id) {
    final idx = restaurants.indexWhere((r) => r.id == id);
    if (idx < 0) return;
    restaurants[idx].status = RestaurantStatus.active;
    notifyListeners();
  }

  void rejectRestaurant(String id) {
    final idx = restaurants.indexWhere((r) => r.id == id);
    if (idx < 0) return;
    restaurants[idx].status = RestaurantStatus.disabled;
    notifyListeners();
  }

  void setRestaurantCommission(String restaurantId, double rate) {
    final idx = restaurants.indexWhere((r) => r.id == restaurantId);
    if (idx < 0) return;
    restaurants[idx].commissionRate = rate;
    notifyListeners();
  }

  void releasePayout(String restaurantId) {
    final idx = restaurants.indexWhere((r) => r.id == restaurantId);
    if (idx < 0) return;
    final amount = restaurants[idx].walletBalance;
    if (amount <= 0) return;
    restaurants[idx].transactions.insert(0, Transaction(id: 'tx${DateTime.now().millisecondsSinceEpoch}', orderId: '-', amount: amount, type: TransactionType.payout, date: DateTime.now(), note: 'Manual payout released by admin', paid: true));
    restaurants[idx].walletBalance = 0;
    _addActivity(ActivityType.paymentReleased, 'Rs.${amount.toStringAsFixed(0)} payout released to ${restaurants[idx].name}');
    notifyListeners();
  }

  void toggleUserStatus(String id) {
    final idx = users.indexWhere((u) => u.id == id);
    if (idx < 0) return;
    users[idx].status = users[idx].status == UserStatus.active ? UserStatus.blocked : UserStatus.active;
    notifyListeners();
  }

  void setCommissionRate(double rate) { commissionRate = rate; notifyListeners(); }

  void updateOrderCommission(String orderId, double newRate) {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return;
    orders[idx].commissionRate = newRate;
    notifyListeners();
  }

  void updateSettings({bool? codEnabled, bool? driverSettlementEnabled}) {
    if (codEnabled != null) settings.codEnabled = codEnabled;
    if (driverSettlementEnabled != null) settings.driverSettlementEnabled = driverSettlementEnabled;
    notifyListeners();
  }

  DriverDailySummary? getSummary(String driverId) {
    try { return driverSummaries.firstWhere((s) => s.driverId == driverId); } catch (_) { return null; }
  }

  Future<void> recordCashSubmission(String driverId, double amount, String note) async {
    final driver = drivers.firstWhere((d) => d.id == driverId, orElse: () => drivers.first);
    
    await AdminFirestoreService.markCashReceived(
      driverId, 
      amount, 
      driver.name,
      adminUid.isNotEmpty ? adminUid : 'system',
    );

    final idx = driverSummaries.indexWhere((s) => s.driverId == driverId);
    final isFullySettled = idx >= 0 ? driverSummaries[idx].pendingAmount <= amount : false;
    final history = settlementHistory[driverId] ?? [];
    if (history.isNotEmpty) {
      final todayIdx = history.indexWhere((r) => _isSameDay(r.date, DateTime.now()));
      if (todayIdx >= 0) {
        history[todayIdx] = DriverSettlementRecord(driverId: driverId, date: history[todayIdx].date, ordersCompleted: history[todayIdx].ordersCompleted, codCollected: history[todayIdx].codCollected, submittedAmount: history[todayIdx].submittedAmount + amount);
        settlementHistory[driverId] = history;
      }
    }
    _addActivity(ActivityType.cashSubmitted, '${driver.name} submitted Rs.${amount.toStringAsFixed(0)} cash');
    _addAlert(AdminAlert(id: 'a${DateTime.now().millisecondsSinceEpoch}', title: 'Driver Submitted Payment', description: '${driver.name} submitted Rs.${amount.toStringAsFixed(0)}${isFullySettled ? ' - fully settled' : ' - Rs.${driverSummaries[idx].pendingAmount.toStringAsFixed(0)} still pending'}', severity: isFullySettled ? AlertSeverity.low : AlertSeverity.medium, type: AlertType.systemEvent, createdAt: DateTime.now(), customerName: driver.name));
    notifyListeners();
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void markAlertRead(String id) {
    final idx = alerts.indexWhere((a) => a.id == id);
    if (idx >= 0) { alerts[idx].isRead = true; notifyListeners(); }
  }

  void markAllAlertsRead() { for (final a in alerts) { a.isRead = true; } notifyListeners(); }

  void _addAlert(AdminAlert alert) { alerts.insert(0, alert); }

  void _addActivity(ActivityType type, String message) {
    activityFeed.insert(0, ActivityFeedItem(id: 'act${DateTime.now().millisecondsSinceEpoch}', type: type, message: message, time: DateTime.now()));
    if (activityFeed.length > 50) activityFeed.removeLast();
  }
}