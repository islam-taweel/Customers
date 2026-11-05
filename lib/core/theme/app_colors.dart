import 'package:flutter/material.dart';

/// ألوان الثيم المتاحة (اللوحة «professional — tuned»). البنفسجي للوضع الداكن،
/// السماوي للفاتح، والبقية لخيار «مخصص».
enum ThemeColor {
  green(Color(0xFF00C853)),
  teal(Color(0xFF40A18B)),
  sky(Color(0xFF3F99BE)),
  blue(Color(0xFF3582E4)),
  indigo(Color(0xFF7361E5)),
  violet(Color(0xFF9C43E5)),
  rose(Color(0xFFE94494)),
  red(Color(0xFFEA4735)),
  orange(Color(0xFFC57938)),
  gold(Color(0xFFD8B84D));

  const ThemeColor(this.color);
  final Color color;

  /// ألوان خيار «مخصص»: كل اللوحة عدا لوني الوضعين الداكن والفاتح
  static List<ThemeColor> get customChoices => [
        for (final c in values)
          if (c != violet && c != sky) c,
      ];

  static ThemeColor fromName(String? name, ThemeColor fallback) =>
      values.firstWhere((c) => c.name == name, orElse: () => fallback);
}

/// الألوان الدلالية للتطبيق: أحمر للدين، أخضر للدفعة، رمادي للمسدد.
class AppColors {
  AppColors._();

  static const Color debt = Color(0xFFD32F2F);
  static const Color payment = Color(0xFF388E3C);
  static const Color settled = Color(0xFF757575);

  /// لون زر واتساب
  static const Color whatsapp = Color(0xFF128C7E);

  /// لون الرصيد: موجب = مستحق على العميل، سالب = له رصيد، صفر = مسدد
  static Color forBalance(double balance) {
    if (balance > 0) return debt;
    if (balance < 0) return payment;
    return settled;
  }
}
