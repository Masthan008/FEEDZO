import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class ChatService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _chats = _db.collection('adminChats');

  static Stream<List<ChatMessageModel>> watchAllChats() {
    return _chats.orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => ChatMessageModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<ChatMessageModel>> watchChatsWithUser(String userId) {
    return _chats
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => ChatMessageModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<ChatMessageModel>> watchChatBetweenUsers(String userId1, String userId2) {
    return _chats
        .where(Filter.or(
          Filter.and(Filter('senderId', isEqualTo: userId1), Filter('recipientId', isEqualTo: userId2)),
          Filter.and(Filter('senderId', isEqualTo: userId2), Filter('recipientId', isEqualTo: userId1)),
        ))
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => ChatMessageModel.fromFirestore(doc)).toList();
    });
  }

  static Future<String> sendMessage({
    required String senderId,
    required String senderName,
    required String senderType,
    required String recipientId,
    required String recipientName,
    required String recipientType,
    required String message,
  }) async {
    final chatMessage = ChatMessageModel(
      id: '',
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      recipientId: recipientId,
      recipientName: recipientName,
      recipientType: recipientType,
      message: message,
      createdAt: DateTime.now(),
      isRead: false,
    );
    final docRef = await _chats.add(chatMessage.toMap());
    return docRef.id;
  }

  static Future<void> markAsRead(String messageId) async {
    await _chats.doc(messageId).update({
      'isRead': true,
    });
  }

  static Future<void> deleteMessage(String messageId) async {
    await _chats.doc(messageId).delete();
  }
}
