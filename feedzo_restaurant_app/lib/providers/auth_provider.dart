import 'dart:async';
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

  // Admin sync fields
  bool _isRestaurantOpen = true;
  bool _isApproved = false;
  String? _rejectionReason;
  double _commissionRate = 10.0;
  Map<String, dynamic>? _documents;
  Map<String, dynamic>? _autoOpenClose;
  
  // Firestore listeners
  StreamSubscription<DocumentSnapshot>? _restaurantListener;
  StreamSubscription<DocumentSnapshot>? _userListener;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String get userName => _userName;
  String get restaurantName => _restaurantName;
  String get status => _status;
  bool get isApproved => _isApproved;
  bool get isRestaurantOpen => _isRestaurantOpen;
  String? get rejectionReason => _rejectionReason;
  double get commissionRate => _commissionRate;
  Map<String, dynamic>? get documents => _documents;
  Map<String, dynamic>? get autoOpenClose => _autoOpenClose;
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
      _isApproved = rData?['isApproved'] as bool? ?? false;
      _rejectionReason = rData?['rejectionReason'] as String?;
      _commissionRate = (rData?['commission'] ?? 10.0).toDouble();
      _documents = rData?['documents'] as Map<String, dynamic>?;
      _autoOpenClose = rData?['autoOpenClose'] as Map<String, dynamic>?;
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
      
      // Start real-time listeners
      _startFirestoreListeners(cred.user!.uid);
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
    // Cancel listeners
    await _restaurantListener?.cancel();
    await _userListener?.cancel();
    _restaurantListener = null;
    _userListener = null;
    
    await FirebaseAuth.instance.signOut();
    _isLoggedIn = false;
    _userName = '';
    _restaurantName = '';
    notifyListeners();
  }
  
  // Real-time Firestore listeners for admin sync
  void _startFirestoreListeners(String uid) {
    // Listen to restaurant document changes
    _restaurantListener = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      
      final data = snapshot.data();
      if (data == null) return;
      
      bool hasChanges = false;
      
      // Sync isOpen status from admin
      final newIsOpen = data['isOpen'] as bool? ?? true;
      if (newIsOpen != _isRestaurantOpen) {
        _isRestaurantOpen = newIsOpen;
        hasChanges = true;
      }
      
      // Sync approval status
      final newIsApproved = data['isApproved'] as bool? ?? false;
      if (newIsApproved != _isApproved) {
        _isApproved = newIsApproved;
        hasChanges = true;
      }
      
      // Sync rejection reason
      final newRejectionReason = data['rejectionReason'] as String?;
      if (newRejectionReason != _rejectionReason) {
        _rejectionReason = newRejectionReason;
        hasChanges = true;
      }
      
      // Sync commission rate
      final rawCommission = data['commission'];
      final newCommission = (rawCommission ?? 10.0).toDouble();
      debugPrint('AuthProvider: Commission sync - raw: $rawCommission, parsed: $newCommission, current: $_commissionRate');
      if (newCommission != _commissionRate) {
        _commissionRate = newCommission;
        hasChanges = true;
        debugPrint('AuthProvider: Commission updated to $_commissionRate');
      }
      
      // Sync documents
      final newDocuments = data['documents'] as Map<String, dynamic>?;
      if (newDocuments?.toString() != _documents?.toString()) {
        _documents = newDocuments;
        hasChanges = true;
      }
      
      // Sync auto open/close
      final newAutoOpenClose = data['autoOpenClose'] as Map<String, dynamic>?;
      if (newAutoOpenClose?.toString() != _autoOpenClose?.toString()) {
        _autoOpenClose = newAutoOpenClose;
        hasChanges = true;
      }
      
      if (hasChanges) {
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Error in restaurant listener: $e');
    });
    
    // Listen to user document for status changes
    _userListener = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      
      final data = snapshot.data();
      if (data == null) return;
      
      final newStatus = data['status'] as String? ?? 'pending';
      if (newStatus != _status) {
        _status = newStatus;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Error in user listener: $e');
    });
  }
  
  @override
  void dispose() {
    _restaurantListener?.cancel();
    _userListener?.cancel();
    super.dispose();
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
      _isApproved = rData?['isApproved'] as bool? ?? false;
      _rejectionReason = rData?['rejectionReason'] as String?;
      _commissionRate = (rData?['commission'] ?? 10.0).toDouble();
      _documents = rData?['documents'] as Map<String, dynamic>?;
      _autoOpenClose = rData?['autoOpenClose'] as Map<String, dynamic>?;
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
      
      // Start real-time listeners
      _startFirestoreListeners(user.uid);
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
