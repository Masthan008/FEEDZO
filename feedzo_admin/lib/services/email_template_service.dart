import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/email_template_model.dart';

class EmailTemplateService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _templates = _db.collection('emailTemplates');

  static Stream<List<EmailTemplateModel>> watchAllTemplates() {
    return _templates.orderBy('name').snapshots().map((snap) {
      return snap.docs.map((doc) => EmailTemplateModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<EmailTemplateModel>> watchTemplatesByEvent(String eventType) {
    return _templates
        .where('eventType', isEqualTo: eventType)
        .orderBy('name')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => EmailTemplateModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<EmailTemplateModel>> watchActiveTemplates() {
    return _templates
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => EmailTemplateModel.fromFirestore(doc)).toList();
    });
  }

  static Future<EmailTemplateModel?> getTemplateById(String id) async {
    final doc = await _templates.doc(id).get();
    if (!doc.exists) return null;
    return EmailTemplateModel.fromFirestore(doc);
  }

  static Future<EmailTemplateModel?> getTemplateByEvent(String eventType) async {
    final snapshot = await _templates
        .where('eventType', isEqualTo: eventType)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return EmailTemplateModel.fromFirestore(snapshot.docs.first);
  }

  static Future<String> addTemplate(EmailTemplateModel template) async {
    final docRef = await _templates.add(template.toMap());
    return docRef.id;
  }

  static Future<void> updateTemplate(EmailTemplateModel template) async {
    await _templates.doc(template.id).update(template.toUpdateMap());
  }

  static Future<void> deleteTemplate(String id) async {
    await _templates.doc(id).delete();
  }

  static Future<void> toggleTemplateStatus(String id, bool isActive) async {
    await _templates.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
