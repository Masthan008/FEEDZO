import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/newsletter_model.dart';

class NewsletterService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _subscribers = _db.collection('newsletterSubscribers');

  static Stream<List<NewsletterSubscriberModel>> watchAllSubscribers() {
    return _subscribers.orderBy('subscribedAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => NewsletterSubscriberModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<NewsletterSubscriberModel>> watchActiveSubscribers() {
    return _subscribers
        .where('isActive', isEqualTo: true)
        .orderBy('subscribedAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => NewsletterSubscriberModel.fromFirestore(doc)).toList();
    });
  }

  static Future<String> addSubscriber(NewsletterSubscriberModel subscriber) async {
    final docRef = await _subscribers.add(subscriber.toMap());
    return docRef.id;
  }

  static Future<void> unsubscribe(String id) async {
    await _subscribers.doc(id).update({
      'isActive': false,
      'unsubscribedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteSubscriber(String id) async {
    await _subscribers.doc(id).delete();
  }
}
