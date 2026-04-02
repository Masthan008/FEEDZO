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
    required String name,
    required String phone,
    required String vehicle,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    await _db.collection('users').doc(cred.user!.uid).set({
      'id': cred.user!.uid, 'name': name, 'email': email,
      'phone': phone, 'role': 'driver',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('drivers').doc(cred.user!.uid).set({
      'id': cred.user!.uid, 'name': name, 'phone': phone,
      'vehicle': vehicle, 'status': 'available',
      'totalDeliveries': 0, 'rating': 0.0, 'totalEarnings': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<void> logout() => _auth.signOut();
}
