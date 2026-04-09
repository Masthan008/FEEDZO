import 'package:cloud_firestore/cloud_firestore.dart';

class CashLimitModel {
  final String id;
  final String driverId;
  final String driverName;
  final double maxCashInHand;
  final double currentCash;
  final DateTime updatedAt;

  CashLimitModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.maxCashInHand,
    this.currentCash = 0,
    required this.updatedAt,
  });

  factory CashLimitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CashLimitModel(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      maxCashInHand: (data['maxCashInHand'] ?? 0).toDouble(),
      currentCash: (data['currentCash'] ?? 0).toDouble(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'maxCashInHand': maxCashInHand,
      'currentCash': currentCash,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'maxCashInHand': maxCashInHand,
      'currentCash': currentCash,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool get isOverLimit => currentCash > maxCashInHand;
  double get remaining => maxCashInHand - currentCash;
}
