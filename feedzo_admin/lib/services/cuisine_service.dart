import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cuisine_model.dart';

class CuisineService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _cuisines = _db.collection('cuisines');

  static Stream<List<CuisineModel>> watchAllCuisines() {
    return _cuisines.orderBy('priority', descending: true).orderBy('name').snapshots().map((snap) {
      return snap.docs.map((doc) => CuisineModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<CuisineModel>> watchActiveCuisines() {
    return _cuisines
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .orderBy('name')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => CuisineModel.fromFirestore(doc)).toList();
    });
  }

  static Future<CuisineModel?> getCuisineById(String id) async {
    final doc = await _cuisines.doc(id).get();
    if (!doc.exists) return null;
    return CuisineModel.fromFirestore(doc);
  }

  static Future<String> addCuisine(CuisineModel cuisine) async {
    final docRef = await _cuisines.add(cuisine.toMap());
    return docRef.id;
  }

  static Future<void> updateCuisine(CuisineModel cuisine) async {
    await _cuisines.doc(cuisine.id).update(cuisine.toUpdateMap());
  }

  static Future<void> deleteCuisine(String id) async {
    await _cuisines.doc(id).delete();
  }

  static Future<void> toggleCuisineStatus(String id, bool isActive) async {
    await _cuisines.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
