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

  // ==================== CREATE ====================

  /// Submit a new review
  Future<ReviewModel> submitReview({
    required String orderId,
    required String customerId,
    required String customerName,
    String? customerAvatarUrl,
    required String targetId,
    required ReviewTargetType targetType,
    required double rating,
    String? reviewText,
    List<String> tags = const [],
    List<String> photoUrls = const [],
  }) async {
    final reviewId = _reviewsCollection.doc().id;
    final now = DateTime.now();

    final review = ReviewModel(
      id: reviewId,
      orderId: orderId,
      customerId: customerId,
      customerName: customerName,
      customerAvatarUrl: customerAvatarUrl,
      targetId: targetId,
      targetType: targetType,
      rating: rating,
      reviewText: reviewText,
      tags: tags,
      photoUrls: photoUrls,
      createdAt: now,
    );

    // Use transaction to ensure consistency
    await _firestore.runTransaction((transaction) async {
      // Add the review
      transaction.set(
        _reviewsCollection.doc(reviewId),
        review.toJson(),
      );

      // Update rating summary
      await _updateRatingSummary(
        transaction: transaction,
        targetId: targetId,
        targetType: targetType,
        newRating: rating,
      );

      // Mark order as rated
      transaction.update(
        _firestore.collection('orders').doc(orderId),
        {
          'isRated': true,
          'ratedAt': Timestamp.fromDate(now),
          'ratedTargetId': targetId,
          'ratedTargetType': targetType.name,
        },
      );
    });

    return review;
  }

  /// Submit multiple reviews for an order (restaurant, dishes, driver)
  Future<List<ReviewModel>> submitOrderReviews({
    required String orderId,
    required String customerId,
    required String customerName,
    String? customerAvatarUrl,
    required String restaurantId,
    double? restaurantRating,
    String? restaurantReview,
    List<String> restaurantTags = const [],
    required String? driverId,
    double? driverRating,
    String? driverReview,
    List<String> driverTags = const [],
    List<DishReviewData> dishReviews = const [],
  }) async {
    final List<ReviewModel> submittedReviews = [];

    await _firestore.runTransaction((transaction) async {
      // Submit restaurant review
      if (restaurantRating != null && restaurantRating > 0) {
        final reviewId = _reviewsCollection.doc().id;
        final review = ReviewModel(
          id: reviewId,
          orderId: orderId,
          customerId: customerId,
          customerName: customerName,
          customerAvatarUrl: customerAvatarUrl,
          targetId: restaurantId,
          targetType: ReviewTargetType.restaurant,
          rating: restaurantRating,
          reviewText: restaurantReview,
          tags: restaurantTags,
          createdAt: DateTime.now(),
        );

        transaction.set(_reviewsCollection.doc(reviewId), review.toJson());
        await _updateRatingSummary(
          transaction: transaction,
          targetId: restaurantId,
          targetType: ReviewTargetType.restaurant,
          newRating: restaurantRating,
        );
        submittedReviews.add(review);
      }

      // Submit driver review
      if (driverId != null &&
          driverRating != null &&
          driverRating > 0) {
        final reviewId = _reviewsCollection.doc().id;
        final review = ReviewModel(
          id: reviewId,
          orderId: orderId,
          customerId: customerId,
          customerName: customerName,
          customerAvatarUrl: customerAvatarUrl,
          targetId: driverId,
          targetType: ReviewTargetType.driver,
          rating: driverRating,
          reviewText: driverReview,
          tags: driverTags,
          createdAt: DateTime.now(),
        );

        transaction.set(_reviewsCollection.doc(reviewId), review.toJson());
        await _updateRatingSummary(
          transaction: transaction,
          targetId: driverId,
          targetType: ReviewTargetType.driver,
          newRating: driverRating,
        );
        submittedReviews.add(review);
      }

      // Submit dish reviews
      for (final dishReview in dishReviews) {
        if (dishReview.rating > 0) {
          final reviewId = _reviewsCollection.doc().id;
          final review = ReviewModel(
            id: reviewId,
            orderId: orderId,
            customerId: customerId,
            customerName: customerName,
            customerAvatarUrl: customerAvatarUrl,
            targetId: dishReview.dishId,
            targetType: ReviewTargetType.dish,
            rating: dishReview.rating,
            reviewText: dishReview.review,
            tags: dishReview.tags,
            createdAt: DateTime.now(),
          );

          transaction.set(_reviewsCollection.doc(reviewId), review.toJson());
          await _updateRatingSummary(
            transaction: transaction,
            targetId: dishReview.dishId,
            targetType: ReviewTargetType.dish,
            newRating: dishReview.rating,
          );
          submittedReviews.add(review);
        }
      }

      // Mark order as rated
      transaction.update(
        _firestore.collection('orders').doc(orderId),
        {
          'isRated': true,
          'ratedAt': Timestamp.fromDate(DateTime.now()),
        },
      );
    });

    return submittedReviews;
  }

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

  /// Get reviews by a customer
  Stream<List<ReviewModel>> getReviewsByCustomer(String customerId) {
    return _reviewsCollection
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              ReviewModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Get reviews for an order
  Future<List<ReviewModel>> getReviewsForOrder(String orderId) async {
    final snapshot = await _reviewsCollection
        .where('orderId', isEqualTo: orderId)
        .get();

    return snapshot.docs
        .map((doc) =>
            ReviewModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Check if customer has reviewed an order
  Future<bool> hasReviewedOrder(String orderId, String customerId) async {
    final snapshot = await _reviewsCollection
        .where('orderId', isEqualTo: orderId)
        .where('customerId', isEqualTo: customerId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get rating summary for a target
  Stream<RatingSummary?> getRatingSummary({
    required String targetId,
    required ReviewTargetType targetType,
  }) {
    return _ratingSummariesCollection
        .where('targetId', isEqualTo: targetId)
        .where('targetType', isEqualTo: targetType.name)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return RatingSummary.fromJson(
          snapshot.docs.first.data() as Map<String, dynamic>);
    });
  }

  // ==================== UPDATE ====================

  /// Edit a review
  Future<void> editReview({
    required String reviewId,
    double? newRating,
    String? newReviewText,
    List<String>? newTags,
    List<String>? newPhotoUrls,
  }) async {
    final reviewDoc = await _reviewsCollection.doc(reviewId).get();
    if (!reviewDoc.exists) throw Exception('Review not found');

    final oldReview =
        ReviewModel.fromJson(reviewDoc.data() as Map<String, dynamic>);

    await _firestore.runTransaction((transaction) async {
      // Update review
      final updates = <String, dynamic>{
        'isEdited': true,
        'editedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (newRating != null) {
        updates['rating'] = newRating;
      }
      if (newReviewText != null) {
        updates['reviewText'] = newReviewText;
      }
      if (newTags != null) {
        updates['tags'] = newTags;
      }
      if (newPhotoUrls != null) {
        updates['photoUrls'] = newPhotoUrls;
      }

      transaction.update(_reviewsCollection.doc(reviewId), updates);

      // Update rating summary if rating changed
      if (newRating != null && newRating != oldReview.rating) {
        await _updateRatingSummary(
          transaction: transaction,
          targetId: oldReview.targetId,
          targetType: oldReview.targetType,
          newRating: newRating,
          oldRating: oldReview.rating,
        );
      }
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

  /// Mark review as helpful
  Future<void> markHelpful({
    required String reviewId,
    required String userId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final reviewDoc = await transaction.get(_reviewsCollection.doc(reviewId));
      if (!reviewDoc.exists) return;

      final review =
          ReviewModel.fromJson(reviewDoc.data() as Map<String, dynamic>);

      if (review.helpfulByUserIds.contains(userId)) {
        // Remove helpful mark
        transaction.update(_reviewsCollection.doc(reviewId), {
          'helpfulCount': review.helpfulCount - 1,
          'helpfulByUserIds':
              FieldValue.arrayRemove([userId]),
        });
      } else {
        // Add helpful mark
        transaction.update(_reviewsCollection.doc(reviewId), {
          'helpfulCount': review.helpfulCount + 1,
          'helpfulByUserIds':
              FieldValue.arrayUnion([userId]),
        });
      }
    });
  }

  // ==================== DELETE ====================

  /// Delete a review (admin only)
  Future<void> deleteReview(String reviewId) async {
    final reviewDoc = await _reviewsCollection.doc(reviewId).get();
    if (!reviewDoc.exists) return;

    final review =
        ReviewModel.fromJson(reviewDoc.data() as Map<String, dynamic>);

    await _firestore.runTransaction((transaction) async {
      // Delete review
      transaction.delete(_reviewsCollection.doc(reviewId));

      // Update rating summary
      final summaryQuery = await _ratingSummariesCollection
          .where('targetId', isEqualTo: review.targetId)
          .where('targetType', isEqualTo: review.targetType.name)
          .limit(1)
          .get();

      if (summaryQuery.docs.isNotEmpty) {
        final summaryDoc = summaryQuery.docs.first;
        final summary = RatingSummary.fromJson(
            summaryDoc.data() as Map<String, dynamic>);

        final newTotal = summary.totalReviews - 1;
        double newAverage;

        if (newTotal > 0) {
          newAverage = ((summary.averageRating * summary.totalReviews) -
                  review.rating) /
              newTotal;
        } else {
          newAverage = 0;
        }

        transaction.update(
          _ratingSummariesCollection.doc(summaryDoc.id),
          {
            'averageRating': newAverage,
            'totalReviews': newTotal,
            '${_getStarField(review.rating)}':
                FieldValue.increment(-1),
            'lastUpdated': Timestamp.fromDate(DateTime.now()),
          },
        );
      }
    });
  }

  // ==================== HELPER METHODS ====================

  Future<void> _updateRatingSummary({
    required Transaction transaction,
    required String targetId,
    required ReviewTargetType targetType,
    required double newRating,
    double? oldRating,
  }) async {
    final summaryQuery = await _ratingSummariesCollection
        .where('targetId', isEqualTo: targetId)
        .where('targetType', isEqualTo: targetType.name)
        .limit(1)
        .get();

    final now = DateTime.now();

    if (summaryQuery.docs.isEmpty) {
      // Create new summary
      final summaryId = _ratingSummariesCollection.doc().id;
      final summary = RatingSummary(
        targetId: targetId,
        targetType: targetType,
        averageRating: newRating,
        totalReviews: 1,
        fiveStarCount: newRating >= 5 ? 1 : 0,
        fourStarCount: newRating >= 4 && newRating < 5 ? 1 : 0,
        threeStarCount: newRating >= 3 && newRating < 4 ? 1 : 0,
        twoStarCount: newRating >= 2 && newRating < 3 ? 1 : 0,
        oneStarCount: newRating >= 1 && newRating < 2 ? 1 : 0,
        lastUpdated: now,
      );

      transaction.set(
        _ratingSummariesCollection.doc(summaryId),
        summary.toJson(),
      );
    } else {
      // Update existing summary
      final summaryDoc = summaryQuery.docs.first;
      final summary = RatingSummary.fromJson(
          summaryDoc.data() as Map<String, dynamic>);

      int newTotal;
      double newAverage;

      if (oldRating != null) {
        // Editing existing review
        newTotal = summary.totalReviews;
        newAverage = ((summary.averageRating * summary.totalReviews) -
                oldRating +
                newRating) /
            newTotal;
      } else {
        // New review
        newTotal = summary.totalReviews + 1;
        newAverage = ((summary.averageRating * summary.totalReviews) +
                newRating) /
            newTotal;
      }

      final updates = <String, dynamic>{
        'averageRating': newAverage,
        'totalReviews': newTotal,
        'lastUpdated': Timestamp.fromDate(now),
      };

      if (oldRating != null) {
        updates[_getStarField(oldRating)] = FieldValue.increment(-1);
      }
      updates[_getStarField(newRating)] = FieldValue.increment(1);

      transaction.update(
        _ratingSummariesCollection.doc(summaryDoc.id),
        updates,
      );
    }
  }

  String _getStarField(double rating) {
    if (rating >= 5) return 'fiveStarCount';
    if (rating >= 4) return 'fourStarCount';
    if (rating >= 3) return 'threeStarCount';
    if (rating >= 2) return 'twoStarCount';
    return 'oneStarCount';
  }
}

/// Data class for dish reviews
class DishReviewData {
  final String dishId;
  final String dishName;
  final double rating;
  final String? review;
  final List<String> tags;

  DishReviewData({
    required this.dishId,
    required this.dishName,
    required this.rating,
    this.review,
    this.tags = const [],
  });
}
