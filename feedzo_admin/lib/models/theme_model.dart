import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeModel {
  final String id;
  final String name;
  final String description;
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String textColor;
  final bool isDark;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ThemeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.textColor,
    this.isDark = false,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ThemeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ThemeModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      primaryColor: data['primaryColor'] ?? '#FF6B35',
      secondaryColor: data['secondaryColor'] ?? '#FF9F1C',
      backgroundColor: data['backgroundColor'] ?? '#FFFFFF',
      textColor: data['textColor'] ?? '#333333',
      isDark: data['isDark'] ?? false,
      isActive: data['isActive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'isDark': isDark,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'description': description,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'isDark': isDark,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
