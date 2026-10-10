import 'package:flutter/material.dart';

/// Paleta "Neon Sunset": índigo profundo + violeta + magenta, com
/// destaques em ciano, laranja e verde-limão.
class AppColors {
  AppColors._();

  static const ink = Color(0xFF1B0B3A);
  static const indigo = Color(0xFF3A0CA3);
  static const violet = Color(0xFF7209B7);
  static const magenta = Color(0xFFF72585);
  static const cyan = Color(0xFF4CC9F0);
  static const orange = Color(0xFFFF9E00);
  static const lime = Color(0xFF80ED99);
  static const mint = Color(0xFF2EC4B6);
  static const mist = Color(0xFFF5EFFF);
  static const lavender = Color(0xFFE4D7FF);
  static const danger = Color(0xFFFF4D6D);

  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo, violet, magenta],
    stops: [0, 0.55, 1],
  );

  static const sunset = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [magenta, orange],
  );

  static const success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [mint, lime],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.violet,
        primary: AppColors.violet,
        secondary: AppColors.magenta,
      ),
    );

    OutlineInputBorder border(Color color, [double width = 0]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: width == 0
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.indigo,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.mist,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        prefixIconColor: AppColors.violet,
        labelStyle: const TextStyle(color: AppColors.violet),
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(AppColors.magenta, 2),
        errorBorder: border(AppColors.danger, 1.5),
        focusedErrorBorder: border(AppColors.danger, 2),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        actionTextColor: AppColors.orange,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.magenta,
      ),
    );
  }
}
