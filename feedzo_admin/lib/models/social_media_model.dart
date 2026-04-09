import 'package:cloud_firestore/cloud_firestore.dart';

class SocialMediaModel {
  final String id;
  final String platform;
  final String url;
  final String? icon;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  SocialMediaModel({
    required this.id,
    required this.platform,
    required this.url,
    this.icon,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SocialMediaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialMediaModel(
      id: doc.id,
      platform: data['platform'] ?? '',
      url: data['url'] ?? '',
      icon: data['icon'],
      isActive: data['isActive'] ?? true,
      sortOrder: data['sortOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'url': url,
      'icon': icon,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'platform': platform,
      'url': url,
      'icon': icon,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
