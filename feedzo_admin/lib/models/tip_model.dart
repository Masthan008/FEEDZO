import 'package:cloud_firestore/cloud_firestore.dart';

class TipModel {
  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final String driverId;
  final double amount;
  final String? paymentMethod; // cash, wallet, card
  final DateTime createdAt;

  TipModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.driverId,
    required this.amount,
    this.paymentMethod,
    required this.createdAt,
  });

  factory TipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TipModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      driverId: data['driverId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'driverId': driverId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
