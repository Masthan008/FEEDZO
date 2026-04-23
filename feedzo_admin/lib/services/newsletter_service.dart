import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/newsletter_model.dart';

class NewsletterService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _subscribers = _db.collection('newsletterSubscribers');
  static final CollectionReference _sentNewsletters = _db.collection('sentNewsletters');

  static Stream<List<NewsletterSubscriberModel>> watchAllSubscribers() {
    return _subscribers.orderBy('subscribedAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => NewsletterSubscriberModel.fromFirestore(doc)).toList();
    });
  }

  static Future<List<NewsletterSubscriberModel>> getAllSubscribers() async {
    final snap = await _subscribers.orderBy('subscribedAt', descending: true).get();
    return snap.docs.map((doc) => NewsletterSubscriberModel.fromFirestore(doc)).toList();
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

  static Future<void> sendNewsletter({
    required String subject,
    required String content,
    required List<NewsletterSubscriberModel> subscribers,
  }) async {
    // Save newsletter record to Firestore
    await _sentNewsletters.add({
      'subject': subject,
      'content': content,
      'recipientCount': subscribers.length,
      'sentAt': FieldValue.serverTimestamp(),
    });

    // In a real implementation, this would integrate with an email service like:
    // - SendGrid
    // - Mailchimp
    // - AWS SES
    // - Firebase Cloud Functions with email API
    // For now, we'll simulate the sending by logging to Firestore
    
    for (final subscriber in subscribers) {
      await _subscribers.doc(subscriber.id).collection('newsletters').add({
        'subject': subject,
        'content': content,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'sent',
      });
    }
  }
}
