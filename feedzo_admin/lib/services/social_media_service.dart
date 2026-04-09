import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/social_media_model.dart';

class SocialMediaService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _socialMedia = _db.collection('socialMedia');

  static Stream<List<SocialMediaModel>> watchAllSocialMedia() {
    return _socialMedia.orderBy('sortOrder').snapshots().map((snap) {
      return snap.docs.map((doc) => SocialMediaModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<SocialMediaModel>> watchActiveSocialMedia() {
    return _socialMedia
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => SocialMediaModel.fromFirestore(doc)).toList();
    });
  }

  static Future<SocialMediaModel?> getSocialMediaById(String id) async {
    final doc = await _socialMedia.doc(id).get();
    if (!doc.exists) return null;
    return SocialMediaModel.fromFirestore(doc);
  }

  static Future<String> addSocialMedia(SocialMediaModel socialMedia) async {
    final docRef = await _socialMedia.add(socialMedia.toMap());
    return docRef.id;
  }

  static Future<void> updateSocialMedia(SocialMediaModel socialMedia) async {
    await _socialMedia.doc(socialMedia.id).update(socialMedia.toUpdateMap());
  }

  static Future<void> deleteSocialMedia(String id) async {
    await _socialMedia.doc(id).delete();
  }

  static Future<void> toggleSocialMediaStatus(String id, bool isActive) async {
    await _socialMedia.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> reorderSocialMedia(String id, int newSortOrder) async {
    await _socialMedia.doc(id).update({
      'sortOrder': newSortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
