import 'package:cloud_firestore/cloud_firestore.dart';

class DriverEarningsModel {
  final String id;
  final String driverId;
  final String driverName;
  final double totalEarnings;
  final double tipEarnings;
  final double deliveryEarnings;
  final double bonusEarnings;
  final double deductions;
  final double netEarnings;
  final int totalDeliveries;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime createdAt;

  DriverEarningsModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.totalEarnings,
    this.tipEarnings = 0,
    this.deliveryEarnings = 0,
    this.bonusEarnings = 0,
    this.deductions = 0,
    required this.netEarnings,
    this.totalDeliveries = 0,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
  });

  factory DriverEarningsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DriverEarningsModel(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      totalEarnings: (data['totalEarnings'] ?? 0).toDouble(),
      tipEarnings: (data['tipEarnings'] ?? 0).toDouble(),
      deliveryEarnings: (data['deliveryEarnings'] ?? 0).toDouble(),
      bonusEarnings: (data['bonusEarnings'] ?? 0).toDouble(),
      deductions: (data['deductions'] ?? 0).toDouble(),
      netEarnings: (data['netEarnings'] ?? 0).toDouble(),
      totalDeliveries: data['totalDeliveries'] ?? 0,
      periodStart: (data['periodStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      periodEnd: (data['periodEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'totalEarnings': totalEarnings,
      'tipEarnings': tipEarnings,
      'deliveryEarnings': deliveryEarnings,
      'bonusEarnings': bonusEarnings,
      'deductions': deductions,
      'netEarnings': netEarnings,
      'totalDeliveries': totalDeliveries,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
