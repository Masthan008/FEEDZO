import 'package:cloud_firestore/cloud_firestore.dart';

/// Customer detail model for admin view
class CustomerDetail {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final DateTime joinedAt;
  final String status;
  final List<String> savedAddresses;
  final Map<String, dynamic>? preferences;
  
  // Statistics
  final int totalOrders;
  final double totalSpent;
  final double averageOrderValue;
  final DateTime? lastOrderAt;
  final String? favoriteRestaurant;
  
  // Current/Live data
  final List<CustomerOrderSummary> recentOrders;
  final CustomerOrderSummary? activeOrder;
  
  // Location data
  final Map<String, dynamic>? lastKnownLocation;
  final String? defaultAddress;

  CustomerDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.joinedAt,
    required this.status,
    required this.savedAddresses,
    this.preferences,
    required this.totalOrders,
    required this.totalSpent,
    required this.averageOrderValue,
    this.lastOrderAt,
    this.favoriteRestaurant,
    required this.recentOrders,
    this.activeOrder,
    this.lastKnownLocation,
    this.defaultAddress,
  });

  factory CustomerDetail.fromMap(String id, Map<String, dynamic> userData, 
      List<CustomerOrderSummary> orders, Map<String, dynamic> stats) {
    // Find active order (not delivered or cancelled)
    final active = orders.firstWhere(
      (o) => o.status != 'delivered' && o.status != 'cancelled',
      orElse: () => null as CustomerOrderSummary,
    );
    
    return CustomerDetail(
      id: id,
      name: userData['name'] ?? 'Unknown',
      email: userData['email'] ?? '',
      phone: userData['phone'] ?? '',
      photoUrl: userData['photoUrl'],
      joinedAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: userData['status'] ?? 'active',
      savedAddresses: List<String>.from(userData['savedAddresses'] ?? []),
      preferences: userData['preferences'],
      totalOrders: stats['totalOrders'] ?? 0,
      totalSpent: (stats['totalSpent'] ?? 0).toDouble(),
      averageOrderValue: (stats['averageOrderValue'] ?? 0).toDouble(),
      lastOrderAt: stats['lastOrderAt'] != null 
          ? (stats['lastOrderAt'] as Timestamp).toDate() 
          : null,
      favoriteRestaurant: stats['favoriteRestaurant'],
      recentOrders: orders.take(10).toList(),
      activeOrder: active.status != null ? active : null,
      lastKnownLocation: userData['lastLocation'],
      defaultAddress: userData['defaultAddress'],
    );
  }
}

/// Simplified order info for customer detail view
class CustomerOrderSummary {
  final String orderId;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantImage;
  final DateTime orderedAt;
  final DateTime? deliveredAt;
  final double totalAmount;
  final String status;
  final String paymentType;
  final String? deliveryAddress;
  final List<OrderItemSummary> items;
  final String? driverName;
  final String? driverPhone;
  final Map<String, dynamic>? trackingData;
  final Map<String, dynamic>? locationData;

  CustomerOrderSummary({
    required this.orderId,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantImage,
    required this.orderedAt,
    this.deliveredAt,
    required this.totalAmount,
    required this.status,
    required this.paymentType,
    this.deliveryAddress,
    required this.items,
    this.driverName,
    this.driverPhone,
    this.trackingData,
    this.locationData,
  });

  factory CustomerOrderSummary.fromMap(String id, Map<String, dynamic> map) {
    return CustomerOrderSummary(
      orderId: id,
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'] ?? 'Unknown Restaurant',
      restaurantImage: map['restaurantImage'],
      orderedAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveredAt: (map['deliveredAt'] as Timestamp?)?.toDate(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'placed',
      paymentType: map['paymentType'] ?? 'cod',
      deliveryAddress: map['address'],
      items: (map['items'] as List<dynamic>? ?? [])
          .map((i) => OrderItemSummary.fromMap(i as Map<String, dynamic>))
          .toList(),
      driverName: map['driverName'],
      driverPhone: map['driverPhone'],
      trackingData: map['tracking'],
      locationData: map['locationData'],
    );
  }

  bool get isActive => status != 'delivered' && status != 'cancelled';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  
  String get statusLabel {
    switch (status) {
      case 'placed': return 'Order Placed';
      case 'preparing': return 'Preparing';
      case 'picked': return 'Out for Delivery';
      case 'delivered': return 'Delivered';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }
}

class OrderItemSummary {
  final String name;
  final int quantity;
  final double price;
  final bool isVeg;
  final String? variant;
  final List<String> addons;

  OrderItemSummary({
    required this.name,
    required this.quantity,
    required this.price,
    required this.isVeg,
    this.variant,
    required this.addons,
  });

  factory OrderItemSummary.fromMap(Map<String, dynamic> map) {
    return OrderItemSummary(
      name: map['name'] ?? 'Unknown Item',
      quantity: map['qty'] ?? map['quantity'] ?? 1,
      price: (map['price'] ?? 0).toDouble(),
      isVeg: map['isVeg'] ?? false,
      variant: map['selectedVariant'],
      addons: (map['selectedAddons'] as List<dynamic>? ?? [])
          .map((a) => a['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }

  double get total => price * quantity;
}
