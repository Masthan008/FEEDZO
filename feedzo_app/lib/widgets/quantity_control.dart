import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

class QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool compact;

  const QuantityControl({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 32.0;
    final fontSize = compact ? 13.0 : 15.0;

    if (quantity == 0) {
      return AddButton(onTap: onAdd, compact: compact);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppShape.small,
        boxShadow: AppShadows.primaryGlow(0.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(icon: Icons.remove, onTap: () {
            HapticFeedback.lightImpact();
            onRemove();
          }, size: size),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: child,
            ),
            child: Padding(
              key: ValueKey(quantity),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$quantity',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              ),
            ),
          ),
          _Btn(icon: Icons.add, onTap: () {
            HapticFeedback.lightImpact();
            onAdd();
          }, size: size),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _Btn({required this.icon, required this.onTap, required this.size});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppShape.small,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class AddButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool compact;

  const AddButton({super.key, required this.onTap, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppShape.small,
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Text(
          'ADD',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: compact ? 12 : 13,
          ),
        ),
      ),
    );
  }
}
