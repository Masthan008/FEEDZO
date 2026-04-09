import 'package:cloud_firestore/cloud_firestore.dart';

class LandingPageModel {
  final String id;
  final String title;
  final String subtitle;
  final String? heroImageUrl;
  final String? description;
  final List<String> featureImages;
  final List<String> appStoreUrls;
  final String? ctaText;
  final String? ctaLink;
  final bool isActive;
  final DateTime updatedAt;

  LandingPageModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.heroImageUrl,
    this.description,
    this.featureImages = const [],
    this.appStoreUrls = const [],
    this.ctaText,
    this.ctaLink,
    this.isActive = true,
    required this.updatedAt,
  });

  factory LandingPageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LandingPageModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      heroImageUrl: data['heroImageUrl'],
      description: data['description'],
      featureImages: List<String>.from(data['featureImages'] ?? []),
      appStoreUrls: List<String>.from(data['appStoreUrls'] ?? []),
      ctaText: data['ctaText'],
      ctaLink: data['ctaLink'],
      isActive: data['isActive'] ?? true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'heroImageUrl': heroImageUrl,
      'description': description,
      'featureImages': featureImages,
      'appStoreUrls': appStoreUrls,
      'ctaText': ctaText,
      'ctaLink': ctaLink,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'heroImageUrl': heroImageUrl,
      'description': description,
      'featureImages': featureImages,
      'appStoreUrls': appStoreUrls,
      'ctaText': ctaText,
      'ctaLink': ctaLink,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
