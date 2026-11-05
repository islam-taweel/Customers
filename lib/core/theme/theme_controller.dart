import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'app_theme.dart';

/// أوضاع الثيم: داكن (بنفسجي)، فاتح (سماوي)، مخصص (لون يختاره المستخدم).
enum AppThemeMode { dark, light, custom }

/// يحمل وضع الثيم ولون «مخصص» ويحفظهما في الجهاز (نفس نمط [LanguageController]).
class ThemeController extends ChangeNotifier {
  ThemeController._(this._mode, this._customColor);

  static const _modeKey = 'app_theme_mode';
  static const _colorKey = 'app_theme_custom_color';

  AppThemeMode _mode;
  ThemeColor _customColor;

  AppThemeMode get mode => _mode;
  ThemeColor get customColor => _customColor;

  /// اللون الأساسي الفعلي بحسب الوضع
  ThemeColor get activeColor => switch (_mode) {
        AppThemeMode.dark => ThemeColor.violet,
        AppThemeMode.light => ThemeColor.sky,
        AppThemeMode.custom => _customColor,
      };

  ThemeData get theme => AppTheme.build(
        activeColor.color,
        _mode == AppThemeMode.dark ? Brightness.dark : Brightness.light,
      );

  /// يقرأ الثيم المحفوظ (الفاتح افتراضيًا). أي فشل في القراءة يُتجاهل.
  static Future<ThemeController> load() async {
    var mode = AppThemeMode.light;
    var color = ThemeColor.customChoices.first;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_modeKey);
      mode = AppThemeMode.values.firstWhere(
        (m) => m.name == savedMode,
        orElse: () => AppThemeMode.light,
      );
      color = ThemeColor.fromName(prefs.getString(_colorKey), color);
      if (!ThemeColor.customChoices.contains(color)) {
        color = ThemeColor.customChoices.first;
      }
    } catch (e) {
      debugPrint('ThemeController: تعذّرت قراءة الثيم المحفوظ: $e');
    }
    return ThemeController._(mode, color);
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _save(_modeKey, mode.name);
  }

  /// اختيار لون يحوّل الثيم إلى «مخصص» تلقائيًا
  Future<void> setCustomColor(ThemeColor color) async {
    if (!ThemeColor.customChoices.contains(color)) return;
    if (color == _customColor && _mode == AppThemeMode.custom) return;
    _customColor = color;
    _mode = AppThemeMode.custom;
    notifyListeners();
    await _save(_colorKey, color.name);
    await _save(_modeKey, AppThemeMode.custom.name);
  }

  Future<void> _save(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('ThemeController: تعذّر حفظ الثيم: $e');
    }
  }
}
