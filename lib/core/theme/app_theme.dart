import 'package:flutter/material.dart';

/// ثيم التطبيق (Material 3) من لون أساسي وسطوع.
class AppTheme {
  AppTheme._();

  /// fidelity: يبقى اللون الأساسي قريبًا من اللون المختار بدل تليينه
  static ThemeData build(Color seed, Brightness brightness) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: brightness,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
      );
}
