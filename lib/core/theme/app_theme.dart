import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ثيم التطبيق (Material 3).
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.seed,
      );
}