import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/landing_page_model.dart';

class LandingPageService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _landingPages = _db.collection('landingPages');

  static Stream<LandingPageModel?> watchActiveLandingPage() {
    return _landingPages
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return LandingPageModel.fromFirestore(snap.docs.first);
    });
  }

  static Stream<List<LandingPageModel>> watchAllLandingPages() {
    return _landingPages.orderBy('updatedAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => LandingPageModel.fromFirestore(doc)).toList();
    });
  }

  static Future<LandingPageModel?> getActiveLandingPage() async {
    final snapshot = await _landingPages.where('isActive', isEqualTo: true).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return LandingPageModel.fromFirestore(snapshot.docs.first);
  }

  static Future<LandingPageModel?> getLandingPageById(String id) async {
    final doc = await _landingPages.doc(id).get();
    if (!doc.exists) return null;
    return LandingPageModel.fromFirestore(doc);
  }

  static Future<String> saveLandingPage(LandingPageModel landingPage) async {
    if (landingPage.isActive) {
      final batch = _db.batch();
      final existing = await _landingPages.where('isActive', isEqualTo: true).get();
      for (var doc in existing.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      if (landingPage.id.isEmpty) {
        final newDocRef = _landingPages.doc();
        batch.set(newDocRef, landingPage.toMap());
        await batch.commit();
        return newDocRef.id;
      } else {
        batch.update(_landingPages.doc(landingPage.id), landingPage.toUpdateMap());
        await batch.commit();
        return landingPage.id;
      }
    }
    
    if (landingPage.id.isEmpty) {
      final docRef = await _landingPages.add(landingPage.toMap());
      return docRef.id;
    } else {
      await _landingPages.doc(landingPage.id).update(landingPage.toUpdateMap());
      return landingPage.id;
    }
  }

  static Future<void> updateLandingPage(LandingPageModel landingPage) async {
    if (landingPage.isActive) {
      final batch = _db.batch();
      final existing = await _landingPages.where('isActive', isEqualTo: true).get();
      for (var doc in existing.docs) {
        if (doc.id != landingPage.id) {
          batch.update(doc.reference, {'isActive': false});
        }
      }
      batch.update(_landingPages.doc(landingPage.id), landingPage.toUpdateMap());
      await batch.commit();
    } else {
      await _landingPages.doc(landingPage.id).update(landingPage.toUpdateMap());
    }
  }

  static Future<void> deleteLandingPage(String id) async {
    await _landingPages.doc(id).delete();
  }

  static Future<void> toggleLandingPageStatus(String id, bool isActive) async {
    if (isActive) {
      await setActiveLandingPage(id);
    } else {
      await _landingPages.doc(id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> setActiveLandingPage(String id) async {
    final batch = _db.batch();
    final existing = await _landingPages.where('isActive', isEqualTo: true).get();
    for (var doc in existing.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    batch.update(_landingPages.doc(id), {
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
