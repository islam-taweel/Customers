import 'package:flutter/widgets.dart' show Locale;
import 'package:get/get.dart';

import 'ar.dart';
import 'en.dart';

/// ترجمات التطبيق (GetX Translations).
///
/// - العربية هي اللغة الافتراضية ([fallback] و[defaultLocale]).
/// - النصوص نفسها في [arTranslations] و[enTranslations] فقط؛ الشاشات تقرؤها
///   عبر AppStrings/EssStrings/... (core/constants) التي تستدعي `'key'.tr`.
/// - الاتجاه (RTL/LTR) يضبطه DebtsApp من اللغة الحالية.
class AppTranslations extends Translations {
  static const defaultLocale = Locale('ar');
  static const fallback = Locale('ar');
  static const supported = [Locale('ar'), Locale('en')];

  @override
  Map<String, Map<String, String>> get keys => {
    'ar': arTranslations,
    'en': enTranslations,
  };
}
