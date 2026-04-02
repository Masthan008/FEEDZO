import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Phone OTP Authentication
class PhoneAuthService {
  final _auth = FirebaseAuth.instance;

  String? _verificationId;

  /// Step 1: Send OTP to phone number
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(PhoneAuthCredential)? onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber, // e.g. '+919876543210'
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) {
        // Auto-retrieval on Android
        onAutoVerified?.call(credential);
      },
      verificationFailed: (e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Step 2: Verify OTP entered by user
  Future<UserCredential?> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Convenience: verify using stored verificationId
  Future<UserCredential?> verifyWithStoredId(String smsCode) {
    if (_verificationId == null) throw Exception('No verification ID. Send OTP first.');
    return verifyOtp(verificationId: _verificationId!, smsCode: smsCode);
  }

  User? get currentUser => _auth.currentUser;
}
