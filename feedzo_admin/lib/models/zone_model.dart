import 'package:cloud_firestore/cloud_firestore.dart';

class ZoneModel {
  final String id;
  final String name;
  final String? description;
  final List<double> coordinates; // [latitude, longitude]
  final double baseDeliveryCharge;
  final double perKmCharge;
  final double minOrderValue;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ZoneModel({
    required this.id,
    required this.name,
    this.description,
    required this.coordinates,
    this.baseDeliveryCharge = 20.0,
    this.perKmCharge = 5.0,
    this.minOrderValue = 100.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ZoneModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ZoneModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      coordinates: List<double>.from(data['coordinates'] ?? []),
      baseDeliveryCharge: (data['baseDeliveryCharge'] ?? 20.0).toDouble(),
      perKmCharge: (data['perKmCharge'] ?? 5.0).toDouble(),
      minOrderValue: (data['minOrderValue'] ?? 100.0).toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'coordinates': coordinates,
      'baseDeliveryCharge': baseDeliveryCharge,
      'perKmCharge': perKmCharge,
      'minOrderValue': minOrderValue,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'description': description,
      'coordinates': coordinates,
      'baseDeliveryCharge': baseDeliveryCharge,
      'perKmCharge': perKmCharge,
      'minOrderValue': minOrderValue,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
