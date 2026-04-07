import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../services/phone_auth_service.dart';

/// Modern OTP verification screen with 6-box input and countdown timer
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final String role;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.role,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  final _svc = PhoneAuthService();

  bool _loading = false;
  String? _error;
  int _timerSeconds = 30;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final ctrl in _otpControllers) {
      ctrl.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _canResend = false;
    _timerSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerSeconds > 0) {
          _timerSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  bool get _isComplete => _otp.length == 6 && _otpControllers.every((c) => c.text.isNotEmpty);

  void _onOtpChanged(int index, String value) {
    setState(() => _error = null);

    if (value.isEmpty) {
      // Move to previous box on backspace
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }

    // Only take the last character if multiple entered
    final digit = value.substring(value.length - 1);
    if (!RegExp(r'[0-9]').hasMatch(digit)) {
      _otpControllers[index].text = '';
      return;
    }

    _otpControllers[index].text = digit;

    // Move to next box
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      // Last box filled, verify OTP
      _focusNodes[index].unfocus();
      if (_isComplete) {
        _verifyOtp();
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (!_isComplete) {
      setState(() => _error = 'Enter all 6 digits');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final cred = await _svc.verifyOtp(
        verificationId: widget.verificationId,
        smsCode: _otp,
      );

      if (cred != null && cred.user != null) {
        await _handleSignIn(cred.user!);
      } else {
        setState(() { _error = 'Invalid OTP. Please try again.'; _loading = false; });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Invalid OTP';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Verification failed. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _handleSignIn(User user) async {
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
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() { _loading = true; _error = null; });

    await _svc.sendOtp(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (newVerificationId) {
        setState(() {
          _loading = false;
        });
        _startTimer();
        // Clear previous OTP
        for (final ctrl in _otpControllers) {
          ctrl.clear();
        }
        _focusNodes[0].requestFocus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New OTP sent!'),
            backgroundColor: AppColors.statusDelivered,
            duration: Duration(seconds: 2),
          ),
        );
      },
      onError: (e) {
        setState(() {
          _error = e;
          _loading = false;
        });
      },
      onAutoVerified: (credential) async {
        try {
          final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
          if (userCred.user != null) {
            await _handleSignIn(userCred.user!);
          }
        } catch (_) {}
      },
    );
  }

  String get _maskedPhone {
    final phone = widget.phoneNumber;
    if (phone.length < 4) return phone;
    return '${phone.substring(0, phone.length - 4)}****';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter OTP',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'Enter the 6-digit code sent to ',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: _maskedPhone,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 6-box OTP Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => _OtpBox(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) => _onOtpChanged(index, value),
                    isLast: index == 5,
                  ),
                ),
              ),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading || !_isComplete ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Resend / Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive code? ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (!_canResend)
                    Text(
                      'Resend in 00:${_timerSeconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _loading ? null : _resendOtp,
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // WhatsApp option (placeholder)
              Center(
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('WhatsApp OTP coming soon!'),
                        backgroundColor: AppColors.info,
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: AppColors.statusDelivered,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Get OTP via WhatsApp',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.statusDelivered,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Edit phone number
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Change phone number',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onChanged;
  final bool isLast;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focusNode.hasFocus ? AppColors.primary : AppColors.border,
          width: focusNode.hasFocus ? 2 : 1,
        ),
        boxShadow: focusNode.hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(30),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: onChanged,
      ),
    );
  }
}
