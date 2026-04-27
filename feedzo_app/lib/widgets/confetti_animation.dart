import 'dart:math';
import 'package:flutter/material.dart';

/// Confetti animation widget for celebrations
/// Shows on order completion, achievements, etc.
class ConfettiAnimation extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final VoidCallback? onComplete;

  const ConfettiAnimation({
    super.key,
    required this.child,
    this.isActive = false,
    this.onComplete,
  });

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ConfettiAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _particles.clear();
    for (int i = 0; i < 50; i++) {
      _particles.add(ConfettiParticle(
        x: _random.nextDouble(),
        y: -0.1 - _random.nextDouble() * 0.3,
        color: [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
          Colors.pink,
        ][_random.nextInt(7)],
        size: 5 + _random.nextDouble() * 10,
        speed: 0.5 + _random.nextDouble() * 1.5,
        angle: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
      ));
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isActive)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: ConfettiPainter(
                  particles: _particles,
                  progress: _controller.value,
                ),
              );
            },
          ),
      ],
    );
  }
}

class ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double size;
  final double speed;
  double angle;
  final double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speed,
    required this.angle,
    required this.rotationSpeed,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final y = particle.y + particle.speed * progress;
      final x = particle.x + sin(progress * 4 + particle.angle) * 0.05;
      final opacity = 1 - (progress > 0.7 ? (progress - 0.7) / 0.3 : 0);

      if (y > 1.2) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(particle.angle + progress * particle.rotationSpeed * 10);

      // Draw confetti rectangle
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
