import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String verificationType; // phone, email, identity
  final String? documentUrl;
  final String status; // pending, approved, rejected
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  VerificationModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.verificationType,
    this.documentUrl,
    this.status = 'pending',
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory VerificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VerificationModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      verificationType: data['verificationType'] ?? '',
      documentUrl: data['documentUrl'],
      status: data['status'] ?? 'pending',
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'verificationType': verificationType,
      'documentUrl': documentUrl,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
