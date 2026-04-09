import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VoiceSearchService {
  static final _speech = SpeechToText();
  static bool _isInitialized = false;

  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    final available = await _speech.initialize();
    _isInitialized = available;
    return available;
  }

  static Future<bool> startListening({
    required Function(String) onResult,
    required Function(String) onError,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    await _speech.listen(
      onResult: (result) {
        final recognizedWords = result.recognizedWords;
        onResult(recognizedWords);
      },
      onError: (error) {
        onError(error.toString());
      },
      cancelOnError: true,
      partialResults: true,
    );
    return true;
  }

  static Future<void> stopListening() async {
    await _speech.stop();
  }

  static bool get isListening => _speech.isListening;

  static Future<List<Map<String, dynamic>>> searchByVoice(String query) async {
    // Search restaurants and items by voice query
    final restaurants = await FirebaseFirestore.instance
        .collection('restaurants')
        .where('isOpen', isEqualTo: true)
        .where('name', isGreaterThanOrEqualTo: query)
        .limit(10)
        .get();

    final items = await FirebaseFirestore.instance
        .collection('items')
        .where('isAvailable', isEqualTo: true)
        .where('name', isGreaterThanOrEqualTo: query)
        .limit(10)
        .get();

    final results = <Map<String, dynamic>>[];

    for (var doc in restaurants.docs) {
      results.add({
        'type': 'restaurant',
        'id': doc.id,
        'name': doc.data()['name'],
        'image': doc.data()['imageUrl'],
      });
    }

    for (var doc in items.docs) {
      results.add({
        'type': 'item',
        'id': doc.id,
        'name': doc.data()['name'],
        'image': doc.data()['imageUrl'],
        'restaurantId': doc.data()['restaurantId'],
      });
    }

    return results;
  }
}
