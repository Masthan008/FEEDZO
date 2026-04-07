import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'phone_login_screen.dart';
import 'login_screen.dart';

/// Modern authentication gateway screen inspired by Zomato/Swiggy
/// Features full-screen background, social login options, and guest access
class AuthGatewayScreen extends StatelessWidget {
  const AuthGatewayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image - Replace with actual image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/auth_background.png'),
                fit: BoxFit.cover,
              ),
            ),
            // Fallback gradient when image not available
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(100),
                    Colors.black.withAlpha(180),
                    Colors.black.withAlpha(220),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Logo Section
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 60,
                    height: 60,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.local_fire_department_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Feedzo',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const Text(
                  'Delicious food, delivered fast',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),

                const Spacer(),

                // Bottom Sheet Style Content
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Headline
                      const Text(
                        'Login or Sign up',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Order your favorite food from the best restaurants',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Phone Button (Primary)
                      _SocialButton(
                        icon: Icons.phone_android_rounded,
                        label: 'Continue with Phone',
                        backgroundColor: AppColors.primary,
                        textColor: Colors.white,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PhoneLoginScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Google Button
                      _SocialButton(
                        icon: Icons.g_mobiledata_rounded,
                        label: 'Continue with Google',
                        backgroundColor: Colors.white,
                        textColor: AppColors.textPrimary,
                        borderColor: AppColors.border,
                        isLoading: auth.isLoading,
                        onTap: () async {
                          final success = await context.read<AuthProvider>().signInWithGoogle();
                          if (success && context.mounted) {
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Apple Button (iOS only)
                      if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                        _SocialButton(
                          icon: Icons.apple,
                          label: 'Continue with Apple',
                          backgroundColor: Colors.black,
                          textColor: Colors.white,
                          isLoading: auth.isLoading,
                          onTap: () async {
                            final success = await context.read<AuthProvider>().signInWithApple();
                            if (success && context.mounted) {
                              Navigator.of(context).popUntil((r) => r.isFirst);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.border,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.border,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Email Option
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          ),
                          child: const Text(
                            'Continue with Email',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Guest Option
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            await context.read<AuthProvider>().enableGuestMode();
                            if (context.mounted) {
                              Navigator.of(context).popUntil((r) => r.isFirst);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Continue as Guest',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Terms and Privacy
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text.rich(
                    TextSpan(
                      text: 'By continuing, you agree to our ',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms of Service',
                          style: const TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                          // TODO: Add Terms navigation
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                          // TODO: Add Privacy navigation
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;
  final bool isLoading;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null
              ? Border.all(color: borderColor!)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
