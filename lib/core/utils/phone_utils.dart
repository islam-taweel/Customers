import '../constants/app_constants.dart';
import 'formatters.dart';
import 'validators.dart';

/// تحويل الهاتف من الصيغة المحلية 05XXXXXXXX إلى الصيغة الدولية 9705XXXXXXXX
/// (بلا + وبلا صفر البداية)، وهي الصيغة التي يفهمها واتساب.
///
/// مثال: `0599123456` ← `970599123456`
/// تُرجع null إذا لم يطابق الرقم الصيغة المحلية الصحيحة (10 أرقام تبدأ بـ 05).
String? toInternationalPhone(String localPhone) {
  if (Validators.phone(localPhone) != null) return null;

  final digits = normalizeDigits(localPhone.trim());
  return '${AppConstants.phoneCountryCode}${digits.substring(1)}';
}