import 'package:cloud_firestore/cloud_firestore.dart';

class GroupOrderModel {
  final String id;
  final String groupId;
  final String creatorId;
  final String restaurantId;
  final String restaurantName;
  final List<GroupOrderParticipant> participants;
  final double totalAmount;
  final String status; // 'pending', 'active', 'completed'
  final DateTime scheduledFor;
  final DateTime createdAt;

  GroupOrderModel({
    required this.id,
    required this.groupId,
    required this.creatorId,
    required this.restaurantId,
    required this.restaurantName,
    required this.participants,
    required this.totalAmount,
    required this.status,
    required this.scheduledFor,
    required this.createdAt,
  });

  factory GroupOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupOrderModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      creatorId: data['creatorId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      participants: (data['participants'] as List?)
              ?.map((p) => GroupOrderParticipant.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      scheduledFor: (data['scheduledFor'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'creatorId': creatorId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'participants': participants.map((p) => p.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class GroupOrderParticipant {
  final String userId;
  final String userName;
  final String userEmail;
  final List<Map<String, dynamic>> items;
  final double amount;
  final String status; // 'invited', 'joined', 'declined'

  GroupOrderParticipant({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.items,
    required this.amount,
    this.status = 'invited',
  });

  factory GroupOrderParticipant.fromMap(Map<String, dynamic> data) {
    return GroupOrderParticipant(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      items: (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [],
      amount: (data['amount'] ?? 0).toDouble(),
      status: data['status'] ?? 'invited',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'items': items,
      'amount': amount,
      'status': status,
    };
  }
}
