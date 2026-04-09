import 'package:cloud_firestore/cloud_firestore.dart';

class NewsletterSubscriberModel {
  final String id;
  final String email;
  final String? name;
  final bool isActive;
  final DateTime subscribedAt;
  final DateTime? unsubscribedAt;

  NewsletterSubscriberModel({
    required this.id,
    required this.email,
    this.name,
    this.isActive = true,
    required this.subscribedAt,
    this.unsubscribedAt,
  });

  factory NewsletterSubscriberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewsletterSubscriberModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'],
      isActive: data['isActive'] ?? true,
      subscribedAt: (data['subscribedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unsubscribedAt: (data['unsubscribedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'isActive': isActive,
      'subscribedAt': FieldValue.serverTimestamp(),
      'unscribedAt': unsubscribedAt,
    };
  }
}
