import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> login(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String restaurantName,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> imageUrls,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    // Save user info
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'name': restaurantName,
      'email': email,
      'phone': phone,
      'role': 'restaurant',
      'status': 'pending', // Approval system
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Save restaurant details
    await _db.collection('restaurants').doc(uid).set({
      'id': uid,
      'ownerId': uid,
      'name': restaurantName,
      'email': email,
      'phone': phone,
      'address': address,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'imageUrls': imageUrls,
      'commission': 10, // Default 10%
      'isOpen': true,
      'walletBalance': 0.0,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  Future<void> logout() => _auth.signOut();
}
