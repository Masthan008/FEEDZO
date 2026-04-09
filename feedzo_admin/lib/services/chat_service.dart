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

  static Future<String> sendMessage(ChatMessageModel message) async {
    final docRef = await _chats.add(message.toMap());
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
