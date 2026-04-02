import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../data/models/restaurant_model.dart';
import '../data/models/order_model.dart';
import '../data/models/user_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── Collections ──────────────────────────────────────────────────────────
  static CollectionReference get users => _db.collection('users');
  static CollectionReference get orders => _db.collection('orders');
  static CollectionReference get restaurants => _db.collection('restaurants');
  static CollectionReference get items => _db.collection('items');

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

  // ── Restaurants ──────────────────────────────────────────────────────────
  static Stream<List<Restaurant>> watchOpenRestaurants() => restaurants
      .snapshots()
      .map(
        (snap) => snap.docs
            .map(
              (doc) => Restaurant.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList(),
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
    final doc = await orders.add(
      order.toMap()..['createdAt'] = FieldValue.serverTimestamp(),
    );
    return doc.id;
  }

  static Stream<List<Order>> watchCustomerOrders(String customerId) => orders
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map(
              (doc) =>
                  Order.fromMap(doc.data() as Map<String, dynamic>, doc.id),
            )
            .toList(),
      );

  static Stream<Order> watchOrder(String orderId) => orders
      .doc(orderId)
      .snapshots()
      .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>, doc.id));

  static Future<void> cancelOrder(String orderId) =>
      orders.doc(orderId).update({'status': OrderStatus.cancelled.name});

  static Stream<List<Order>> watchRestaurantOrders(String restaurantId) =>
      orders
          .where('restaurantId', isEqualTo: restaurantId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map(
                  (doc) =>
                      Order.fromMap(doc.data() as Map<String, dynamic>, doc.id),
                )
                .toList(),
          );

  static Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      orders.doc(orderId).update({'status': status.name});

  static Future<void> updateMenuItemAvailability(
    String itemId,
    bool isAvailable,
  ) => items.doc(itemId).update({'isAvailable': isAvailable});

  // ── Driver Location (Real-time tracking) ────────────────────────────────
  /// Streams the driver's live {lat, lng} from the order document.
  /// The driver app should write `driverLocation: {lat: x, lng: y}` into the order doc.
  static Stream<Map<String, double>?> watchDriverLocation(String driverId) =>
      FirebaseFirestore.instance.collection('drivers').doc(driverId).snapshots().map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
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
}
