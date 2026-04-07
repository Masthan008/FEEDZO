import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/models/user_model.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      if (firebaseUser != null) {
        FirestoreService.watchUser(firebaseUser.uid).listen((userData) {
          _user = userData;
          notifyListeners();
        });
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyError(e.code);
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signup(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final newUser = UserModel(
        id: cred.user!.uid,
        name: name,
        email: email,
        phone: '',
      );
      await FirestoreService.saveUser(newUser);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyError(e.code);
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Check if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Create user document
        final newUser = UserModel(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'User',
          email: userCredential.user!.email ?? '',
          phone: userCredential.user!.phoneNumber ?? '',
          avatarUrl: userCredential.user!.photoURL ?? '',
        );
        await FirestoreService.saveUser(newUser);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyError(e.code);
    } catch (e) {
      _errorMessage = 'Google Sign-In failed. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Sign in with Apple (for iOS)
  Future<bool> signInWithApple() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final appleProvider = AppleAuthProvider();
      final userCredential = await FirebaseAuth.instance.signInWithProvider(appleProvider);

      // Check if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final newUser = UserModel(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'User',
          email: userCredential.user!.email ?? '',
          phone: userCredential.user!.phoneNumber ?? '',
          avatarUrl: userCredential.user!.photoURL ?? '',
        );
        await FirestoreService.saveUser(newUser);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyError(e.code);
    } catch (e) {
      _errorMessage = 'Apple Sign-In failed. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Enable guest mode for browsing without login
  Future<void> enableGuestMode() async {
    _isLoading = true;
    notifyListeners();
    
    // Create anonymous user
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (_) {
      // Silent fail - allow local guest mode
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
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
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email. Please sign in with your original method.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
