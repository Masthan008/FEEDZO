import 'package:cloud_firestore/cloud_firestore.dart';

class FoodAddonModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? restaurantId; // null means global addon
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  FoodAddonModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.restaurantId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodAddonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodAddonModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      price: (data['price'] ?? 0).toDouble(),
      restaurantId: data['restaurantId'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'restaurantId': restaurantId,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'restaurantId': restaurantId,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
