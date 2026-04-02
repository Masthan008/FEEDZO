import 'restaurant_model.dart';

enum OrderStatus {
  placed,
  preparing,
  ready,
  picked,
  outForDelivery,
  delivered,
  cancelled,
}

class CartItem {
  final MenuItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  double get total => item.discountedPrice * quantity;

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      item: MenuItem.fromMap(map['item'], map['item']['id'] ?? ''),
      quantity: map['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item': item.toMap()..['id'] = item.id,
      'quantity': quantity,
      // For compatibility with restaurant app
      'name': item.name,
      'qty': quantity,
      'price': item.discountedPrice,
    };
  }
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String restaurantId;
  final String restaurantName;
  final String restaurantImage;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final List<CartItem> items;
  final double totalAmount;
  final String address;
  final OrderStatus status;
  final DateTime createdAt;

  double get total => totalAmount;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantImage,
    this.driverId,
    this.driverName,
    this.driverPhone,
    required this.items,
    required this.totalAmount,
    required this.address,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? map['phone'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'] ?? '',
      restaurantImage: map['restaurantImage'] ?? '',
      driverId: map['driverId'],
      driverName: map['driverName'],
      driverPhone: map['driverPhone'],
      items: (map['items'] as List? ?? [])
          .map((i) => CartItem.fromMap(i))
          .toList(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'placed'),
        orElse: () => OrderStatus.placed,
      ),
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'phone': customerPhone, // For compatibility with restaurant app
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantImage': restaurantImage,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'address': address,
      'status': status.name,
      'createdAt': createdAt,
    };
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready to Pick';
      case OrderStatus.picked:
        return 'Picked Up';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
