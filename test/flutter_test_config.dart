import 'dart:async';

import 'package:customer/app/translations/app_translations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// (R7) يُشغَّل قبل كل ملف اختبار: نفس ترجمات التطبيق (lib/app/translations)
/// والعربية افتراضيًا كما في main()، فتظهر النصوص الحقيقية لا مفاتيحها.
///
/// تُعاد قبل **كل** اختبار لأن `Get.reset()` (في tearDown الاختبارات) يستدعي
/// `Get.clearTranslations()`. التطبيق نفسه لا يستدعي Get.reset أبدًا.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    Get.addTranslations(AppTranslations().keys);
    Get.locale = AppTranslations.defaultLocale;
  });
  await testMain();
}
