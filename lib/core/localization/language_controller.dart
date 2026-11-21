import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اللغات المدعومة في التطبيق.
enum AppLanguage {
  arabic('ar'),
  english('en');

  const AppLanguage(this.code);
  final String code;

  Locale get locale => Locale(code);
  TextDirection get direction =>
      this == arabic ? TextDirection.rtl : TextDirection.ltr;

  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
    (l) => l.code == code,
    orElse: () => AppLanguage.arabic,
  );
}

/// يحمل اللغة الحالية ويحفظها في الجهاز، ويضبط لغة GetX (Get.locale) التي تقرؤها
/// الترجمات (lib/app/translations) و[AppStrings.isArabic].
class LanguageController extends ChangeNotifier {
  LanguageController._(this._language) {
    Get.locale = _language.locale;
  }

  static const _prefsKey = 'app_language';

  AppLanguage _language;
  AppLanguage get language => _language;
  Locale get locale => _language.locale;
  TextDirection get direction => _language.direction;

  /// يقرأ اللغة المحفوظة (العربية افتراضيًا). أي فشل في القراءة يُتجاهل.
  static Future<LanguageController> load() async {
    var language = AppLanguage.arabic;
    try {
      final prefs = await SharedPreferences.getInstance();
      language = AppLanguage.fromCode(prefs.getString(_prefsKey));
    } catch (e) {
      debugPrint('LanguageController: تعذّرت قراءة اللغة المحفوظة: $e');
    }
    return LanguageController._(language);
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    Get.locale = language.locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, language.code);
    } catch (e) {
      debugPrint('LanguageController: تعذّر حفظ اللغة: $e');
    }
  }
}
