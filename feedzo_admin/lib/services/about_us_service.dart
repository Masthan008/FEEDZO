import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/about_us_model.dart';

class AboutUsService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _aboutUs = _db.collection('aboutUs');

  static Stream<AboutUsModel?> watchAboutUs() {
    return _aboutUs.limit(1).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return AboutUsModel.fromFirestore(snap.docs.first);
    });
  }

  static Future<AboutUsModel?> getAboutUs() async {
    final snapshot = await _aboutUs.limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return AboutUsModel.fromFirestore(snapshot.docs.first);
  }

  static Future<String> saveAboutUs(AboutUsModel aboutUs) async {
    final existing = await _aboutUs.limit(1).get();
    if (existing.docs.isEmpty) {
      final docRef = await _aboutUs.add(aboutUs.toMap());
      return docRef.id;
    } else {
      await _aboutUs.doc(existing.docs.first.id).update(aboutUs.toUpdateMap());
      return existing.docs.first.id;
    }
  }

  static Future<void> updateAboutUs(AboutUsModel aboutUs) async {
    await _aboutUs.doc(aboutUs.id).update(aboutUs.toUpdateMap());
  }
}
