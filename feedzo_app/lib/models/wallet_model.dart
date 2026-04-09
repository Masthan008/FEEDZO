import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String id;
  final String userId;
  final double balance;
  final double bonus;
  final List<WalletTransaction> transactions;
  final DateTime updatedAt;

  WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    this.bonus = 0,
    this.transactions = const [],
    required this.updatedAt,
  });

  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      balance: (data['balance'] ?? 0).toDouble(),
      bonus: (data['bonus'] ?? 0).toDouble(),
      transactions: (data['transactions'] as List?)
              ?.map((t) => WalletTransaction.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'balance': balance,
      'bonus': bonus,
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class WalletTransaction {
  final String id;
  final String type; // 'credit', 'debit', 'bonus_credit', 'bonus_debit'
  final double amount;
  final String description;
  final DateTime createdAt;
  final String? orderId;
  final String? referenceId;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.orderId,
    this.referenceId,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> data) {
    return WalletTransaction(
      id: data['id'] ?? '',
      type: data['type'] ?? 'credit',
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      orderId: data['orderId'],
      referenceId: data['referenceId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'createdAt': createdAt,
      'orderId': orderId,
      'referenceId': referenceId,
    };
  }
}
