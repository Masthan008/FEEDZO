import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String id;
  final String restaurantId;
  String name;
  String description;
  double price;
  double discount;
  bool isAvailable;
  String imageUrl;
  bool isVeg;
  String category;
  bool isBestseller;
  final DateTime createdAt;
  
  // Inventory/Stock fields
  int stockQuantity; // Current stock count (-1 for unlimited)
  int lowStockThreshold; // Alert when stock below this
  bool trackInventory; // Whether to track stock for this item
  bool unlimitedStock; // If true, stock never depletes

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
    // Inventory fields
    this.stockQuantity = -1, // -1 = unlimited
    this.lowStockThreshold = 5,
    this.trackInventory = false,
    this.unlimitedStock = true,
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
      // Inventory fields
      stockQuantity: data['stockQuantity'] ?? -1,
      lowStockThreshold: data['lowStockThreshold'] ?? 5,
      trackInventory: data['trackInventory'] ?? false,
      unlimitedStock: data['unlimitedStock'] ?? true,
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
      // Inventory fields
      'stockQuantity': stockQuantity,
      'lowStockThreshold': lowStockThreshold,
      'trackInventory': trackInventory,
      'unlimitedStock': unlimitedStock,
    };
  }
  
  /// Check if stock is low
  bool get isLowStock {
    if (!trackInventory || unlimitedStock) return false;
    return stockQuantity <= lowStockThreshold && stockQuantity > 0;
  }
  
  /// Check if out of stock
  bool get isOutOfStock {
    if (!trackInventory || unlimitedStock) return false;
    return stockQuantity <= 0;
  }
  
  /// Check if inventory is valid (stock > 0)
  bool get hasStock {
    if (!trackInventory || unlimitedStock) return true;
    return stockQuantity > 0;
  }
}
