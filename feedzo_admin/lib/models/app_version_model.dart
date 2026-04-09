import 'package:cloud_firestore/cloud_firestore.dart';

class AppVersionModel {
  final String id;
  final String platform; // android, ios
  final String version;
  final int buildNumber;
  final bool isForceUpdate;
  final String? updateMessage;
  final String? downloadUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppVersionModel({
    required this.id,
    required this.platform,
    required this.version,
    required this.buildNumber,
    this.isForceUpdate = false,
    this.updateMessage,
    this.downloadUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppVersionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppVersionModel(
      id: doc.id,
      platform: data['platform'] ?? '',
      version: data['version'] ?? '',
      buildNumber: data['buildNumber'] ?? 0,
      isForceUpdate: data['isForceUpdate'] ?? false,
      updateMessage: data['updateMessage'],
      downloadUrl: data['downloadUrl'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'version': version,
      'buildNumber': buildNumber,
      'isForceUpdate': isForceUpdate,
      'updateMessage': updateMessage,
      'downloadUrl': downloadUrl,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'platform': platform,
      'version': version,
      'buildNumber': buildNumber,
      'isForceUpdate': isForceUpdate,
      'updateMessage': updateMessage,
      'downloadUrl': downloadUrl,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
