import 'package:cloud_firestore/cloud_firestore.dart';

class SplitPaymentModel {
  final String id;
  final String orderId;
  final double totalAmount;
  final List<SplitPaymentPart> splits;
  final DateTime createdAt;

  SplitPaymentModel({
    required this.id,
    required this.orderId,
    required this.totalAmount,
    required this.splits,
    required this.createdAt,
  });

  factory SplitPaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SplitPaymentModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      splits: (data['splits'] as List?)
              ?.map((s) => SplitPaymentPart.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'totalAmount': totalAmount,
      'splits': splits.map((s) => s.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class SplitPaymentPart {
  final String userId;
  final String userName;
  final String userEmail;
  final double amount;
  final String paymentMethod; // 'wallet', 'card', 'upi', 'cod'
  final String status; // 'pending', 'paid', 'failed'
  final DateTime? paidAt;

  SplitPaymentPart({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.amount,
    required this.paymentMethod,
    this.status = 'pending',
    this.paidAt,
  });

  factory SplitPaymentPart.fromMap(Map<String, dynamic> data) {
    return SplitPaymentPart(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'card',
      status: data['status'] ?? 'pending',
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }
}
