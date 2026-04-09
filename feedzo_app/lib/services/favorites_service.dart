import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/favorites_model.dart';

class FavoritesService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _favorites = _db.collection('favorites');

  static Stream<FavoritesModel?> watchFavorites(String userId) {
    return _favorites.where('userId', isEqualTo: userId).limit(1).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return FavoritesModel.fromFirestore(snap.docs.first);
    });
  }

  static Future<FavoritesModel?> getFavorites(String userId) async {
    final snapshot = await _favorites.where('userId', isEqualTo: userId).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return FavoritesModel.fromFirestore(snapshot.docs.first);
  }

  static Future<void> addFavoriteRestaurant(String userId, String restaurantId, String name, {String? imageUrl}) async {
    final favorites = await getFavorites(userId);
    final favoriteItem = FavoriteItem(
      id: restaurantId,
      name: name,
      imageUrl: imageUrl,
      addedAt: DateTime.now(),
    );

    if (favorites == null) {
      await _favorites.add({
        'userId': userId,
        'favoriteRestaurants': [favoriteItem.toMap()],
        'favoriteItems': [],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _favorites.doc(favorites.id).update({
        'favoriteRestaurants': FieldValue.arrayUnion([favoriteItem.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> removeFavoriteRestaurant(String userId, String restaurantId) async {
    final favorites = await getFavorites(userId);
    if (favorites == null) return;

    final updatedList = favorites.favoriteRestaurants.where((r) => r.id != restaurantId).toList();
    await _favorites.doc(favorites.id).update({
      'favoriteRestaurants': updatedList.map((r) => r.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> addFavoriteItem(String userId, String itemId, String name, {String? imageUrl}) async {
    final favorites = await getFavorites(userId);
    final favoriteItem = FavoriteItem(
      id: itemId,
      name: name,
      imageUrl: imageUrl,
      addedAt: DateTime.now(),
    );

    if (favorites == null) {
      await _favorites.add({
        'userId': userId,
        'favoriteRestaurants': [],
        'favoriteItems': [favoriteItem.toMap()],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _favorites.doc(favorites.id).update({
        'favoriteItems': FieldValue.arrayUnion([favoriteItem.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> removeFavoriteItem(String userId, String itemId) async {
    final favorites = await getFavorites(userId);
    if (favorites == null) return;

    final updatedList = favorites.favoriteItems.where((i) => i.id != itemId).toList();
    await _favorites.doc(favorites.id).update({
      'favoriteItems': updatedList.map((i) => i.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static bool isRestaurantFavorite(FavoritesModel? favorites, String restaurantId) {
    return favorites?.favoriteRestaurants.any((r) => r.id == restaurantId) ?? false;
  }

  static bool isItemFavorite(FavoritesModel? favorites, String itemId) {
    return favorites?.favoriteItems.any((i) => i.id == itemId) ?? false;
  }
}
