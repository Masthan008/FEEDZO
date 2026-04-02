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
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    await _db.collection('users').doc(cred.user!.uid).set({
      'id': cred.user!.uid, 'name': name, 'email': email,
      'phone': phone, 'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<void> logout() => _auth.signOut();
}
