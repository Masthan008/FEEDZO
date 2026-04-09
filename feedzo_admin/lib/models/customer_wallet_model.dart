import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerWalletModel {
  final String id;
  final String customerId;
  final double balance;
  final List<WalletTransaction> transactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerWalletModel({
    required this.id,
    required this.customerId,
    required this.balance,
    this.transactions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerWalletModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerWalletModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      balance: (data['balance'] ?? 0).toDouble(),
      transactions: (data['transactions'] as List<dynamic>?)
              ?.map((t) => WalletTransaction.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'balance': balance,
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class WalletTransaction {
  final String id;
  final String type; // credit, debit
  final double amount;
  final String? description;
  final String? reference;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    this.reference,
    required this.createdAt,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: map['type'] ?? 'credit',
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'],
      reference: map['reference'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'reference': reference,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class LoyaltyPointModel {
  final String id;
  final String customerId;
  final int points;
  final List<PointTransaction> transactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoyaltyPointModel({
    required this.id,
    required this.customerId,
    required this.points,
    this.transactions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoyaltyPointModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoyaltyPointModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      points: data['points'] ?? 0,
      transactions: (data['transactions'] as List<dynamic>?)
              ?.map((t) => PointTransaction.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'points': points,
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class PointTransaction {
  final String id;
  final String type; // earn, redeem
  final int points;
  final String? description;
  final DateTime createdAt;

  PointTransaction({
    required this.id,
    required this.type,
    required this.points,
    this.description,
    required this.createdAt,
  });

  factory PointTransaction.fromMap(Map<String, dynamic> map) {
    return PointTransaction(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: map['type'] ?? 'earn',
      points: map['points'] ?? 0,
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'points': points,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
