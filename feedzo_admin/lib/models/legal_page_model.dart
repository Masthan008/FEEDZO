import 'package:cloud_firestore/cloud_firestore.dart';

class LegalPageModel {
  final String id;
  final String title;
  final String slug; // URL-friendly identifier
  final String content;
  final String type; // terms, privacy, refund, shipping, cancellation
  final DateTime lastUpdated;
  final DateTime updatedAt;

  LegalPageModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.type,
    required this.lastUpdated,
    required this.updatedAt,
  });

  factory LegalPageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LegalPageModel(
      id: doc.id,
      title: data['title'] ?? '',
      slug: data['slug'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? '',
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'slug': slug,
      'content': content,
      'type': type,
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'slug': slug,
      'content': content,
      'type': type,
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
