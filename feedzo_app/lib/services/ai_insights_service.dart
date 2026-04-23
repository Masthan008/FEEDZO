import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AIInsightsService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Get personalized AI insights for the current customer
  static Future<Map<String, dynamic>> getCustomerInsights() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};

    try {
      // Get customer's order history
      final ordersSnapshot = await _db
          .collection('orders')
          .where('customerId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final orders = ordersSnapshot.docs;
      
      // Calculate insights
      final totalOrders = orders.length;
      final totalSpent = orders.fold<double>(
        0,
        (sum, doc) => sum + (doc.data()['totalAmount'] as num? ?? 0).toDouble(),
      );
      
      // Get favorite cuisines
      final cuisines = <String, int>{};
      for (final doc in orders) {
        final restaurantId = doc.data()['restaurantId'] as String?;
        if (restaurantId != null) {
          final restaurantDoc = await _db.collection('restaurants').doc(restaurantId).get();
          if (restaurantDoc.exists) {
            final cuisine = restaurantDoc.data()?['cuisine'] as String? ?? 'Other';
            cuisines[cuisine] = (cuisines[cuisine] ?? 0) + 1;
          }
        }
      }
      
      final favoriteCuisine = cuisines.isNotEmpty
          ? cuisines.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'Indian';

      // Get average order value
      final avgOrderValue = totalOrders > 0 ? totalSpent / totalOrders : 0;

      // Get loyalty points
      final loyaltyDoc = await _db.collection('loyalty_points').doc(userId).get();
      final loyaltyPoints = loyaltyDoc.exists
          ? (loyaltyDoc.data()?['totalPoints'] as num? ?? 0).toInt()
          : 0;

      // Get loyalty tier
      final loyaltyTier = loyaltyDoc.exists
          ? (loyaltyDoc.data()?['currentTier'] as String? ?? 'Bronze')
          : 'Bronze';

      return {
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
        'avgOrderValue': avgOrderValue,
        'favoriteCuisine': favoriteCuisine,
        'loyaltyPoints': loyaltyPoints,
        'loyaltyTier': loyaltyTier,
        'cuisineBreakdown': cuisines,
      };
    } catch (e) {
      print('[AIInsightsService] Error getting insights: $e');
      return {};
    }
  }

  /// Get personalized food recommendations based on order history
  static Future<List<Map<String, dynamic>>> getFoodRecommendations() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      // Get customer's recent orders
      final ordersSnapshot = await _db
          .collection('orders')
          .where('customerId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      // Extract ordered items
      final orderedItems = <String, int>{};
      for (final doc in ordersSnapshot.docs) {
        final items = doc.data()['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final itemName = item['name'] as String? ?? 'Unknown';
          orderedItems[itemName] = (orderedItems[itemName] ?? 0) + 1;
        }
      }

      // Get popular items from restaurants
      final popularItems = await _db
          .collectionGroup('menuItems')
          .where('orderCount', isGreaterThan: 10)
          .orderBy('orderCount', descending: true)
          .limit(10)
          .get();

      // Filter recommendations based on preferences
      final recommendations = <Map<String, dynamic>>[];
      for (final doc in popularItems.docs) {
        final item = doc.data();
        final itemName = item['name'] as String? ?? '';
        
        // If user has ordered this before, it's a repeat favorite
        if (orderedItems.containsKey(itemName)) {
          recommendations.add({
            'name': itemName,
            'reason': 'You love this! Ordered ${orderedItems[itemName]} times',
            'icon': Icons.star_rounded,
            'color': 0xFF16A34A,
          });
        } else {
          recommendations.add({
            'name': itemName,
            'reason': 'Popular choice - ${item['orderCount']} orders',
            'icon': Icons.trending_up_rounded,
            'color': 0xFF3B82F6,
          });
        }
      }

      return recommendations.take(5).toList();
    } catch (e) {
      print('[AIInsightsService] Error getting recommendations: $e');
      return [];
    }
  }

  /// Get spending insights
  static Future<Map<String, dynamic>> getSpendingInsights() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};

    try {
      // Get orders from last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentOrders = await _db
          .collection('orders')
          .where('customerId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final recentSpent = recentOrders.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc.data()['totalAmount'] as num? ?? 0).toDouble(),
      );

      // Get orders from previous 30 days
      final sixtyDaysAgo = DateTime.now().subtract(const Duration(days: 60));
      final previousOrders = await _db
          .collection('orders')
          .where('customerId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(sixtyDaysAgo))
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final previousSpent = previousOrders.docs.fold<double>(
        0,
        (sum, doc) => sum + (doc.data()['totalAmount'] as num? ?? 0).toDouble(),
      );

      // Calculate change
      final spendingChange = previousSpent > 0
          ? ((recentSpent - previousSpent) / previousSpent * 100)
          : 0.0;

      return {
        'recentSpent': recentSpent,
        'previousSpent': previousSpent,
        'spendingChange': spendingChange,
        'recentOrderCount': recentOrders.docs.length,
        'previousOrderCount': previousOrders.docs.length,
      };
    } catch (e) {
      print('[AIInsightsService] Error getting spending insights: $e');
      return {};
    }
  }

  /// Stream customer insights for real-time updates
  static Stream<Map<String, dynamic>> watchCustomerInsights() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value({});

    return _db
        .collection('orders')
        .where('customerId', isEqualTo: userId)
        .snapshots()
        .asyncMap((_) async => await getCustomerInsights());
  }
}
