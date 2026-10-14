import '../constants/app_strings.dart';
import 'formatters.dart';

/// دوال التحقق من المدخلات. كل دالة تُرجع null إن كانت القيمة صحيحة،
/// أو نص الخطأ الذي يُعرض أسفل الحقل. تُستخدم كـ `validator` في TextFormField،
/// وتُعاد في المتحكم كحماية ثانية.
class Validators {
  Validators._();

  /// 10 أرقام بالضبط، تبدأ بـ 05
  static final RegExp _phonePattern = RegExp(r'^05\d{8}$');

  /// الاسم مطلوب
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.nameRequired;
    return null;
  }

  /// الهاتف: مطلوب، 10 أرقام، يبدأ بـ 05 (تُقبل الأرقام العربية وتُحوَّل أولًا)
  static String? phone(String? value) {
    final v = normalizeDigits((value ?? '').trim());
    if (v.isEmpty) return AppStrings.phoneRequired;
    if (!_phonePattern.hasMatch(v)) return AppStrings.phoneInvalid;
    return null;
  }
}
