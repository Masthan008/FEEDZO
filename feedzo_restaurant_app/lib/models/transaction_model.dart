import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { earning, commission, withdrawal }

class TransactionModel {
  final String id;
  final String? orderId;
  final String description;
  final double amount;
  final double? commission;
  final DateTime date;
  final TransactionType type;

  TransactionModel({
    required this.id,
    this.orderId,
    required this.description,
    required this.amount,
    this.commission,
    required this.date,
    required this.type,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      orderId: data['orderId'],
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      commission: (data['commission'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: TransactionType.values.firstWhere((e) => e.name == data['type'], orElse: () => TransactionType.earning),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'description': description,
      'amount': amount,
      'commission': commission,
      'date': FieldValue.serverTimestamp(),
      'type': type.name,
    };
  }
}
