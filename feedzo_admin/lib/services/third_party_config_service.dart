import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/third_party_config_model.dart';

class ThirdPartyConfigService {
  static final _db = FirebaseFirestore.instance;
  static final CollectionReference _configs = _db.collection('thirdPartyConfigs');

  static Stream<List<ThirdPartyConfigModel>> watchAllConfigs() {
    return _configs.orderBy('serviceName').snapshots().map((snap) {
      return snap.docs.map((doc) => ThirdPartyConfigModel.fromFirestore(doc)).toList();
    });
  }

  static Stream<ThirdPartyConfigModel?> watchConfigByService(String serviceName) {
    return _configs.where('serviceName', isEqualTo: serviceName).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return ThirdPartyConfigModel.fromFirestore(snap.docs.first);
    });
  }

  static Future<ThirdPartyConfigModel?> getConfigByService(String serviceName) async {
    final snapshot = await _configs.where('serviceName', isEqualTo: serviceName).get();
    if (snapshot.docs.isEmpty) return null;
    return ThirdPartyConfigModel.fromFirestore(snapshot.docs.first);
  }

  static Future<String> saveConfig(ThirdPartyConfigModel config) async {
    final existing = await _configs.where('serviceName', isEqualTo: config.serviceName).get();
    if (existing.docs.isEmpty) {
      final docRef = await _configs.add(config.toMap());
      return docRef.id;
    } else {
      await _configs.doc(existing.docs.first.id).update(config.toUpdateMap());
      return existing.docs.first.id;
    }
  }

  static Future<void> updateConfig(ThirdPartyConfigModel config) async {
    await _configs.doc(config.id).update(config.toUpdateMap());
  }

  static Future<void> deleteConfig(String id) async {
    await _configs.doc(id).delete();
  }

  static Future<void> toggleConfigStatus(String id, bool isActive) async {
    await _configs.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
