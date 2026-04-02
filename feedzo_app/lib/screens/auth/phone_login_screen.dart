import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../services/phone_auth_service.dart';

class PhoneLoginScreen extends StatefulWidget {
  final String role; // 'customer' | 'driver' | 'restaurant'
  const PhoneLoginScreen({super.key, this.role = 'customer'});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _svc = PhoneAuthService();

  bool _otpSent = false;
  bool _loading = false;
  String? _verificationId;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final formatted = phone.startsWith('+') ? phone : '+91$phone';
    await _svc.sendOtp(
      phoneNumber: formatted,
      onCodeSent: (id) {
        setState(() { _verificationId = id; _otpSent = true; _loading = false; });
      },
      onError: (e) => setState(() { _error = e; _loading = false; }),
      onAutoVerified: (credential) => _signInWithCredential(credential),
    );
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await _svc.verifyOtp(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );
      if (cred != null) await _handleSignIn(cred.user!);
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message ?? 'Invalid OTP'; _loading = false; });
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithCredential(credential);
      if (cred.user != null) await _handleSignIn(cred.user!);
    } catch (_) {}
  }

  Future<void> _handleSignIn(User user) async {
    // Check if user doc exists; if not, create with pending status
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'id': user.uid,
        'phone': user.phoneNumber,
        'role': widget.role,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    if (!mounted) return;
    setState(() => _loading = false);
    // Navigation handled by _AppRoot watching FirebaseAuth state
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Phone Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                _otpSent ? 'Enter OTP' : 'Verify Phone',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? 'Enter the 6-digit code sent to ${_phoneCtrl.text}'
                    : 'We\'ll send a one-time password to your phone',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                  child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],
              if (!_otpSent) ...[
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixText: '+91 ',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendOtp,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Send OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '6-digit OTP',
                    prefixIcon: Icon(Icons.lock_outline),
                    counterText: '',
                  ),
                  style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verifyOtp,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Verify OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : () => setState(() { _otpSent = false; _otpCtrl.clear(); }),
                    child: const Text('Change phone number', style: TextStyle(color: AppColors.primary)),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : _sendOtp,
                    child: const Text('Resend OTP', style: TextStyle(color: AppColors.primary)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
