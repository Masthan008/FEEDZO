import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

/// Service for managing reviews and ratings
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _reviewsCollection =>
      _firestore.collection('reviews');

  CollectionReference get _ratingSummariesCollection =>
      _firestore.collection('ratingSummaries');

  // ==================== READ ====================

  /// Get reviews for a specific target
  Stream<List<ReviewModel>> getReviewsForTarget({
    required String targetId,
    required ReviewTargetType targetType,
    bool onlyVisible = true,
  }) {
    Query query = _reviewsCollection
        .where('targetId', isEqualTo: targetId)
        .where('targetType', isEqualTo: targetType.name)
        .orderBy('createdAt', descending: true);

    if (onlyVisible) {
      query = query.where('isVisible', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ReviewModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Add restaurant response to review
  Future<void> addRestaurantResponse({
    required String reviewId,
    required String response,
  }) async {
    await _reviewsCollection.doc(reviewId).update({
      'restaurantResponse': response,
      'restaurantResponseAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete a review (admin only)
  Future<void> deleteReview(String reviewId) async {
    await _reviewsCollection.doc(reviewId).delete();
  }
}
