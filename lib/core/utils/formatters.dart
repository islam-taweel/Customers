import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

/// تنسيق المبلغ مع فواصل الآلاف، مثال: 1,250.50 ₪
String formatAmount(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  final decimals = parts[1] == '00' ? '' : '.${parts[1]}';
  return '$intPart$decimals ${AppConstants.currencySymbol}';
}

/// تنسيق التاريخ والوقت، مثال: 2026/10/10 - 3:45 م
String formatDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final isPm = d.hour >= 12;
  var hour12 = d.hour % 12;
  if (hour12 == 0) hour12 = 12;
  return '${d.year}/${two(d.month)}/${two(d.day)} - '
      '$hour12:${two(d.minute)} ${isPm ? AppStrings.pm : AppStrings.am}';
}

/// تحويل الأرقام العربية/الهندية (٠١٢٣…) إلى أرقام لاتينية (0123…)
String normalizeDigits(String input) {
  const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
  var s = input;
  for (var i = 0; i < arabicDigits.length; i++) {
    s = s.replaceAll(arabicDigits[i], i.toString());
  }
  return s;
}

/// تحويل الأرقام العربية/الهندية إلى لاتينية وتوحيد الفاصلة العشرية،
/// ثم تحويل النص إلى رقم (أو null إذا كان غير صالح)
double? parseAmount(String input) {
  final s = normalizeDigits(input.trim())
      .replaceAll('٫', '.')
      .replaceAll(',', '.')
      .replaceAll('،', '.');
  return double.tryParse(s);
}