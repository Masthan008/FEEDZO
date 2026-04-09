import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_addon_model.dart';

class FoodAddonService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _addons = _db.collection('foodAddons');

  static Stream<List<FoodAddonModel>> watchAllAddons() {
    return _addons.orderBy('name').snapshots().map((snap) {
      return snap.docs.map((doc) => FoodAddonModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<FoodAddonModel>> watchActiveAddons() {
    return _addons
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => FoodAddonModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<List<FoodAddonModel>> watchRestaurantAddons(String restaurantId) {
    return _addons
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('name')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => FoodAddonModel.fromFirestore(doc)).toList();
    });
  }

  static Future<FoodAddonModel?> getAddonById(String id) async {
    final doc = await _addons.doc(id).get();
    if (!doc.exists) return null;
    return FoodAddonModel.fromFirestore(doc);
  }

  static Future<String> addAddon(FoodAddonModel addon) async {
    final docRef = await _addons.add(addon.toMap());
    return docRef.id;
  }

  static Future<void> updateAddon(FoodAddonModel addon) async {
    await _addons.doc(addon.id).update(addon.toUpdateMap());
  }

  static Future<void> deleteAddon(String id) async {
    await _addons.doc(id).delete();
  }

  static Future<void> toggleAddonStatus(String id, bool isActive) async {
    await _addons.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
