import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/theme_model.dart';

class ThemeService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _themes = _db.collection('themes');

  static Stream<List<ThemeModel>> watchAllThemes() {
    return _themes.orderBy('name').snapshots().map((snap) {
      return snap.docs.map((doc) => ThemeModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<ThemeModel>> watchActiveThemes() {
    return _themes
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => ThemeModel.fromFirestore(doc)).toList();
    });
  }

  static Future<ThemeModel?> getActiveTheme() async {
    final snapshot = await _themes.where('isActive', isEqualTo: true).get();
    if (snapshot.docs.isEmpty) return null;
    return ThemeModel.fromFirestore(snapshot.docs.first);
  }

  static Future<ThemeModel?> getThemeById(String id) async {
    final doc = await _themes.doc(id).get();
    if (!doc.exists) return null;
    return ThemeModel.fromFirestore(doc);
  }

  static Future<String> addTheme(ThemeModel theme) async {
    // If this is set as active, deactivate all others
    if (theme.isActive) {
      final batch = _db.batch();
      final existing = await _themes.where('isActive', isEqualTo: true).get();
      for (var doc in existing.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      final newDocRef = _themes.doc();
      batch.set(newDocRef, theme.toMap());
      await batch.commit();
      return newDocRef.id;
    }
    
    final docRef = await _themes.add(theme.toMap());
    return docRef.id;
  }

  static Future<void> updateTheme(ThemeModel theme) async {
    // If this is set as active, deactivate all others
    if (theme.isActive) {
      final batch = _db.batch();
      final existing = await _themes.where('isActive', isEqualTo: true).get();
      for (var doc in existing.docs) {
        if (doc.id != theme.id) {
          batch.update(doc.reference, {'isActive': false});
        }
      }
      batch.update(_themes.doc(theme.id), theme.toUpdateMap());
      await batch.commit();
    } else {
      await _themes.doc(theme.id).update(theme.toUpdateMap());
    }
  }

  static Future<void> deleteTheme(String id) async {
    await _themes.doc(id).delete();
  }

  static Future<void> toggleThemeStatus(String id, bool isActive) async {
    if (isActive) {
      await setDefaultTheme(id);
    } else {
      await _themes.doc(id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> setDefaultTheme(String id) async {
    final batch = _db.batch();
    final existing = await _themes.where('isActive', isEqualTo: true).get();
    for (var doc in existing.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    batch.update(_themes.doc(id), {
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
