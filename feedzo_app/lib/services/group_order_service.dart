import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_order_model.dart';
import '../services/deep_link_service.dart';

class GroupOrderService {
  static final _db = FirebaseFirestore.instance;

  static Future<String> createGroupOrder({
    required String creatorId,
    required String restaurantId,
    required String restaurantName,
    required DateTime scheduledFor,
  }) async {
    final groupId = DateTime.now().millisecondsSinceEpoch.toString();
    
    await _db.collection('groupOrders').add({
      'groupId': groupId,
      'creatorId': creatorId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'participants': [],
      'totalAmount': 0,
      'status': 'pending',
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return groupId;
  }

  static Future<void> inviteParticipant({
    required String groupOrderId,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    final doc = await _db.collection('groupOrders').doc(groupOrderId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final participants = (data['participants'] as List).cast<Map<String, dynamic>>();

    participants.add({
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'items': [],
      'amount': 0,
      'status': 'invited',
    });

    await doc.reference.update({
      'participants': participants,
    });

    // Send invitation notification
    final deepLink = await DeepLinkService.createOrderDeepLink(groupOrderId);
    // Send notification with deep link
  }

  static Future<void> joinGroupOrder({
    required String groupOrderId,
    required String userId,
    required List<Map<String, dynamic>> items,
    required double amount,
  }) async {
    final doc = await _db.collection('groupOrders').doc(groupOrderId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final participants = (data['participants'] as List).cast<Map<String, dynamic>>();

    final updatedParticipants = participants.map((p) {
      if (p['userId'] == userId) {
        p['status'] = 'joined';
        p['items'] = items;
        p['amount'] = amount;
      }
      return p;
    }).toList();

    final totalAmount = updatedParticipants.fold<double>(
      0,
      (sum, p) => sum + (p['amount'] as num).toDouble(),
    );

    await doc.reference.update({
      'participants': updatedParticipants,
      'totalAmount': totalAmount,
      'status': 'active',
    });
  }

  static Future<void> declineGroupOrder({
    required String groupOrderId,
    required String userId,
  }) async {
    final doc = await _db.collection('groupOrders').doc(groupOrderId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final participants = (data['participants'] as List).cast<Map<String, dynamic>>();

    final updatedParticipants = participants.map((p) {
      if (p['userId'] == userId) {
        p['status'] = 'declined';
      }
      return p;
    }).toList();

    await doc.reference.update({
      'participants': updatedParticipants,
    });
  }

  static Stream<GroupOrderModel?> watchGroupOrder(String groupOrderId) {
    return _db
        .collection('groupOrders')
        .doc(groupOrderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return GroupOrderModel.fromFirestore(doc);
    });
  }

  static Stream<List<GroupOrderModel>> watchUserGroupOrders(String userId) {
    return _db
        .collection('groupOrders')
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => GroupOrderModel.fromFirestore(doc))
            .toList());
  }
}
