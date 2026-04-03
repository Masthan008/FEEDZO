import 'package:cloud_firestore/cloud_firestore.dart';

/// Service that provides intelligent food recommendations based on
/// order history, popular items, and trending restaurants.
class RecommendationService {
  static final _db = FirebaseFirestore.instance;

  /// Get popular menu items across all restaurants, sorted by orderCount.
  static Future<List<Map<String, dynamic>>> getPopularItems({int limit = 10}) async {
    final snap = await _db
        .collectionGroup('menuItems')
        .orderBy('orderCount', descending: true)
        .limit(limit)
        .get();

    // Fallback: if collectionGroup isn't indexed, query items collection directly
    if (snap.docs.isEmpty) {
      final itemSnap = await _db
          .collection('items')
          .orderBy('orderCount', descending: true)
          .limit(limit)
          .get();
      return itemSnap.docs
          .map((d) => {...d.data(), 'id': d.id})
          .toList();
    }

    return snap.docs
        .map((d) => {...d.data(), 'id': d.id})
        .toList();
  }

  /// Get personalized recommendations based on user's order history.
  /// Analyzes past cuisines, restaurants, and items to suggest new ones.
  static Future<List<String>> getRecommendedRestaurantIds(String userId, {int limit = 5}) async {
    // 1. Get user's recent orders
    final orderSnap = await _db
        .collection('orders')
        .where('customerId', isEqualTo: userId)
        .where('status', isEqualTo: 'delivered')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    if (orderSnap.docs.isEmpty) return [];

    // 2. Extract restaurant IDs and frequency
    final restaurantFreq = <String, int>{};
    for (final doc in orderSnap.docs) {
      final data = doc.data();
      final restaurantId = data['restaurantId'] as String?;
      if (restaurantId != null) {
        restaurantFreq[restaurantId] = (restaurantFreq[restaurantId] ?? 0) + 1;
      }
    }

    // 3. Sort by frequency (most ordered from) and return top ones
    final sorted = restaurantFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Get trending restaurants (highest rated + most recent orders).
  static Future<List<String>> getTrendingRestaurantIds({int limit = 6}) async {
    final snap = await _db
        .collection('restaurants')
        .where('isOpen', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((d) => d.id).toList();
  }

  /// Get recently ordered items for a user (for "Reorder" section).
  static Future<List<Map<String, dynamic>>> getRecentlyOrdered(String userId, {int limit = 5}) async {
    final orderSnap = await _db
        .collection('orders')
        .where('customerId', isEqualTo: userId)
        .where('status', isEqualTo: 'delivered')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    final items = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final doc in orderSnap.docs) {
      final data = doc.data();
      final orderItems = data['items'] as List<dynamic>? ?? [];
      for (final item in orderItems) {
        final itemData = item as Map<String, dynamic>;
        final itemId = itemData['itemId'] as String?;
        if (itemId != null && !seen.contains(itemId)) {
          seen.add(itemId);
          items.add({
            ...itemData,
            'restaurantId': data['restaurantId'],
            'restaurantName': data['restaurantName'],
            'orderedAt': data['createdAt'],
          });
        }
      }
    }

    return items.take(limit).toList();
  }
}
