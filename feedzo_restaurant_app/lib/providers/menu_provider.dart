import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

class MenuProvider extends ChangeNotifier {
  List<MenuItemModel> _items = [];
  StreamSubscription? _subscription;
  bool _isLoading = false;

  List<MenuItemModel> get items => _items;
  bool get isLoading => _isLoading;

  void init(String restaurantId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = FirebaseFirestore.instance
        .collection('items')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .listen(
          (snap) {
            final fetchedItems = snap.docs
                .map((doc) => MenuItemModel.fromFirestore(doc))
                .toList();
            fetchedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _items = fetchedItems;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Firestore Menu Error: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> addItem(MenuItemModel item) async {
    try {
      await FirebaseFirestore.instance
          .collection('items') // Changed from 'menu_items'
          .add(item.toMap())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Error adding menu item: $e');
      rethrow;
    }
  }

  Future<void> updateItem(MenuItemModel item) async {
    try {
      await FirebaseFirestore.instance
          .collection('items') // Changed from 'menu_items'
          .doc(item.id)
          .update(item.toMap())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Error updating menu item: $e');
      rethrow;
    }
  }

  Future<void> toggleAvailability(String id, bool isAvailable) async {
    try {
      await FirebaseFirestore.instance.collection('items').doc(id).update({
        'isAvailable': isAvailable,
      });
    } catch (e) {
      debugPrint('Error toggling availability: $e');
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('items') // Changed from 'menu_items'
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Error deleting menu item: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
