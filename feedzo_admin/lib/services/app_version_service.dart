import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_version_model.dart';

class AppVersionService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _versions = _db.collection('appVersions');

  static Stream<List<AppVersionModel>> watchAllVersions() {
    return _versions.orderBy('buildNumber', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) => AppVersionModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<AppVersionModel>> watchActiveVersions() {
    return _versions
        .where('isActive', isEqualTo: true)
        .orderBy('buildNumber', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => AppVersionModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<AppVersionModel?> watchLatestVersion(String platform) {
    return _versions
        .where('platform', isEqualTo: platform)
        .where('isActive', isEqualTo: true)
        .orderBy('buildNumber', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return AppVersionModel.fromFirestore(snap.docs.first);
    });
  }

  static Future<AppVersionModel?> getLatestVersion(String platform) async {
    final snapshot = await _versions
        .where('platform', isEqualTo: platform)
        .where('isActive', isEqualTo: true)
        .orderBy('buildNumber', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return AppVersionModel.fromFirestore(snapshot.docs.first);
  }

  static Future<String> addVersion(AppVersionModel version) async {
    // If this is set as active, deactivate all others for this platform
    if (version.isActive) {
      final batch = _db.batch();
      final existing = await _versions
          .where('platform', isEqualTo: version.platform)
          .where('isActive', isEqualTo: true)
          .get();
      for (var doc in existing.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      final newDocRef = _versions.doc();
      batch.set(newDocRef, version.toMap());
      await batch.commit();
      return newDocRef.id;
    }
    
    final docRef = await _versions.add(version.toMap());
    return docRef.id;
  }

  static Future<void> updateVersion(AppVersionModel version) async {
    // If this is set as active, deactivate all others for this platform
    if (version.isActive) {
      final batch = _db.batch();
      final existing = await _versions
          .where('platform', isEqualTo: version.platform)
          .where('isActive', isEqualTo: true)
          .get();
      for (var doc in existing.docs) {
        if (doc.id != version.id) {
          batch.update(doc.reference, {'isActive': false});
        }
      }
      batch.update(_versions.doc(version.id), version.toUpdateMap());
      await batch.commit();
    } else {
      await _versions.doc(version.id).update(version.toUpdateMap());
    }
  }

  static Future<void> deleteVersion(String id) async {
    await _versions.doc(id).delete();
  }

  static Future<void> toggleVersionStatus(String id, bool isActive) async {
    if (isActive) {
      final version = await getVersionById(id);
      if (version != null) {
        await setActiveVersion(version.id, version.platform);
      }
    } else {
      await _versions.doc(id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> setActiveVersion(String id, String platform) async {
    final batch = _db.batch();
    final existing = await _versions
        .where('platform', isEqualTo: platform)
        .where('isActive', isEqualTo: true)
        .get();
    for (var doc in existing.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    batch.update(_versions.doc(id), {
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  static Future<AppVersionModel?> getVersionById(String id) async {
    final doc = await _versions.doc(id).get();
    if (!doc.exists) return null;
    return AppVersionModel.fromFirestore(doc);
  }
}
