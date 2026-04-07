import 'package:cloud_firestore/cloud_firestore.dart';

/// Review model for restaurants, dishes, and drivers
class ReviewModel {
  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final String? customerAvatarUrl;

  // Target of the review
  final String targetId;
  final ReviewTargetType targetType;

  // Rating (1-5)
  final double rating;

  // Review content
  final String? reviewText;
  final List<String> tags;

  // Media attachments
  final List<String> photoUrls;

  // Metadata
  final DateTime createdAt;
  final bool isEdited;
  final DateTime? editedAt;

  // Admin moderation
  final bool isVisible;
  final String? moderationReason;

  // Restaurant response
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
}

enum ReviewTargetType {
  restaurant,
  dish,
  driver,
}
