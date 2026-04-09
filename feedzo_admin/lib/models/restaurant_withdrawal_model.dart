import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantWithdrawalModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final double amount;
  final String method; // bank_transfer, upi, cash
  final Map<String, dynamic> methodDetails;
  final String status; // pending, processing, completed, rejected
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? processedBy;

  RestaurantWithdrawalModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.amount,
    required this.method,
    required this.methodDetails,
    this.status = 'pending',
    this.rejectionReason,
    required this.createdAt,
    this.processedAt,
    this.processedBy,
  });

  factory RestaurantWithdrawalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RestaurantWithdrawalModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      method: data['method'] ?? 'bank_transfer',
      methodDetails: data['methodDetails'] ?? {},
      status: data['status'] ?? 'pending',
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      processedBy: data['processedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'amount': amount,
      'method': method,
      'methodDetails': methodDetails,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'status': status,
      'rejectionReason': rejectionReason,
      'processedAt': FieldValue.serverTimestamp(),
      'processedBy': processedBy,
    };
  }
}

class WithdrawalMethodConfig {
  final String id;
  final String name;
  final String type; // text, number, select
  final String placeholder;
  final bool isRequired;
  final List<String>? options;

  WithdrawalMethodConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.placeholder,
    this.isRequired = true,
    this.options,
  });

  factory WithdrawalMethodConfig.fromMap(Map<String, dynamic> map) {
    return WithdrawalMethodConfig(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'text',
      placeholder: map['placeholder'] ?? '',
      isRequired: map['isRequired'] ?? true,
      options: map['options'] != null ? List<String>.from(map['options']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'placeholder': placeholder,
      'isRequired': isRequired,
      'options': options,
    };
  }
}
