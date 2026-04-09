import 'package:cloud_firestore/cloud_firestore.dart';

class EmailTemplateModel {
  final String id;
  final String name;
  final String subject;
  final String body;
  final String eventType; // order_placed, order_delivered, signup, etc.
  final String targetAudience; // customer, restaurant, driver, admin
  final bool isActive;
  final Map<String, dynamic> variables; // e.g., {'{{customer_name}}': 'Customer Name'}
  final DateTime createdAt;
  final DateTime updatedAt;

  EmailTemplateModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.body,
    required this.eventType,
    required this.targetAudience,
    this.isActive = true,
    this.variables = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmailTemplateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmailTemplateModel(
      id: doc.id,
      name: data['name'] ?? '',
      subject: data['subject'] ?? '',
      body: data['body'] ?? '',
      eventType: data['eventType'] ?? '',
      targetAudience: data['targetAudience'] ?? '',
      isActive: data['isActive'] ?? true,
      variables: data['variables'] ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subject': subject,
      'body': body,
      'eventType': eventType,
      'targetAudience': targetAudience,
      'isActive': isActive,
      'variables': variables,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'subject': subject,
      'body': body,
      'eventType': eventType,
      'targetAudience': targetAudience,
      'isActive': isActive,
      'variables': variables,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
