import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models.dart';

/// Service for admin restaurant CRUD operations
class RestaurantAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═════════════════════════════════════════════════════════════════════════════
  // CREATE
  // ═════════════════════════════════════════════════════════════════════════════

  /// Create a new restaurant (admin can bypass normal registration)
  Future<String?> createRestaurant({
    required String name,
    required String email,
    required String phone,
    required String cuisine,
    required String address,
    required String password, // For auth account creation
    double commissionRate = 10.0,
    String? fssaiNumber,
    String? gstNumber,
    String? panNumber,
    Map<String, dynamic>? documents,
    bool isApproved = true, // Admin created = auto approved
  }) async {
    try {
      final batch = _firestore.batch();
      final restaurantRef = _firestore.collection('restaurants').doc();
      final userRef = _firestore.collection('users').doc(restaurantRef.id);
      final now = FieldValue.serverTimestamp();

      // Restaurant document
      batch.set(restaurantRef, {
        'name': name,
        'email': email,
        'phone': phone,
        'cuisine': cuisine,
        'location': address,
        'address': address,
        'rating': 5.0,
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'wallet': 0.0,
        'commission': commissionRate,
        'isOpen': false,
        'isApproved': isApproved,
        'approvedAt': isApproved ? now : null,
        'approvedBy': isApproved ? 'admin' : null,
        'createdAt': now,
        'fssaiNumber': fssaiNumber,
        'gstNumber': gstNumber,
        'panNumber': panNumber,
        'documents': documents,
        'status': isApproved ? 'active' : 'pendingApproval',
      });

      // User document for authentication
      batch.set(userRef, {
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'restaurant',
        'status': isApproved ? 'approved' : 'pending',
        'restaurantId': restaurantRef.id,
        'createdAt': now,
      });

      await batch.commit();
      return restaurantRef.id;
    } catch (e) {
      print('Error creating restaurant: $e');
      return null;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // READ
  // ═════════════════════════════════════════════════════════════════════════════

  /// Get all restaurants
  Stream<List<AdminRestaurant>> getRestaurants() {
    return _firestore
        .collection('restaurants')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminRestaurant.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get restaurant by ID
  Future<AdminRestaurant?> getRestaurantById(String id) async {
    try {
      final doc = await _firestore.collection('restaurants').doc(id).get();
      if (doc.exists) {
        return AdminRestaurant.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting restaurant: $e');
      return null;
    }
  }

  /// Get pending approval restaurants
  Stream<List<AdminRestaurant>> getPendingRestaurants() {
    return _firestore
        .collection('restaurants')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AdminRestaurant.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get menu items for a restaurant
  Stream<List<Map<String, dynamic>>> getMenuItems(String restaurantId) {
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // UPDATE
  // ═════════════════════════════════════════════════════════════════════════════

  /// Update restaurant details
  Future<bool> updateRestaurant(
    String id, {
    String? name,
    String? email,
    String? phone,
    String? cuisine,
    String? address,
    double? commissionRate,
    String? fssaiNumber,
    String? gstNumber,
    String? panNumber,
    String? imageUrl,
  }) async {
    try {
      final batch = _firestore.batch();
      final restaurantRef = _firestore.collection('restaurants').doc(id);
      final userRef = _firestore.collection('users').doc(id);

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) {
        updateData['name'] = name;
        batch.update(userRef, {'name': name});
      }
      if (email != null) {
        updateData['email'] = email;
        batch.update(userRef, {'email': email});
      }
      if (phone != null) updateData['phone'] = phone;
      if (cuisine != null) updateData['cuisine'] = cuisine;
      if (address != null) {
        updateData['location'] = address;
        updateData['address'] = address;
      }
      if (commissionRate != null) updateData['commission'] = commissionRate;
      if (fssaiNumber != null) updateData['fssaiNumber'] = fssaiNumber;
      if (gstNumber != null) updateData['gstNumber'] = gstNumber;
      if (panNumber != null) updateData['panNumber'] = panNumber;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;

      batch.update(restaurantRef, updateData);
      await batch.commit();
      return true;
    } catch (e) {
      print('Error updating restaurant: $e');
      return false;
    }
  }

  /// Toggle restaurant open/close status
  Future<bool> toggleOpenClose(String id, bool isOpen) async {
    try {
      await _firestore.collection('restaurants').doc(id).update({
        'isOpen': isOpen,
        'status': isOpen ? 'active' : 'disabled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error toggling open/close: $e');
      return false;
    }
  }

  /// Approve restaurant
  Future<bool> approveRestaurant(String id, {String? approvedBy}) async {
    try {
      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      batch.update(_firestore.collection('restaurants').doc(id), {
        'isApproved': true,
        'isOpen': true,
        'status': 'active',
        'approvedAt': now,
        'approvedBy': approvedBy ?? 'admin',
        'rejectionReason': null,
        'updatedAt': now,
      });

      batch.update(_firestore.collection('users').doc(id), {
        'status': 'approved',
        'updatedAt': now,
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error approving restaurant: $e');
      return false;
    }
  }

  /// Reject restaurant with reason
  Future<bool> rejectRestaurant(String id, String reason) async {
    try {
      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      batch.update(_firestore.collection('restaurants').doc(id), {
        'isApproved': false,
        'isOpen': false,
        'status': 'pendingApproval',
        'rejectionReason': reason,
        'updatedAt': now,
      });

      batch.update(_firestore.collection('users').doc(id), {
        'status': 'rejected',
        'updatedAt': now,
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error rejecting restaurant: $e');
      return false;
    }
  }

  /// Update commission rate
  Future<bool> updateCommission(String id, double rate) async {
    try {
      await _firestore.collection('restaurants').doc(id).update({
        'commission': rate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating commission: $e');
      return false;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // DELETE
  // ═════════════════════════════════════════════════════════════════════════════

  /// Delete restaurant and all associated data
  Future<bool> deleteRestaurant(String id) async {
    try {
      final batch = _firestore.batch();

      // Delete restaurant
      batch.delete(_firestore.collection('restaurants').doc(id));

      // Delete user
      batch.delete(_firestore.collection('users').doc(id));

      // Note: Menu items, orders, and other subcollections remain for audit
      // but can be cleaned up separately if needed

      await batch.commit();
      return true;
    } catch (e) {
      print('Error deleting restaurant: $e');
      return false;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // MENU MANAGEMENT
  // ═════════════════════════════════════════════════════════════════════════════

  /// Add menu item
  Future<String?> addMenuItem(
    String restaurantId, {
    required String name,
    required String description,
    required double price,
    double discount = 0,
    bool isAvailable = true,
    bool isVeg = true,
    String category = 'Main Course',
    bool isBestseller = false,
    String? imageUrl,
  }) async {
    try {
      final docRef = _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .doc();

      await docRef.set({
        'restaurantId': restaurantId,
        'name': name,
        'description': description,
        'price': price,
        'discount': discount,
        'isAvailable': isAvailable,
        'isVeg': isVeg,
        'category': category,
        'isBestseller': isBestseller,
        'imageUrl': imageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error adding menu item: $e');
      return null;
    }
  }

  /// Update menu item
  Future<bool> updateMenuItem(
    String restaurantId,
    String itemId, {
    String? name,
    String? description,
    double? price,
    double? discount,
    bool? isAvailable,
    bool? isVeg,
    String? category,
    bool? isBestseller,
    String? imageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (discount != null) updateData['discount'] = discount;
      if (isAvailable != null) updateData['isAvailable'] = isAvailable;
      if (isVeg != null) updateData['isVeg'] = isVeg;
      if (category != null) updateData['category'] = category;
      if (isBestseller != null) updateData['isBestseller'] = isBestseller;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;

      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .doc(itemId)
          .update(updateData);

      return true;
    } catch (e) {
      print('Error updating menu item: $e');
      return false;
    }
  }

  /// Delete menu item
  Future<bool> deleteMenuItem(String restaurantId, String itemId) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .doc(itemId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting menu item: $e');
      return false;
    }
  }

  /// Toggle menu item availability
  Future<bool> toggleMenuItemAvailability(
    String restaurantId,
    String itemId,
    bool isAvailable,
  ) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu')
          .doc(itemId)
          .update({
        'isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error toggling menu item: $e');
      return false;
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // WALLET / PAYOUT
  // ═════════════════════════════════════════════════════════════════════════════

  /// Release payout to restaurant
  Future<bool> releasePayout(String restaurantId, double amount) async {
    try {
      final batch = _firestore.batch();
      final now = FieldValue.serverTimestamp();

      batch.update(_firestore.collection('restaurants').doc(restaurantId), {
        'wallet': 0,
        'updatedAt': now,
      });

      batch.set(_firestore.collection('transactions').doc(), {
        'restaurantId': restaurantId,
        'amount': amount,
        'type': 'payout',
        'status': 'completed',
        'createdAt': now,
        'processedBy': 'admin',
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error releasing payout: $e');
      return false;
    }
  }
}
