import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';

  static Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? _defaultLanguage;
  }

  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  static Future<List<Map<String, dynamic>>> getAvailableLanguages() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('languages')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'code': data['code'],
        'name': data['name'],
        'nativeName': data['nativeName'],
        'flag': data['flag'],
      };
    }).toList();
  }

  static Future<Map<String, String>> getTranslations(String languageCode) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('translations')
        .doc(languageCode)
        .get();

    if (!snapshot.exists) {
      return {};
    }

    return Map<String, String>.from(snapshot.data() ?? {});
  }

  static Future<void> initialize(BuildContext context) async {
    final languageCode = await getCurrentLanguage();
    // Load translations and update app locale
  }
}
