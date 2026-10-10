import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Logo desenhado em código: um "post-it" inclinado com uma checklist
/// colorida (nenhuma imagem externa é necessária).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 92});

  final double size;

  @override
  Widget build(BuildContext context) {
    final bar = size * 0.42;
    return Transform.rotate(
      angle: -0.14,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _row(size, bar, AppColors.violet, checked: true),
            _row(size, bar * 0.8, AppColors.cyan),
            _row(size, bar * 0.95, AppColors.magenta),
          ],
        ),
      ),
    );
  }

  Widget _row(double size, double width, Color color, {bool checked = false}) {
    final dot = size * 0.13;
    return Row(
      children: [
        Container(
          width: dot,
          height: dot,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: checked ? AppColors.sunset : null,
            color: checked ? null : color.withValues(alpha: 0.85),
          ),
          child: checked
              ? Icon(Icons.check_rounded, size: dot * 0.8, color: Colors.white)
              : null,
        ),
        SizedBox(width: size * 0.07),
        Container(
          width: width,
          height: size * 0.09,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size),
          ),
        ),
      ],
    );
  }
}
