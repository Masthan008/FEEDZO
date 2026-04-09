import 'package:cloud_firestore/cloud_firestore.dart';

class AboutUsModel {
  final String id;
  final String title;
  final String mission;
  final String vision;
  final String description;
  final String? imageUrl;
  final String? email;
  final String? phone;
  final String? address;
  final DateTime updatedAt;

  AboutUsModel({
    required this.id,
    required this.title,
    required this.mission,
    required this.vision,
    required this.description,
    this.imageUrl,
    this.email,
    this.phone,
    this.address,
    required this.updatedAt,
  });

  factory AboutUsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AboutUsModel(
      id: doc.id,
      title: data['title'] ?? '',
      mission: data['mission'] ?? '',
      vision: data['vision'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      email: data['email'],
      phone: data['phone'],
      address: data['address'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'mission': mission,
      'vision': vision,
      'description': description,
      'imageUrl': imageUrl,
      'email': email,
      'phone': phone,
      'address': address,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'mission': mission,
      'vision': vision,
      'description': description,
      'imageUrl': imageUrl,
      'email': email,
      'phone': phone,
      'address': address,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
