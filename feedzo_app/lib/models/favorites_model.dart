import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesModel {
  final String id;
  final String userId;
  final List<FavoriteItem> favoriteRestaurants;
  final List<FavoriteItem> favoriteItems;
  final DateTime updatedAt;

  FavoritesModel({
    required this.id,
    required this.userId,
    this.favoriteRestaurants = const [],
    this.favoriteItems = const [],
    required this.updatedAt,
  });

  factory FavoritesModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoritesModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      favoriteRestaurants: (data['favoriteRestaurants'] as List?)
              ?.map((r) => FavoriteItem.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      favoriteItems: (data['favoriteItems'] as List?)
              ?.map((i) => FavoriteItem.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'favoriteRestaurants': favoriteRestaurants.map((r) => r.toMap()).toList(),
      'favoriteItems': favoriteItems.map((i) => i.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class FavoriteItem {
  final String id;
  final String name;
  final String? imageUrl;
  final DateTime addedAt;

  FavoriteItem({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.addedAt,
  });

  factory FavoriteItem.fromMap(Map<String, dynamic> data) {
    return FavoriteItem(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'],
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'addedAt': addedAt,
    };
  }
}
