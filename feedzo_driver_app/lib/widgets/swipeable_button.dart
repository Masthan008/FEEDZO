import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SwipeableButton extends StatefulWidget {
  final String text;
  final VoidCallback onSwipeComplete;
  final Color backgroundColor;
  final Color foregroundColor;

  const SwipeableButton({
    super.key,
    required this.text,
    required this.onSwipeComplete,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
  });

  @override
  State<SwipeableButton> createState() => _SwipeableButtonState();
}

class _SwipeableButtonState extends State<SwipeableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _swipeValue = 0.0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _controller.addListener(() {
      setState(() => _swipeValue = _controller.value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxSlide = maxWidth - 60; // 60 is knob width + padding

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: widget.backgroundColor.withValues(alpha: 0.15),
            borderRadius: AppShape.round,
            border: Border.all(
              color: widget.backgroundColor.withValues(alpha: 0.3),
            ),
          ),
          child: Stack(
            children: [
              // Background Text
              Center(
                child: Opacity(
                  opacity: 1.0 - (_swipeValue * 2).clamp(0.0, 1.0),
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      color: widget.backgroundColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // Animated Track Fill (Gradient)
              Container(
                width: 60 + (_swipeValue * maxSlide),
                height: 60,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: AppShape.round,
                ),
              ),

              // Knob
              Positioned(
                left: _swipeValue * maxSlide,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isCompleted) return;
                    setState(() {
                      _swipeValue += details.primaryDelta! / maxSlide;
                      _swipeValue = _swipeValue.clamp(0.0, 1.0);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isCompleted) return;
                    if (_swipeValue > 0.8) {
                      _isCompleted = true;
                      _controller.value = _swipeValue;
                      _controller.animateTo(1.0).then((_) {
                        widget.onSwipeComplete();
                      });
                    } else {
                      _controller.value = _swipeValue;
                      _controller.animateTo(0.0);
                    }
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 0),
                        )
                      ],
                    ),
                    child: Icon(
                      _isCompleted ? Icons.check_rounded : Icons.arrow_forward_ios_rounded,
                      color: widget.backgroundColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
