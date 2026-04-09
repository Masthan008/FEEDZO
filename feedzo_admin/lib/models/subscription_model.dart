import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int durationDays;
  final int orderLimit;
  final int maxRestaurants;
  final bool isActive;
  final int? freeTrialDays;
  final List<String> features;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.durationDays,
    required this.orderLimit,
    this.maxRestaurants = 1,
    this.isActive = true,
    this.freeTrialDays,
    this.features = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      price: (data['price'] ?? 0).toDouble(),
      durationDays: data['durationDays'] ?? 30,
      orderLimit: data['orderLimit'] ?? 100,
      maxRestaurants: data['maxRestaurants'] ?? 1,
      isActive: data['isActive'] ?? true,
      freeTrialDays: data['freeTrialDays'],
      features: List<String>.from(data['features'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'durationDays': durationDays,
      'orderLimit': orderLimit,
      'maxRestaurants': maxRestaurants,
      'isActive': isActive,
      'freeTrialDays': freeTrialDays,
      'features': features,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'durationDays': durationDays,
      'orderLimit': orderLimit,
      'maxRestaurants': maxRestaurants,
      'isActive': isActive,
      'freeTrialDays': freeTrialDays,
      'features': features,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class RestaurantSubscription {
  final String id;
  final String restaurantId;
  final String subscriptionId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int? freeTrialUsedDays;
  final DateTime createdAt;

  RestaurantSubscription({
    required this.id,
    required this.restaurantId,
    required this.subscriptionId,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.freeTrialUsedDays,
    required this.createdAt,
  });

  factory RestaurantSubscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RestaurantSubscription(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      subscriptionId: data['subscriptionId'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      freeTrialUsedDays: data['freeTrialUsedDays'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'subscriptionId': subscriptionId,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
      'freeTrialUsedDays': freeTrialUsedDays,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
