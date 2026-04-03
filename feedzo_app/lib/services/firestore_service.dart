import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/foundation.dart';
import '../data/models/restaurant_model.dart';
import '../data/models/order_model.dart';
import '../data/models/user_model.dart';
import '../data/models/banner_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── Collections ──────────────────────────────────────────────────────────
  static CollectionReference get users => _db.collection('users');
  static CollectionReference get orders => _db.collection('orders');
  static CollectionReference get restaurants => _db.collection('restaurants');
  static CollectionReference get items => _db.collection('items');
  static CollectionReference get coupons => _db.collection('coupons');

  // ── User ─────────────────────────────────────────────────────────────────
  static Future<void> saveUser(UserModel user) => users
      .doc(user.id)
      .set(user.toMap()..['createdAt'] = FieldValue.serverTimestamp());

  static Stream<UserModel?> watchUser(String uid) => users
      .doc(uid)
      .snapshots()
      .map(
        (doc) => doc.exists
            ? UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
            : null,
      );

  static Future<void> updateAddress(String uid, List<String> addresses) =>
      users.doc(uid).update({'savedAddresses': addresses});

  static Future<void> updateUserProfile(
      String uid, Map<String, dynamic> data) =>
      users.doc(uid).update(data);

  // ── Favorites ─────────────────────────────────────────────────────────────
  /// Toggle a restaurant in the user's favorites list.
  static Future<void> toggleFavoriteRestaurant(
      String uid, String restaurantId) async {
    final doc = await users.doc(uid).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final favs = List<String>.from(data['favoriteRestaurants'] ?? []);
    if (favs.contains(restaurantId)) {
      favs.remove(restaurantId);
    } else {
      favs.add(restaurantId);
    }
    await users.doc(uid).update({'favoriteRestaurants': favs});
  }

  /// Toggle a menu item in the user's favorites list.
  static Future<void> toggleFavoriteItem(String uid, String itemId) async {
    final doc = await users.doc(uid).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final favs = List<String>.from(data['favoriteItems'] ?? []);
    if (favs.contains(itemId)) {
      favs.remove(itemId);
    } else {
      favs.add(itemId);
    }
    await users.doc(uid).update({'favoriteItems': favs});
  }

  // ── Coupons ───────────────────────────────────────────────────────────────
  /// Validate and return coupon details. Returns null if invalid/expired.
  static Future<Map<String, dynamic>?> validateCoupon(
      String code, double orderSubtotal) async {
    try {
      final snap = await coupons
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;

      final coupon = snap.docs.first.data() as Map<String, dynamic>;
      final minOrder = (coupon['minOrder'] as num?)?.toDouble() ?? 0;
      if (orderSubtotal < minOrder) return null;

      // Check expiry
      final expiresAt = (coupon['expiresAt'] as dynamic)?.toDate();
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) return null;

      // Check usage limit
      final usageLimit = (coupon['usageLimit'] as num?)?.toInt() ?? 0;
      final usageCount = (coupon['usageCount'] as num?)?.toInt() ?? 0;
      if (usageLimit > 0 && usageCount >= usageLimit) return null;

      // Calculate discount
      double discountAmount;
      final type = coupon['type'] ?? 'flat'; // 'flat' or 'percent'
      final value = (coupon['value'] as num?)?.toDouble() ?? 0;
      final maxDiscount = (coupon['maxDiscount'] as num?)?.toDouble() ?? 999999;

      if (type == 'percent') {
        discountAmount = (orderSubtotal * value / 100).clamp(0, maxDiscount);
      } else {
        discountAmount = value.clamp(0, orderSubtotal);
      }

      return {
        'id': snap.docs.first.id,
        'code': code.toUpperCase(),
        'discount': discountAmount,
        'type': type,
        'value': value,
        'description': coupon['description'] ?? '',
      };
    } catch (e) {
      debugPrint('[FirestoreService] Coupon validation failed: $e');
      return null;
    }
  }

  /// Fetch all active coupons for display in the app.
  static Future<List<Map<String, dynamic>>> getActiveCoupons() async {
    try {
      final snap = await coupons
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('[FirestoreService] Fetching coupons failed: $e');
      return [];
    }
  }

  // ── Restaurants ──────────────────────────────────────────────────────────
  static Stream<List<Restaurant>> watchOpenRestaurants() => restaurants
      .snapshots()
      .map(
        (snap) {
          final List<Restaurant> result = [];
          for (final doc in snap.docs) {
            try {
              result.add(Restaurant.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ));
            } catch (e) {
              debugPrint('[FirestoreService] Skipping bad restaurant doc ${doc.id}: $e');
            }
          }
          return result;
        },
      );

  static Stream<List<MenuItem>> watchRestaurantMenu(String restaurantId) =>
      items
          .where('restaurantId', isEqualTo: restaurantId)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map(
                  (doc) => MenuItem.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .toList(),
          );

  // ── Orders ────────────────────────────────────────────────────────────────
  static Future<String> placeOrder(Order order) async {
    final counterRef = _db.collection('system').doc('counters');
    
    // 1. Transaction to generate consecutive Order ID
    final newOrderId = await _db.runTransaction<String>((tx) async {
      final counterSnap = await tx.get(counterRef);
      int nextId = 1;

      if (counterSnap.exists) {
        nextId = (counterSnap.data()?['orders'] as num?)?.toInt() ?? 1;
        nextId++;
        tx.update(counterRef, {'orders': nextId});
      } else {
        tx.set(counterRef, {'orders': 1});
      }

      final displayId = '#${nextId.toString().padLeft(4, '0')}';
      final docRef = orders.doc(displayId);
      
      final data = order.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      
      tx.set(docRef, data);
      return displayId;
    });

    // 2. Create an alert for admin dashboard
    try {
      await _db.collection('alerts').add({
        'type': 'orderAlert',
        'title': 'New Order Placed',
        'message': '${order.customerName} placed an order at ${order.restaurantName} — ₹${order.totalAmount.toStringAsFixed(0)} (${order.paymentType.toUpperCase()})',
        'orderId': newOrderId,
        'customerId': order.customerId,
        'restaurantId': order.restaurantId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FirestoreService] Alert creation failed: $e');
    }

    // 3. Increment coupon usage count if a coupon was applied
    if (order.couponCode != null) {
      try {
        final couponSnap = await coupons
            .where('code', isEqualTo: order.couponCode)
            .limit(1)
            .get();
        if (couponSnap.docs.isNotEmpty) {
          await coupons.doc(couponSnap.docs.first.id).update({
            'usageCount': FieldValue.increment(1),
          });
        }
      } catch (e) {
        debugPrint('[FirestoreService] Coupon usage update failed: $e');
      }
    }

    return newOrderId;
  }

  static Stream<List<Order>> watchCustomerOrders(String customerId) => orders
      .where('customerId', isEqualTo: customerId)
      // Removed .orderBy to bypass the missing Firebase composite index
      .snapshots()
      .map((snap) {
        final list = snap.docs
            .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        // Sort locally to keep newest orders on top
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  static Stream<Order> watchOrder(String orderId) => orders
      .doc(orderId)
      .snapshots()
      .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>, doc.id));

  static Future<void> cancelOrder(String orderId, {String? reason}) =>
      orders.doc(orderId).update({
        'status': OrderStatus.cancelled.name,
        if (reason != null) 'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  static Stream<List<Order>> watchRestaurantOrders(String restaurantId) =>
      orders
          .where('restaurantId', isEqualTo: restaurantId)
          // Removed .orderBy to bypass composite index constraints
          .snapshots()
          .map((snap) {
            final list = snap.docs
                .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                .toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          });

  static Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      orders.doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  static Future<void> updateMenuItemAvailability(
    String itemId,
    bool isAvailable,
  ) => items.doc(itemId).update({'isAvailable': isAvailable});

  // ── Driver Location (Real-time tracking) ────────────────────────────────
  /// Streams the driver's live {lat, lng} from the order document.
  /// The driver app should write `driverLocation: {lat: x, lng: y}` into the order doc.
  static Stream<Map<String, double>?> watchDriverLocation(String driverId) =>
      FirebaseFirestore.instance.collection('drivers').doc(driverId).snapshots().map((doc) {
        final data = doc.data();
        if (data == null) return null;
        final loc = data['location'] as Map<String, dynamic>?;
        if (loc == null) return null;
        return {
          'lat': (loc['lat'] as num?)?.toDouble() ?? 0,
          'lng': (loc['lng'] as num?)?.toDouble() ?? 0,
        };
      });

  /// Updates driver location on the order document (used by driver app).
  static Future<void> updateDriverLocation(
      String orderId, double lat, double lng) =>
      orders.doc(orderId).update({
        'driverLocation': {'lat': lat, 'lng': lng},
      });

  // ── Promotions & Banners ────────────────────────────────────────────────
  static Stream<List<BannerModel>> watchActiveBanners() => _db
      .collection('banners')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((doc) => BannerModel.fromFirestore(doc)).toList());
}

