import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  placed,
  preparing,
  ready,
  picked,
  outForDelivery,
  delivered,
  cancelled,
}

class OrderItem {
  final String name;
  final int qty;
  final double price;

  OrderItem({required this.name, required this.qty, required this.price});

  double get total => qty * price;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      qty: map['qty'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'qty': qty, 'price': price};
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String phone;
  final String address;
  final List<OrderItem> items;
  OrderStatus status;
  final DateTime createdAt;
  final String restaurantId;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final double totalAmount;
  final int? prepTime; // in minutes
  final double? driverLat;
  final double? driverLng;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.restaurantId,
    this.driverId,
    this.driverName,
    this.driverPhone,
    required this.totalAmount,
    this.prepTime,
    this.driverLat,
    this.driverLng,
  });

  double get total => items.fold(0, (sum, item) => sum + item.total);

  String get statusLabel {
    switch (status) {
      case OrderStatus.placed:
        return 'Placed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready to Pick';
      case OrderStatus.picked:
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      items: (data['items'] as List? ?? [])
          .map((i) => OrderItem.fromMap(i))
          .toList(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'placed'),
        orElse: () => OrderStatus.placed,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      restaurantId: data['restaurantId'] ?? '',
      driverId: data['driverId'],
      driverName: data['driverName'],
      driverPhone: data['driverPhone'],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      prepTime: data['prepTime'],
      driverLat: (data['driverLat'] ?? 0).toDouble(),
      driverLng: (data['driverLng'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'items': items.map((i) => i.toMap()).toList(),
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'restaurantId': restaurantId,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'totalAmount': totalAmount,
      'prepTime': prepTime,
      'driverLat': driverLat,
      'driverLng': driverLng,
    };
  }
}
