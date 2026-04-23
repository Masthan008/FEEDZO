import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderType; // admin, restaurant, driver, customer
  final String recipientId;
  final String recipientName;
  final String recipientType;
  final String message;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.recipientId,
    required this.recipientName,
    required this.recipientType,
    required this.message,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderType: data['senderType'] ?? '',
      recipientId: data['recipientId'] ?? '',
      recipientName: data['recipientName'] ?? '',
      recipientType: data['recipientType'] ?? '',
      message: data['message'] ?? '',
      imageUrl: data['imageUrl'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'recipientType': recipientType,
      'message': message,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
