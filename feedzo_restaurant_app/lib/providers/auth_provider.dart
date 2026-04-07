import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String _userName = '';
  String _restaurantName = '';
  String _status = 'pending';
  String? _errorMessage;
  String _description = '';
  String _coverImageUrl = '';
  List<String> _restaurantImages = [];
  String _phone = '';
  int _defaultPrepTime = 20;
  double _deliveryRadius = 5.0;
  String _payoutUpi = '';

  // New fields to match customer app
  String _cuisine = '';
  double _deliveryFee = 0.0;
  double _minOrder = 0.0;
  bool _isVeg = false;
  String _address = '';

  bool _isRestaurantOpen = true;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String get userName => _userName;
  String get restaurantName => _restaurantName;
  String get status => _status;
  bool get isApproved => _status == 'approved';
  bool get isRestaurantOpen => _isRestaurantOpen;
  String get description => _description;
  String get coverImageUrl => _coverImageUrl;
  List<String> get restaurantImages => _restaurantImages;
  String get phone => _phone;
  int get defaultPrepTime => _defaultPrepTime;
  double get deliveryRadius => _deliveryRadius;
  String get payoutUpi => _payoutUpi;
  String? get errorMessage => _errorMessage;
  User? get user => FirebaseAuth.instance.currentUser;

  // Getters for new fields
  String get cuisine => _cuisine;
  double get deliveryFee => _deliveryFee;
  double get minOrder => _minOrder;
  bool get isVeg => _isVeg;
  String get address => _address;

  Future<void> toggleRestaurantStatus(bool isOpen) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid)
          .update({'isOpen': isOpen});
      _isRestaurantOpen = isOpen;
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling restaurant status: $e');
    }
  }

  Future<void> updateProfile({
    String? description,
    String? coverImageUrl,
    List<String>? restaurantImages,
    String? phone,
    int? defaultPrepTime,
    double? deliveryRadius,
    String? payoutUpi,
    String? cuisine,
    double? deliveryFee,
    double? minOrder,
    bool? isVeg,
    String? address,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final Map<String, dynamic> data = {};
      if (description != null) data['description'] = description;
      if (coverImageUrl != null) data['coverImageUrl'] = coverImageUrl;
      if (restaurantImages != null) data['imageUrls'] = restaurantImages;
      if (phone != null) data['phone'] = phone;
      if (defaultPrepTime != null) {
        data['defaultPrepTime'] = defaultPrepTime;
        data['deliveryTime'] = defaultPrepTime; // sync for customer app
      }
      if (deliveryRadius != null) data['deliveryRadius'] = deliveryRadius;
      if (payoutUpi != null) data['payoutUpi'] = payoutUpi;
      if (cuisine != null) data['cuisine'] = cuisine;
      if (deliveryFee != null) data['deliveryFee'] = deliveryFee;
      if (minOrder != null) data['minOrder'] = minOrder;
      if (isVeg != null) data['isVeg'] = isVeg;
      if (address != null) data['address'] = address;

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid)
          .update(data);

      if (description != null) _description = description;
      if (coverImageUrl != null) _coverImageUrl = coverImageUrl;
      if (restaurantImages != null) _restaurantImages = restaurantImages;
      if (phone != null) _phone = phone;
      if (defaultPrepTime != null) _defaultPrepTime = defaultPrepTime;
      if (deliveryRadius != null) _deliveryRadius = deliveryRadius;
      if (payoutUpi != null) _payoutUpi = payoutUpi;
      if (cuisine != null) _cuisine = cuisine;
      if (deliveryFee != null) _deliveryFee = deliveryFee;
      if (minOrder != null) _minOrder = minOrder;
      if (isVeg != null) _isVeg = isVeg;
      if (address != null) _address = address;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .get();
      _userName = doc.data()?['name'] as String? ?? email.split('@').first;
      _status = doc.data()?['status'] as String? ?? 'pending';

      final rDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(cred.user!.uid)
          .get();
      final rData = rDoc.data();
      _restaurantName = rData?['name'] as String? ?? 'My Restaurant';
      _isRestaurantOpen = rData?['isOpen'] as bool? ?? true;
      _description = rData?['description'] as String? ?? '';
      _coverImageUrl = rData?['coverImageUrl'] as String? ?? '';
      _restaurantImages = List<String>.from(rData?['imageUrls'] ?? []);
      _phone = rData?['phone'] as String? ?? '';
      _defaultPrepTime = rData?['defaultPrepTime'] as int? ?? 20;
      _deliveryRadius = (rData?['deliveryRadius'] ?? 5.0).toDouble();
      _payoutUpi = rData?['payoutUpi'] as String? ?? '';

      _cuisine = rData?['cuisine'] as String? ?? '';
      _deliveryFee = (rData?['deliveryFee'] ?? 0.0).toDouble();
      _minOrder = (rData?['minOrder'] ?? 0.0).toDouble();
      _isVeg = rData?['isVeg'] as bool? ?? false;
      _address = rData?['address'] as String? ?? '';

      _isLoggedIn = true;
    } on FirebaseAuthException catch (e) {
      _isLoggedIn = false;
      _errorMessage = _friendlyError(e.code);
    } catch (e) {
      _isLoggedIn = false;
      _errorMessage = 'Something went wrong. Please try again.';
    }
    _isLoading = false;
    notifyListeners();
    return _isLoggedIn;
  }

  Future<bool> signup({
    required String name,
    required String restaurantName,
    required String email,
    required String password,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> imageUrls,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;

      // Save user info
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'restaurant',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save restaurant details
      await FirebaseFirestore.instance.collection('restaurants').doc(uid).set({
        'id': uid,
        'ownerId': uid,
        'name': restaurantName,
        'email': email,
        'phone': phone,
        'address': address,
        'location': {'lat': latitude, 'lng': longitude},
        'imageUrls': imageUrls,
        'commission': 10,
        'isOpen': true,
        'walletBalance': 0.0,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _userName = name;
      _restaurantName = restaurantName;
      _status = 'pending';
      _isLoggedIn = true;
    } on FirebaseAuthException catch (e) {
      _isLoggedIn = false;
      _errorMessage = _friendlyError(e.code);
    } catch (e) {
      _isLoggedIn = false;
      _errorMessage = 'Something went wrong. Please try again.';
    }
    _isLoading = false;
    notifyListeners();
    return _isLoggedIn;
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _isLoggedIn = false;
    _userName = '';
    _restaurantName = '';
    notifyListeners();
  }

  Future<void> syncFromFirebase(dynamic user) async {
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        _isLoggedIn = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _userName = doc.data()?['name'] as String? ?? '';
      _status = doc.data()?['status'] as String? ?? 'pending';

      final rDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid)
          .get();
      final rData = rDoc.data();
      _restaurantName = rData?['name'] as String? ?? '';
      _isRestaurantOpen = rData?['isOpen'] as bool? ?? true;
      _description = rData?['description'] as String? ?? '';
      _coverImageUrl = rData?['coverImageUrl'] as String? ?? '';
      _restaurantImages = List<String>.from(rData?['imageUrls'] ?? []);
      _phone = rData?['phone'] as String? ?? '';
      _defaultPrepTime = rData?['defaultPrepTime'] as int? ?? 20;
      _deliveryRadius = (rData?['deliveryRadius'] ?? 5.0).toDouble();
      _payoutUpi = rData?['payoutUpi'] as String? ?? '';

      _cuisine = rData?['cuisine'] as String? ?? '';
      _deliveryFee = (rData?['deliveryFee'] ?? 0.0).toDouble();
      _minOrder = (rData?['minOrder'] ?? 0.0).toDouble();
      _isVeg = rData?['isVeg'] as bool? ?? false;
      _address = rData?['address'] as String? ?? '';

      _isLoggedIn = true;
    } catch (e) {
      debugPrint('Sync Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
