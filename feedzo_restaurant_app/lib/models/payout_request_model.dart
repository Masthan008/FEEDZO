import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutRequestModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final double amount;
  final String status; // pending, approved, rejected, completed
  final String? bankAccount;
  final String? ifscCode;
  final String? accountHolderName;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? completedAt;
  final String? approvedBy;
  final String? rejectionReason;
  final String? transactionId;

  PayoutRequestModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.amount,
    required this.status,
    this.bankAccount,
    this.ifscCode,
    this.accountHolderName,
    required this.requestedAt,
    this.approvedAt,
    this.completedAt,
    this.approvedBy,
    this.rejectionReason,
    this.transactionId,
  });

  factory PayoutRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PayoutRequestModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      bankAccount: data['bankAccount'],
      ifscCode: data['ifscCode'],
      accountHolderName: data['accountHolderName'],
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      approvedBy: data['approvedBy'],
      rejectionReason: data['rejectionReason'],
      transactionId: data['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'amount': amount,
      'status': status,
      'bankAccount': bankAccount,
      'ifscCode': ifscCode,
      'accountHolderName': accountHolderName,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
      'transactionId': transactionId,
    };
  }
}
