import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, preparing, outForDelivery, delivered, cancelled }
enum DriverStatus { available, busy, offline }
enum RestaurantStatus { active, disabled, pendingApproval }
enum UserStatus { active, blocked }
enum TransactionType { commission, payout }
enum AlertType { orderAlert, loginActivity, systemEvent }
enum PaymentMode { cod, online }
enum SettlementStatus { pending, partial, settled }

class AdminOrder {
  final String id;
  final String customerId;
  final String customerName;
  final String restaurantId;
  final String restaurantName;
  double orderValue;
  double commissionRate;
  OrderStatus status;
  String? assignedDriverId;
  String? assignedDriverName;
  final DateTime placedAt;
  final List<String> items;
  bool paymentReleased;
  final List<OrderTimelineEvent> timeline;

  AdminOrder({
    required this.id, required this.customerId, required this.customerName,
    required this.restaurantId, required this.restaurantName,
    required this.orderValue, required this.commissionRate, required this.status,
    this.assignedDriverId, this.assignedDriverName,
    required this.placedAt, required this.items,
    this.paymentReleased = false, List<OrderTimelineEvent>? timeline,
  }) : timeline = timeline ?? [];

  factory AdminOrder.fromMap(String id, Map<String, dynamic> map) {
    return AdminOrder(
      id: id,
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? 'Unknown Customer',
      restaurantId: map['restaurantId'] as String? ?? '',
      restaurantName: map['restaurantName'] as String? ?? 'Unknown Restaurant',
      orderValue: ((map['totalAmount'] ?? map['orderValue'] ?? 0) as num).toDouble(),
      commissionRate: ((map['commissionRate'] ?? 0.10) as num).toDouble(),
      status: OrderStatus.values.firstWhere((e) => e.name == (map['status'] ?? 'pending'), orElse: () => OrderStatus.pending),
      assignedDriverId: map['driverId'] as String?,
      assignedDriverName: map['driverName'] as String?,
      placedAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: (map['items'] as List?)?.map((e) => e is Map ? '${e['name'] ?? ''} x${e['qty'] ?? 1}' : e.toString()).toList() ?? [],
      paymentReleased: map['paymentReleased'] as bool? ?? false,
      timeline: (map['timeline'] as List?)?.map((e) => OrderTimelineEvent(label: e['label'], time: (e['time'] as Timestamp?)?.toDate() ?? DateTime.now())).toList() ?? [],
    );
  }

  double get commission => orderValue * commissionRate;
  double get restaurantPayout => orderValue - commission;
  bool get isDelayed => status == OrderStatus.pending && DateTime.now().difference(placedAt).inMinutes > 20;

  String get statusLabel {
    switch (status) {
      case OrderStatus.pending: return 'Pending';
      case OrderStatus.preparing: return 'Preparing';
      case OrderStatus.outForDelivery: return 'Out for Delivery';
      case OrderStatus.delivered: return 'Delivered';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }
}

class OrderTimelineEvent {
  final String label;
  final DateTime time;
  final IconData? icon;
  const OrderTimelineEvent({required this.label, required this.time, this.icon});
}

class Driver {
  final String id;
  final String name;
  final String phone;
  final String vehicle;
  DriverStatus status;
  final int totalDeliveries;
  final double rating;
  final double totalEarnings;
  String? currentOrderId;

  Driver({
    required this.id, required this.name, required this.phone, required this.vehicle,
    required this.status, required this.totalDeliveries, required this.rating,
    required this.totalEarnings, this.currentOrderId,
  });

  factory Driver.fromMap(String id, Map<String, dynamic> map) {
    return Driver(
      id: id,
      name: map['name'] as String? ?? 'Unknown Driver',
      phone: map['phone'] as String? ?? '',
      vehicle: map['vehicle'] as String? ?? 'N/A',
      status: DriverStatus.values.firstWhere((e) => e.name == (map['status'] ?? 'offline'), orElse: () => DriverStatus.offline),
      totalDeliveries: (map['totalDeliveries'] as num?)?.toInt() ?? 0,
      rating: ((map['rating'] ?? 5.0) as num).toDouble(),
      totalEarnings: ((map['totalEarnings'] ?? 0) as num).toDouble(),
      currentOrderId: map['currentOrderId'] as String?,
    );
  }
}

class AdminRestaurant {
  final String id;
  final String name;
  final String cuisine;
  final String location;
  final double rating;
  RestaurantStatus status;
  final int totalOrders;
  final double totalRevenue;
  double walletBalance;
  double commissionRate;
  final List<Transaction> transactions;

  AdminRestaurant({
    required this.id, required this.name, required this.cuisine, required this.location,
    required this.rating, required this.status, required this.totalOrders,
    required this.totalRevenue, required this.walletBalance,
    this.commissionRate = 0.10,
    required this.transactions,
  });

  factory AdminRestaurant.fromMap(String id, Map<String, dynamic> map) {
    return AdminRestaurant(
      id: id,
      name: map['name'] as String? ?? 'Unknown Restaurant',
      cuisine: map['cuisine'] as String? ?? '',
      location: map['location'] as String? ?? map['address'] as String? ?? '',
      rating: ((map['rating'] ?? 5.0) as num).toDouble(),
      status: RestaurantStatus.values.firstWhere((e) => e.name == (map['status'] ?? 'pendingApproval'), orElse: () => RestaurantStatus.pendingApproval),
      totalOrders: (map['totalOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: ((map['totalRevenue'] ?? 0) as num).toDouble(),
      walletBalance: ((map['wallet'] ?? map['walletBalance'] ?? 0) as num).toDouble(),
      commissionRate: ((map['commission'] ?? map['commissionRate'] ?? 0.10) as num).toDouble(),
      transactions: [], 
    );
  }

  double get commissionEarned => totalRevenue * commissionRate;
  double get restaurantEarnings => totalRevenue - commissionEarned;
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  UserStatus status;
  final int totalOrders;
  final double totalSpent;
  final DateTime joinedAt;

  AppUser({
    required this.id, required this.name, required this.email, required this.phone,
    required this.status, required this.totalOrders, required this.totalSpent,
    required this.joinedAt,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      name: map['name'] as String? ?? 'Unknown',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      status: UserStatus.values.firstWhere((e) => e.name == (map['status'] ?? 'active'), orElse: () => UserStatus.active),
      totalOrders: (map['totalOrders'] as num?)?.toInt() ?? 0,
      totalSpent: ((map['totalSpent'] ?? 0) as num).toDouble(),
      joinedAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class Transaction {
  final String id;
  final String orderId;
  final double amount;
  final double commission;
  final TransactionType type;
  final DateTime date;
  final String note;
  final bool paid;

  const Transaction({
    required this.id, required this.orderId, required this.amount,
    this.commission = 0, required this.type, required this.date,
    required this.note, this.paid = false,
  });
}

enum AlertSeverity { high, medium, low }

class AdminAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final AlertType type;
  final DateTime createdAt;
  bool isRead;
  final String? customerName;
  final String? restaurantName;
  final List<String>? orderedItems;
  final String? orderId;

  AdminAlert({
    required this.id, required this.title, required this.description,
    required this.severity, required this.type, required this.createdAt,
    this.isRead = false, this.customerName, this.restaurantName,
    this.orderedItems, this.orderId,
  });

  factory AdminAlert.fromMap(String id, Map<String, dynamic> map) {
    return AdminAlert(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      severity: AlertSeverity.values.firstWhere((e) => e.name == (map['severity'] ?? 'low'), orElse: () => AlertSeverity.low),
      type: AlertType.values.firstWhere((e) => e.name == (map['type'] ?? 'systemEvent'), orElse: () => AlertType.systemEvent),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
      customerName: map['customerName'] as String?,
      restaurantName: map['restaurantName'] as String?,
      orderedItems: (map['orderedItems'] as List?)?.map((e) => e.toString()).toList(),
      orderId: map['orderId'] as String?,
    );
  }
}

enum ActivityType { orderPlaced, driverAssigned, orderDelivered, orderDelayed, paymentReleased, loginCustomer, loginRestaurant, loginDriver, cashSubmitted }

class ActivityFeedItem {
  final String id;
  final ActivityType type;
  final String message;
  final DateTime time;
  const ActivityFeedItem({required this.id, required this.type, required this.message, required this.time});

  factory ActivityFeedItem.fromMap(String id, Map<String, dynamic> map) {
    return ActivityFeedItem(
      id: id,
      type: ActivityType.values.firstWhere((e) => e.name == (map['type'] ?? 'systemEvent'), orElse: () => ActivityType.loginCustomer),
      message: map['message'] as String? ?? '',
      time: (map['time'] ?? map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class DriverDailySummary {
  final String driverId;
  final DateTime date;
  final int totalOrders;
  final int codOrders;
  final double codAmount;
  final int onlineOrders;
  final double onlineAmount;
  double submittedAmount;
  final List<CashSubmission> submissions;

  DriverDailySummary({
    required this.driverId, required this.date, required this.totalOrders,
    required this.codOrders, required this.codAmount, required this.onlineOrders,
    required this.onlineAmount, required this.submittedAmount,
    List<CashSubmission>? submissions,
  }) : submissions = submissions ?? [];

  factory DriverDailySummary.fromMap(String id, Map<String, dynamic> map) {
    return DriverDailySummary(
      driverId: id,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalOrders: (map['totalOrders'] as num?)?.toInt() ?? 0,
      codOrders: (map['codOrders'] as num?)?.toInt() ?? 0,
      codAmount: ((map['codAmount'] ?? 0) as num).toDouble(),
      onlineOrders: (map['onlineOrders'] as num?)?.toInt() ?? 0,
      onlineAmount: ((map['onlineAmount'] ?? 0) as num).toDouble(),
      submittedAmount: ((map['submitted'] ?? map['submittedAmount'] ?? 0) as num).toDouble(),
    );
  }

  double get pendingAmount => codAmount - submittedAmount;
  SettlementStatus get settlementStatus {
    if (submittedAmount <= 0) return SettlementStatus.pending;
    if (submittedAmount >= codAmount) return SettlementStatus.settled;
    return SettlementStatus.partial;
  }
}

class CashSubmission {
  final String id;
  final double amount;
  final DateTime submittedAt;
  final String note;
  const CashSubmission({required this.id, required this.amount, required this.submittedAt, this.note = ''});
}

class DriverSettlementRecord {
  final String driverId;
  final DateTime date;
  final int ordersCompleted;
  final double codCollected;
  final double submittedAmount;
  const DriverSettlementRecord({
    required this.driverId, required this.date, required this.ordersCompleted,
    required this.codCollected, required this.submittedAmount,
  });
  double get pending => codCollected - submittedAmount;
}

// ─── System Settings ──────────────────────────────────────────────────────────

class SystemSettings {
  bool codEnabled;
  bool driverSettlementEnabled;

  SystemSettings({this.codEnabled = true, this.driverSettlementEnabled = true});
}