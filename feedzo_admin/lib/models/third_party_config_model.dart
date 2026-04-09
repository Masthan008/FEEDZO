import 'package:cloud_firestore/cloud_firestore.dart';

class ThirdPartyConfigModel {
  final String id;
  final String serviceName; // stripe, paypal, razorpay, google_maps, onesignal, etc.
  final Map<String, dynamic> config; // API keys, secrets, etc.
  final bool isActive;
  final DateTime updatedAt;

  ThirdPartyConfigModel({
    required this.id,
    required this.serviceName,
    required this.config,
    this.isActive = true,
    required this.updatedAt,
  });

  factory ThirdPartyConfigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ThirdPartyConfigModel(
      id: doc.id,
      serviceName: data['serviceName'] ?? '',
      config: data['config'] ?? {},
      isActive: data['isActive'] ?? true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceName': serviceName,
      'config': config,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'serviceName': serviceName,
      'config': config,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
