import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/legal_page_model.dart';

class LegalPageService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _legalPages = _db.collection('legalPages');

  static Stream<List<LegalPageModel>> watchAllLegalPages() {
    return _legalPages.orderBy('title').snapshots().map((snap) {
      return snap.docs.map((doc) => LegalPageModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<LegalPageModel>> watchLegalPagesByType(String type) {
    return _legalPages.where('type', isEqualTo: type).snapshots().map((snap) {
      return snap.docs.map((doc) => LegalPageModel.fromFirestore(doc)).toList();
    });
  }

  static Future<LegalPageModel?> getLegalPageById(String id) async {
    final doc = await _legalPages.doc(id).get();
    if (!doc.exists) return null;
    return LegalPageModel.fromFirestore(doc);
  }

  static Future<LegalPageModel?> getLegalPageBySlug(String slug) async {
    final snapshot = await _legalPages.where('slug', isEqualTo: slug).get();
    if (snapshot.docs.isEmpty) return null;
    return LegalPageModel.fromFirestore(snapshot.docs.first);
  }

  static Future<String> addLegalPage(LegalPageModel legalPage) async {
    final docRef = await _legalPages.add(legalPage.toMap());
    return docRef.id;
  }

  static Future<void> updateLegalPage(LegalPageModel legalPage) async {
    await _legalPages.doc(legalPage.id).update(legalPage.toUpdateMap());
  }

  static Future<void> deleteLegalPage(String id) async {
    await _legalPages.doc(id).delete();
  }
}
