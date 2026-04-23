import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceModel {
  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String restaurantId;
  final String restaurantName;
  final String restaurantPhone;
  final String restaurantAddress;
  final String driverId;
  final String driverName;
  final double distanceKm;
  final double subtotal;
  final double deliveryFee;
  final double taxAmount;
  final double discount;
  final double tipAmount;
  final double totalAmount;
  final String paymentType;
  final DateTime createdAt;
  final GeoPoint? customerLocation;
  final GeoPoint? restaurantLocation;

  InvoiceModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantPhone,
    required this.restaurantAddress,
    required this.driverId,
    required this.driverName,
    required this.distanceKm,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxAmount,
    required this.discount,
    required this.tipAmount,
    required this.totalAmount,
    required this.paymentType,
    required this.createdAt,
    this.customerLocation,
    this.restaurantLocation,
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    return InvoiceModel(
      id: id,
      orderId: map['orderId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerAddress: map['customerAddress'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'] ?? '',
      restaurantPhone: map['restaurantPhone'] ?? '',
      restaurantAddress: map['restaurantAddress'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tipAmount: (map['tipAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentType: map['paymentType'] ?? 'cod',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customerLocation: map['customerLocation'] as GeoPoint?,
      restaurantLocation: map['restaurantLocation'] as GeoPoint?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantPhone': restaurantPhone,
      'restaurantAddress': restaurantAddress,
      'driverId': driverId,
      'driverName': driverName,
      'distanceKm': distanceKm,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'taxAmount': taxAmount,
      'discount': discount,
      'tipAmount': tipAmount,
      'totalAmount': totalAmount,
      'paymentType': paymentType,
      'createdAt': Timestamp.fromDate(createdAt),
      'customerLocation': customerLocation,
      'restaurantLocation': restaurantLocation,
    };
  }

  InvoiceModel copyWith({String? id}) {
    return InvoiceModel(
      id: id ?? this.id,
      orderId: orderId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantPhone: restaurantPhone,
      restaurantAddress: restaurantAddress,
      driverId: driverId,
      driverName: driverName,
      distanceKm: distanceKm,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      taxAmount: taxAmount,
      discount: discount,
      tipAmount: tipAmount,
      totalAmount: totalAmount,
      paymentType: paymentType,
      createdAt: createdAt,
      customerLocation: customerLocation,
      restaurantLocation: restaurantLocation,
    );
  }
}
