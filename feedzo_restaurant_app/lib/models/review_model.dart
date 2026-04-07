import 'package:cloud_firestore/cloud_firestore.dart';

/// Review model for restaurants, dishes, and drivers
class ReviewModel {
  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final String? customerAvatarUrl;

  // Target of the review
  final String targetId; // restaurantId, dishId, or driverId
  final ReviewTargetType targetType;

  // Rating (1-5)
  final double rating;

  // Review content
  final String? reviewText;
  final List<String> tags; // e.g., ['Tasty', 'Fast Delivery', 'Cold Food']

  // Media attachments
  final List<String> photoUrls;

  // Metadata
  final DateTime createdAt;
  final bool isEdited;
  final DateTime? editedAt;

  // Admin moderation
  final bool isVisible;
  final String? moderationReason;

  // Restaurant response (for restaurant reviews)
  final String? restaurantResponse;
  final DateTime? restaurantResponseAt;

  // Helpful count
  final int helpfulCount;
  final List<String> helpfulByUserIds;

  ReviewModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    this.customerAvatarUrl,
    required this.targetId,
    required this.targetType,
    required this.rating,
    this.reviewText,
    this.tags = const [],
    this.photoUrls = const [],
    required this.createdAt,
    this.isEdited = false,
    this.editedAt,
    this.isVisible = true,
    this.moderationReason,
    this.restaurantResponse,
    this.restaurantResponseAt,
    this.helpfulCount = 0,
    this.helpfulByUserIds = const [],
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      customerAvatarUrl: json['customerAvatarUrl'] as String?,
      targetId: json['targetId'] as String,
      targetType: ReviewTargetType.values.firstWhere(
        (e) => e.name == json['targetType'],
        orElse: () => ReviewTargetType.restaurant,
      ),
      rating: (json['rating'] as num).toDouble(),
      reviewText: json['reviewText'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null
          ? (json['editedAt'] as Timestamp).toDate()
          : null,
      isVisible: json['isVisible'] ?? true,
      moderationReason: json['moderationReason'] as String?,
      restaurantResponse: json['restaurantResponse'] as String?,
      restaurantResponseAt: json['restaurantResponseAt'] != null
          ? (json['restaurantResponseAt'] as Timestamp).toDate()
          : null,
      helpfulCount: json['helpfulCount'] ?? 0,
      helpfulByUserIds: List<String>.from(json['helpfulByUserIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'customerAvatarUrl': customerAvatarUrl,
      'targetId': targetId,
      'targetType': targetType.name,
      'rating': rating,
      'reviewText': reviewText,
      'tags': tags,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isVisible': isVisible,
      'moderationReason': moderationReason,
      'restaurantResponse': restaurantResponse,
      'restaurantResponseAt': restaurantResponseAt != null
          ? Timestamp.fromDate(restaurantResponseAt!)
          : null,
      'helpfulCount': helpfulCount,
      'helpfulByUserIds': helpfulByUserIds,
    };
  }

  ReviewModel copyWith({
    String? id,
    String? orderId,
    String? customerId,
    String? customerName,
    String? customerAvatarUrl,
    String? targetId,
    ReviewTargetType? targetType,
    double? rating,
    String? reviewText,
    List<String>? tags,
    List<String>? photoUrls,
    DateTime? createdAt,
    bool? isEdited,
    DateTime? editedAt,
    bool? isVisible,
    String? moderationReason,
    String? restaurantResponse,
    DateTime? restaurantResponseAt,
    int? helpfulCount,
    List<String>? helpfulByUserIds,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerAvatarUrl: customerAvatarUrl ?? this.customerAvatarUrl,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      tags: tags ?? this.tags,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isVisible: isVisible ?? this.isVisible,
      moderationReason: moderationReason ?? this.moderationReason,
      restaurantResponse: restaurantResponse ?? this.restaurantResponse,
      restaurantResponseAt: restaurantResponseAt ?? this.restaurantResponseAt,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      helpfulByUserIds: helpfulByUserIds ?? this.helpfulByUserIds,
    );
  }
}

enum ReviewTargetType {
  restaurant,
  dish,
  driver,
}

/// Predefined review tags for quick selection
class ReviewTags {
  static const List<String> positive = [
    'Tasty Food',
    'Great Packaging',
    'Fast Delivery',
    'Hot & Fresh',
    'Good Portion',
    'Value for Money',
    'Polite Driver',
    'Cleanliness',
  ];

  static const List<String> negative = [
    'Cold Food',
    'Late Delivery',
    'Wrong Order',
    'Poor Packaging',
    'Small Portion',
    'Overpriced',
    'Rude Behavior',
    'Missing Items',
  ];

  static const List<String> all = [...positive, ...negative];
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

/// Data class for order items to rate
class OrderItemRating {
  final String dishId;
  final String dishName;
  final int quantity;

  OrderItemRating({
    required this.dishId,
    required this.dishName,
    required this.quantity,
  });
}
