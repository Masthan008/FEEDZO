import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringOrderModel {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final List<int> daysOfWeek; // 1-7 for weekly
  final int dayOfMonth; // 1-31 for monthly
  final String preferredTime;
  final String deliveryAddress;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;

  RecurringOrderModel({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    required this.items,
    required this.totalAmount,
    required this.frequency,
    this.daysOfWeek = const [],
    this.dayOfMonth = 1,
    required this.preferredTime,
    required this.deliveryAddress,
    this.isActive = true,
    required this.startDate,
    this.endDate,
    required this.createdAt,
  });

  factory RecurringOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecurringOrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      items: (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      frequency: data['frequency'] ?? 'weekly',
      daysOfWeek: (data['daysOfWeek'] as List?)?.cast<int>() ?? [],
      dayOfMonth: data['dayOfMonth'] ?? 1,
      preferredTime: data['preferredTime'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      isActive: data['isActive'] ?? true,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'items': items,
      'totalAmount': totalAmount,
      'frequency': frequency,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'preferredTime': preferredTime,
      'deliveryAddress': deliveryAddress,
      'isActive': isActive,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
