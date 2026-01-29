import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData.light();
  return base.copyWith(
    useMaterial3: false,
    scaffoldBackgroundColor: AppColors.page,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primaryBlue,
      secondary: AppColors.primaryRed,
      background: AppColors.page,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: base.textTheme.copyWith(
      headlineSmall: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: const TextStyle(
        color: AppColors.textPrimary,
      ),
      bodySmall: const TextStyle(
        color: AppColors.textSecondary,
      ),
    ),
  );
}
