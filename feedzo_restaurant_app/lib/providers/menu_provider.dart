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
          .collection('items')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Error deleting menu item: $e');
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // STOCK/INVENTORY MANAGEMENT
  // ═════════════════════════════════════════════════════════════════════════════

  /// Update stock quantity for a menu item
  Future<void> updateStock(String id, int newStock) async {
    try {
      await FirebaseFirestore.instance.collection('items').doc(id).update({
        'stockQuantity': newStock,
        'isAvailable': newStock > 0, // Auto-disable if out of stock
      });
      debugPrint('Stock updated for item $id: $newStock');
    } catch (e) {
      debugPrint('Error updating stock: $e');
      rethrow;
    }
  }

  /// Decrement stock when order is placed
  Future<bool> decrementStock(String id, int quantity) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('items').doc(id).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final trackInventory = data['trackInventory'] ?? false;
      final unlimitedStock = data['unlimitedStock'] ?? true;

      if (!trackInventory || unlimitedStock) return true;

      final currentStock = (data['stockQuantity'] ?? 0) as int;
      final newStock = currentStock - quantity;

      if (newStock < 0) {
        debugPrint('Insufficient stock for item $id');
        return false;
      }

      await FirebaseFirestore.instance.collection('items').doc(id).update({
        'stockQuantity': newStock,
        'isAvailable': newStock > 0,
      });

      debugPrint('Stock decremented for item $id: $currentStock -> $newStock');
      return true;
    } catch (e) {
      debugPrint('Error decrementing stock: $e');
      return false;
    }
  }

  /// Enable/disable inventory tracking
  Future<void> setInventoryTracking(String id, bool track, {int initialStock = 10}) async {
    try {
      await FirebaseFirestore.instance.collection('items').doc(id).update({
        'trackInventory': track,
        'stockQuantity': track ? initialStock : -1,
        'unlimitedStock': !track,
      });
      debugPrint('Inventory tracking ${track ? 'enabled' : 'disabled'} for item $id');
    } catch (e) {
      debugPrint('Error setting inventory tracking: $e');
      rethrow;
    }
  }

  /// Get items with low stock
  List<MenuItemModel> get lowStockItems {
    return _items.where((item) => item.isLowStock).toList();
  }

  /// Get items out of stock
  List<MenuItemModel> get outOfStockItems {
    return _items.where((item) => item.isOutOfStock).toList();
  }

  /// Get inventory summary
  Map<String, int> get inventorySummary {
    return {
      'total': _items.length,
      'tracking': _items.where((i) => i.trackInventory).length,
      'lowStock': lowStockItems.length,
      'outOfStock': outOfStockItems.length,
      'unlimited': _items.where((i) => i.unlimitedStock).length,
    };
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
