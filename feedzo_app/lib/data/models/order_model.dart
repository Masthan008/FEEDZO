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

/// Represents a selected add-on within a cart item.
class SelectedAddon {
  final String name;
  final double price;

  const SelectedAddon({required this.name, required this.price});

  factory SelectedAddon.fromMap(Map<String, dynamic> map) {
    return SelectedAddon(
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'price': price};
}

class CartItem {
  final MenuItem item;
  int quantity;
  final List<SelectedAddon> selectedAddons;
  final String? selectedVariant; // e.g. "Large", "Medium"
  final double? variantPriceAdjustment;

  CartItem({
    required this.item,
    this.quantity = 1,
    this.selectedAddons = const [],
    this.selectedVariant,
    this.variantPriceAdjustment,
  });

  double get addonTotal => selectedAddons.fold(0, (s, a) => s + a.price);
  double get unitPrice => item.discountedPrice + addonTotal + (variantPriceAdjustment ?? 0);
  double get total => unitPrice * quantity;

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      item: MenuItem.fromMap(map['item'], map['item']['id'] ?? ''),
      quantity: map['quantity'] ?? 1,
      selectedAddons: (map['selectedAddons'] as List?)
              ?.map((a) => SelectedAddon.fromMap(a))
              .toList() ??
          [],
      selectedVariant: map['selectedVariant'] as String?,
      variantPriceAdjustment: (map['variantPriceAdjustment'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item': item.toMap()..['id'] = item.id,
      'quantity': quantity,
      // For compatibility with restaurant app
      'name': item.name,
      'qty': quantity,
      'price': unitPrice,
      if (selectedAddons.isNotEmpty)
        'selectedAddons': selectedAddons.map((a) => a.toMap()).toList(),
      if (selectedVariant != null) 'selectedVariant': selectedVariant,
      if (variantPriceAdjustment != null)
        'variantPriceAdjustment': variantPriceAdjustment,
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
  final String paymentType; // 'cod' or 'online'
  final double? rating;
  final String? ratingComment;
  final bool isRated;
  final DateTime? ratedAt;

  // ── New fields for production readiness ──
  final String? couponCode;
  final double discount;
  final double tipAmount;
  final double deliveryFee;
  final double taxAmount;
  final double platformFee;
  final double driverEarnings;
  final String? deliveryInstructions;
  final DateTime? scheduledFor;
  final String? otpCode;
  final String? cancellationReason;
  final String? refundStatus; // 'pending', 'processed', 'rejected'
  final Map<String, double>? customerLocation; // {lat, lng}
  final Map<String, double>? restaurantLocation; // {lat, lng}
  final String? paymentId; // Razorpay payment ID
  final String? paymentStatus; // 'pending', 'paid', 'refunded'

  /// The final amount the customer pays (subtotal - discount + deliveryFee + tax + tip).
  double get total => totalAmount;

  /// Subtotal before discounts/fees.
  double get subtotal => items.fold(0.0, (s, i) => s + i.total);

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
    this.paymentType = 'cod',
    this.rating,
    this.ratingComment,
    this.isRated = false,
    this.ratedAt,
    // New fields
    this.couponCode,
    this.discount = 0,
    this.tipAmount = 0,
    this.deliveryFee = 0,
    this.taxAmount = 0,
    this.platformFee = 0,
    this.driverEarnings = 0,
    this.deliveryInstructions,
    this.scheduledFor,
    this.otpCode,
    this.cancellationReason,
    this.refundStatus,
    this.customerLocation,
    this.restaurantLocation,
    this.paymentId,
    this.paymentStatus,
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
      paymentType: map['paymentType'] as String? ?? 'cod',
      rating: (map['rating'] as num?)?.toDouble(),
      ratingComment: map['ratingComment'] as String?,
      isRated: map['isRated'] as bool? ?? false,
      ratedAt: (map['ratedAt'] as dynamic)?.toDate(),
      // New fields
      couponCode: map['couponCode'] as String?,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      tipAmount: (map['tipAmount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0,
      platformFee: (map['platformFee'] as num?)?.toDouble() ?? 0,
      driverEarnings: (map['driverEarnings'] as num?)?.toDouble() ?? 0,
      deliveryInstructions: map['deliveryInstructions'] as String?,
      scheduledFor: (map['scheduledFor'] as dynamic)?.toDate(),
      otpCode: map['otpCode'] as String?,
      cancellationReason: map['cancellationReason'] as String?,
      refundStatus: map['refundStatus'] as String?,
      customerLocation: _parseLocation(map['customerLocation']),
      restaurantLocation: _parseLocation(map['restaurantLocation']),
      paymentId: map['paymentId'] as String?,
      paymentStatus: map['paymentStatus'] as String?,
    );
  }

  static Map<String, double>? _parseLocation(dynamic loc) {
    if (loc == null || loc is! Map) return null;
    return {
      'lat': (loc['lat'] as num?)?.toDouble() ?? 0,
      'lng': (loc['lng'] as num?)?.toDouble() ?? 0,
    };
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
      'paymentType': paymentType,
      if (rating != null) 'rating': rating,
      if (ratingComment != null) 'ratingComment': ratingComment,
      'isRated': isRated,
      if (ratedAt != null) 'ratedAt': ratedAt,
      // New fields
      if (couponCode != null) 'couponCode': couponCode,
      if (discount > 0) 'discount': discount,
      if (tipAmount > 0) 'tipAmount': tipAmount,
      if (deliveryFee > 0) 'deliveryFee': deliveryFee,
      if (taxAmount > 0) 'taxAmount': taxAmount,
      if (platformFee > 0) 'platformFee': platformFee,
      if (driverEarnings > 0) 'driverEarnings': driverEarnings,
      if (deliveryInstructions != null)
        'deliveryInstructions': deliveryInstructions,
      if (scheduledFor != null) 'scheduledFor': scheduledFor,
      if (otpCode != null) 'otpCode': otpCode,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      if (refundStatus != null) 'refundStatus': refundStatus,
      if (customerLocation != null) 'customerLocation': customerLocation,
      if (restaurantLocation != null) 'restaurantLocation': restaurantLocation,
      if (paymentId != null) 'paymentId': paymentId,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
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

  /// Creates a copy with modified fields.
  Order copyWith({
    String? id,
    OrderStatus? status,
    String? couponCode,
    double? discount,
    double? tipAmount,
    double? deliveryFee,
    double? taxAmount,
    double? totalAmount,
    String? deliveryInstructions,
    DateTime? scheduledFor,
    String? otpCode,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? cancellationReason,
    String? refundStatus,
    double? rating,
    String? ratingComment,
    bool? isRated,
    DateTime? ratedAt,
    String? paymentId,
    String? paymentStatus,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantImage: restaurantImage,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      items: items,
      totalAmount: totalAmount ?? this.totalAmount,
      address: address,
      status: status ?? this.status,
      createdAt: createdAt,
      paymentType: paymentType,
      rating: rating ?? this.rating,
      ratingComment: ratingComment ?? this.ratingComment,
      isRated: isRated ?? this.isRated,
      ratedAt: ratedAt ?? this.ratedAt,
      couponCode: couponCode ?? this.couponCode,
      discount: discount ?? this.discount,
      tipAmount: tipAmount ?? this.tipAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      taxAmount: taxAmount ?? this.taxAmount,
      platformFee: platformFee,
      driverEarnings: driverEarnings,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      otpCode: otpCode ?? this.otpCode,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      refundStatus: refundStatus ?? this.refundStatus,
      customerLocation: customerLocation,
      restaurantLocation: restaurantLocation,
      paymentId: paymentId ?? this.paymentId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}
