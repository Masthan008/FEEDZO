import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/language_model.dart';

class LanguageService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _languages = _db.collection('languages');

  static Stream<List<LanguageModel>> watchAllLanguages() {
    return _languages.orderBy('name').snapshots().map((snap) {
      return snap.docs.map((doc) => LanguageModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<LanguageModel>> watchActiveLanguages() {
    return _languages
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => LanguageModel.fromFirestore(doc)).toList();
    });
  }

  static Future<LanguageModel?> getDefaultLanguage() async {
    final snapshot = await _languages.where('isDefault', isEqualTo: true).get();
    if (snapshot.docs.isEmpty) return null;
    return LanguageModel.fromFirestore(snapshot.docs.first);
  }

  static Future<LanguageModel?> getLanguageById(String id) async {
    final doc = await _languages.doc(id).get();
    if (!doc.exists) return null;
    return LanguageModel.fromFirestore(doc);
  }

  static Future<String> addLanguage(LanguageModel language) async {
    // If this is set as default, remove default from all others
    if (language.isDefault) {
      final batch = _db.batch();
      final existing = await _languages.where('isDefault', isEqualTo: true).get();
      for (var doc in existing.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      final newDocRef = _languages.doc();
      batch.set(newDocRef, language.toMap());
      await batch.commit();
      return newDocRef.id;
    }
    
    final docRef = await _languages.add(language.toMap());
    return docRef.id;
  }

  static Future<void> updateLanguage(LanguageModel language) async {
    // If this is set as default, remove default from all others
    if (language.isDefault) {
      final batch = _db.batch();
      final existing = await _languages.where('isDefault', isEqualTo: true).get();
      for (var doc in existing.docs) {
        if (doc.id != language.id) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }
      batch.update(_languages.doc(language.id), language.toUpdateMap());
      await batch.commit();
    } else {
      await _languages.doc(language.id).update(language.toUpdateMap());
    }
  }

  static Future<void> deleteLanguage(String id) async {
    await _languages.doc(id).delete();
  }

  static Future<void> toggleLanguageStatus(String id, bool isActive) async {
    await _languages.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setDefaultLanguage(String id) async {
    final batch = _db.batch();
    final existing = await _languages.where('isDefault', isEqualTo: true).get();
    for (var doc in existing.docs) {
      batch.update(doc.reference, {'isDefault': false});
    }
    batch.update(_languages.doc(id), {
      'isDefault': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
