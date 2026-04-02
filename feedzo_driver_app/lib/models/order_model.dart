enum OrderStatus {
  pending,
  accepted,
  pickedUp,
  onTheWay,
  delivered,
}

extension OrderStatusExt on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.onTheWay:
        return 'On The Way';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  int get step {
    return OrderStatus.values.indexOf(this);
  }
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}

class DriverOrder {
  final String id;
  final String restaurantName;
  final String restaurantAddress;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final double distance;
  final double earnings;
  final List<OrderItem> items;
  OrderStatus status;
  final DateTime createdAt;

  DriverOrder({
    required this.id,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
    required this.distance,
    required this.earnings,
    required this.items,
    this.status = OrderStatus.pending,
    required this.createdAt,
  });

  double get totalAmount => items.fold(0, (sum, i) => sum + i.price * i.quantity);
}
