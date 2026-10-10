import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fundo em degradê com "bolhas" de luz, usado em todas as telas.
class NeonBackground extends StatelessWidget {
  const NeonBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.background),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _Glow(size: 260, color: AppColors.cyan, opacity: 0.45),
          ),
          Positioned(
            bottom: -120,
            left: -90,
            child: _Glow(size: 300, color: AppColors.orange, opacity: 0.40),
          ),
          Positioned(
            top: 220,
            left: -50,
            child: _Glow(size: 140, color: Colors.white, opacity: 0.12),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color, required this.opacity});

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
