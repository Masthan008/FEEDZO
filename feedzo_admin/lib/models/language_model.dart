import 'package:cloud_firestore/cloud_firestore.dart';

class LanguageModel {
  final String id;
  final String name;
  final String code; // ISO 639-1 code (e.g., 'en', 'es', 'fr')
  final String? flag;
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  LanguageModel({
    required this.id,
    required this.name,
    required this.code,
    this.flag,
    this.isActive = true,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LanguageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LanguageModel(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      flag: data['flag'],
      isActive: data['isActive'] ?? true,
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'flag': flag,
      'isActive': isActive,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'code': code,
      'flag': flag,
      'isActive': isActive,
      'isDefault': isDefault,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
