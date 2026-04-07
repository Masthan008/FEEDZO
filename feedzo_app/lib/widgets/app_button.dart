import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final IconData? icon;
  final double? width;
  final Color? color;
  final bool useGradient;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.icon,
    this.width,
    this.color,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          );

    if (outlined) {
      return SizedBox(
        width: width,
        child: OutlinedButton(
          onPressed: isLoading
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed?.call();
                },
          style: OutlinedButton.styleFrom(
            foregroundColor: color ?? AppColors.primary,
            side: BorderSide(color: color ?? AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: AppShape.medium),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: child,
        ),
      );
    }

    if (useGradient) {
      return SizedBox(
        width: width,
        height: 54,
        child: GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onPressed?.call();
                },
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: AppShape.medium,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onPressed?.call();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
        ),
        child: child,
      ),
    );
  }
}
