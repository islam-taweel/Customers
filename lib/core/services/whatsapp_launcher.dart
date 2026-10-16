import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/phone_utils.dart';

/// نتيجة محاولة فتح واتساب.
enum WhatsAppResult {
  /// فُتح واتساب برسالة جاهزة
  opened,

  /// تطبيق واتساب غير مثبّت على الجهاز
  notInstalled,

  /// رقم العميل لا يمكن تحويله إلى الصيغة الدولية
  invalidPhone,

  /// لا يوجد مبلغ مستحق على العميل (لا معنى للتذكير)
  noDebt,

  /// خطأ غير متوقع أثناء الفتح
  failed,
}

/// نتيجة محاولة فتح رابط واحد (داخلية).
enum _Attempt { opened, unavailable, error }

/// يفتح واتساب مباشرة على محادثة رقم معيّن برسالة جاهزة، عبر `url_launcher`.
///
/// لا يرمي استثناءات أبدًا: كل خطأ يتحول إلى [WhatsAppResult] تتصرف الواجهة
/// بحسبها (رسالة عربية واضحة) بدل أن يتوقف التطبيق.
///
/// طريقة التحقق من وجود واتساب: **نحاول فتحه فعلًا** ونعتمد على نتيجة الفتح،
/// ولا نعتمد على `canLaunchUrl`. السبب أن `canLaunchUrl` يُرجع false لتطبيقات
/// موجودة إن لم يُصرَّح بها في `<queries>` (أندرويد 11+) أو `LSApplicationQueriesSchemes`
/// (iOS)، فيظهر «غير مثبّت» خطأً. أما `launchUrl` فلا يحتاج هذا الإعداد.
class WhatsAppLauncher {
  const WhatsAppLauncher();

  Future<WhatsAppResult> send({
    required String localPhone,
    required String message,
  }) async {
    // 05XXXXXXXX ← 9705XXXXXXXX
    final phone = toInternationalPhone(localPhone);
    if (phone == null) return WhatsAppResult.invalidPhone;

    final text = Uri.encodeComponent(message);

    // المحاولة 1: مخطط التطبيق المباشر (يفتح واتساب نفسه على محادثة الرقم)
    final direct = await _tryLaunch(
      Uri.parse('whatsapp://send?phone=$phone&text=$text'),
      LaunchMode.externalApplication,
    );
    if (direct == _Attempt.opened) return WhatsAppResult.opened;

    // المحاولة 2: رابط wa.me بشرط أن يتعامل معه تطبيق غير المتصفح (أي واتساب)،
    // فلا يفتح صفحة ويب بدل التطبيق.
    final link = await _tryLaunch(
      Uri.parse('https://wa.me/$phone?text=$text'),
      LaunchMode.externalNonBrowserApplication,
    );
    if (link == _Attempt.opened) return WhatsAppResult.opened;

    // لم تنجح أي محاولة: خطأ تقني، أو لا يوجد تطبيق يتعامل مع الرابط
    final hadError = direct == _Attempt.error || link == _Attempt.error;
    return hadError ? WhatsAppResult.failed : WhatsAppResult.notInstalled;
  }

  Future<_Attempt> _tryLaunch(Uri uri, LaunchMode mode) async {
    try {
      final launched = await launchUrl(uri, mode: mode);
      if (!launched)
        debugPrint(
          'WhatsApp: ${uri.scheme} لم يُفتح (لا يوجد تطبيق يتعامل معه)',
        );
      return launched ? _Attempt.opened : _Attempt.unavailable;
    } on PlatformException catch (e) {
      debugPrint(
        'WhatsApp: ${uri.scheme} PlatformException ${e.code}: ${e.message}',
      );
      return e.code == 'ACTIVITY_NOT_FOUND'
          ? _Attempt.unavailable
          : _Attempt.error;
    } catch (e) {
      debugPrint('WhatsApp: ${uri.scheme} فشل غير متوقع: $e');
      return _Attempt.error;
    }
  }
}
