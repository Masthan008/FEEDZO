import 'package:cloud_firestore/cloud_firestore.dart';

class CuisineModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int priority; // 0 = normal, 1 = medium, 2 = high
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CuisineModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.priority = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CuisineModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CuisineModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      priority: data['priority'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'priority': priority,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'priority': priority,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
