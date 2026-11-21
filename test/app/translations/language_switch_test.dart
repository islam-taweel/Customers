import 'package:customer/app/translations/app_translations.dart';
import 'package:customer/app/translations/language_scope.dart';
import 'package:customer/core/constants/app_strings.dart';
import 'package:customer/core/constants/ess_strings.dart';
import 'package:customer/core/localization/language_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نفس تركيب DebtsApp في main.dart: GetMaterialApp بالترجمات، وGet.locale من
/// LanguageController، وLanguageScope + Directionality من اللغة الحالية.
Widget app(LanguageController language) =>
    ChangeNotifierProvider<LanguageController>.value(
      value: language,
      child: Consumer<LanguageController>(
        builder: (context, language, _) {
          Get.locale = language.locale;
          return GetMaterialApp(
            locale: language.locale,
            translations: AppTranslations(),
            fallbackLocale: AppTranslations.fallback,
            supportedLocales: AppTranslations.supported,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => LanguageScope(
              language: language.language,
              child: Directionality(
                textDirection: language.direction,
                child: child!,
              ),
            ),
            home: const _Screen(),
          );
        },
      ),
    );

class _Screen extends StatelessWidget {
  const _Screen();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text(AppStrings.retry, key: const Key('retry')),
        Text(EssStrings.section, key: const Key('ess')),
        Builder(
          builder: (c) =>
              Text('${Directionality.of(c)}', key: const Key('dir')),
        ),
      ],
    ),
  );
}

String text(WidgetTester t, String key) =>
    t.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  tearDown(() => Get.locale = AppTranslations.defaultLocale);

  testWidgets(
    'العربية افتراضيًا (RTL)، والتبديل للإنجليزية فورًا (LTR) ويُحفظ',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final language = await LanguageController.load();
      expect(language.language, AppLanguage.arabic, reason: 'الافتراضية');

      await tester.pumpWidget(app(language));
      await tester.pumpAndSettle();
      expect(text(tester, 'retry'), 'إعادة المحاولة');
      expect(text(tester, 'dir'), '${TextDirection.rtl}');
      final arabicEss = text(tester, 'ess');

      await tester.runAsync(() => language.setLanguage(AppLanguage.english));
      await tester.pumpAndSettle();
      expect(text(tester, 'retry'), 'Retry');
      expect(text(tester, 'dir'), '${TextDirection.ltr}');
      expect(text(tester, 'ess'), isNot(arabicEss), reason: 'كل الشاشات تُعاد');
      expect(AppStrings.isArabic, isFalse);

      // يُحفظ: التحميل التالي يبدأ بالإنجليزية
      final again = await tester.runAsync(LanguageController.load);
      expect(again!.language, AppLanguage.english);

      await tester.runAsync(() => language.setLanguage(AppLanguage.arabic));
      await tester.pumpAndSettle();
      expect(text(tester, 'retry'), 'إعادة المحاولة');
      expect(text(tester, 'dir'), '${TextDirection.rtl}');
    },
  );

  test('كل مفتاح موجود في الملفين (لا نص ناقص في إحدى اللغتين)', () {
    final keys = AppTranslations().keys;
    final ar = keys['ar']!.keys.toSet();
    final en = keys['en']!.keys.toSet();
    // الاستثناء الوحيد المقصود: رسالة تذكير واتساب للعميل بالعربية دائمًا
    // (كما كانت قبل R7)، فتُقرأ من ar.dart مباشرة ولا نسخة إنجليزية لها
    expect(ar.difference(en), {'app.whatsappDebtMessage'});
    expect(en.difference(ar), isEmpty);
    expect(ar.length, greaterThan(1200));
  });
}
