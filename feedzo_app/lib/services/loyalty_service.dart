import 'package:cloud_firestore/cloud_firestore.dart';

class LoyaltyService {
  static final _db = FirebaseFirestore.instance;

  /// Credit loyalty points to a customer when order is delivered
  /// Points are calculated as 1 point per ₹10 spent
  static Future<void> creditPointsOnOrderDelivery({
    required String customerId,
    required String orderId,
    required double orderAmount,
  }) async {
    try {
      // Calculate points: 1 point per ₹10 spent
      final pointsEarned = (orderAmount / 10).floor();
      
      if (pointsEarned <= 0) return;

      // Get current loyalty points document
      final pointsDoc = await _db.collection('loyalty_points').doc(customerId).get();
      
      int currentPoints = 0;
      String currentTier = 'Bronze';
      
      if (pointsDoc.exists) {
        final data = pointsDoc.data() as Map<String, dynamic>;
        currentPoints = data['totalPoints'] ?? 0;
        currentTier = data['currentTier'] ?? 'Bronze';
      }

      // Calculate new points and tier
      final newPoints = currentPoints + pointsEarned;
      final newTier = _calculateTier(newPoints);

      // Update loyalty points document
      await _db.collection('loyalty_points').doc(customerId).set({
        'totalPoints': newPoints,
        'currentTier': newTier,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Add point transaction record
      await _db.collection('point_transactions').add({
        'userId': customerId,
        'orderId': orderId,
        'points': pointsEarned,
        'type': 'credit',
        'description': 'Points earned on order delivery',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('[LoyaltyService] Credited $pointsEarned points to $customerId. Total: $newPoints');
    } catch (e) {
      print('[LoyaltyService] Error crediting points: $e');
      rethrow;
    }
  }

  /// Calculate tier based on total points
  static String _calculateTier(int points) {
    if (points >= 5000) return 'Platinum';
    if (points >= 2500) return 'Gold';
    if (points >= 1000) return 'Silver';
    return 'Bronze';
  }

  /// Redeem points for discount
  static Future<bool> redeemPoints({
    required String customerId,
    required int pointsToRedeem,
    required String orderId,
  }) async {
    try {
      final pointsDoc = await _db.collection('loyalty_points').doc(customerId).get();
      
      if (!pointsDoc.exists) {
        throw Exception('No loyalty account found');
      }

      final data = pointsDoc.data() as Map<String, dynamic>;
      final currentPoints = data['totalPoints'] ?? 0;

      if (currentPoints < pointsToRedeem) {
        throw Exception('Insufficient points');
      }

      final newPoints = currentPoints - pointsToRedeem;
      final newTier = _calculateTier(newPoints);

      // Update loyalty points
      await _db.collection('loyalty_points').doc(customerId).update({
        'totalPoints': newPoints,
        'currentTier': newTier,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Add transaction record
      await _db.collection('point_transactions').add({
        'userId': customerId,
        'orderId': orderId,
        'points': pointsToRedeem,
        'type': 'debit',
        'description': 'Points redeemed for discount',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('[LoyaltyService] Redeemed $pointsToRedeem points from $customerId. Remaining: $newPoints');
      return true;
    } catch (e) {
      print('[LoyaltyService] Error redeeming points: $e');
      rethrow;
    }
  }

  /// Get customer loyalty points
  static Future<Map<String, dynamic>?> getCustomerLoyalty(String customerId) async {
    try {
      final doc = await _db.collection('loyalty_points').doc(customerId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      print('[LoyaltyService] Error getting loyalty data: $e');
      return null;
    }
  }

  /// Stream customer loyalty points
  static Stream<Map<String, dynamic>?> watchCustomerLoyalty(String customerId) {
    return _db.collection('loyalty_points').doc(customerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data();
    });
  }

  /// Get point transaction history
  static Stream<List<Map<String, dynamic>>> getPointTransactions(String customerId) {
    return _db
        .collection('point_transactions')
        .where('userId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
}
