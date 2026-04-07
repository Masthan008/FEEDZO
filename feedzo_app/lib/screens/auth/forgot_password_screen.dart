import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

/// Forgot password screen with email/phone reset options
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }

    setState(() { _loading = true; _error = null; _successMessage = null; });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _successMessage = 'Password reset link sent! Check your email inbox.';
        _loading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.code == 'user-not-found'
            ? 'No account found with this email address.'
            : 'Failed to send reset link. Please try again.';
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
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
                  color: AppColors.warning.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: AppColors.warning,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Success message
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Email Input
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                enabled: _successMessage == null,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 8),

              // Error message (if not shown in TextField)
              if (_error != null && _error != _emailCtrl.text) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
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
              ],

              const Spacer(),

              // Send Reset Link Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading || _successMessage != null ? null : _sendResetLink,
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
                      : Text(
                          _successMessage != null ? 'Email Sent!' : 'Send Reset Link',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Back to login
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Back to Login',
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
