import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String id;
  final String restaurantId;
  String name;
  String description;
  double price;
  double discount; // Changed from discountPercent (int?) to match customer app
  bool isAvailable;
  String imageUrl;
  bool isVeg;
  String category; // Added to match customer app
  bool isBestseller;
  final DateTime createdAt;

  MenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    this.discount = 0.0,
    required this.isAvailable,
    required this.imageUrl,
    this.isVeg = true,
    this.category = 'Main Course',
    this.isBestseller = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get discountedPrice {
    if (discount == 0) return price;
    return price * (1 - (discount / 100));
  }

  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuItemModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0.0).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      imageUrl: data['imageUrl'] ?? '',
      isVeg: data['isVeg'] ?? true,
      category: data['category'] ?? 'Main Course',
      isBestseller: data['isBestseller'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'discount': discount,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'isVeg': isVeg,
      'category': category,
      'isBestseller': isBestseller,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
