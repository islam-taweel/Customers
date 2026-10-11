import 'package:flutter/material.dart';

/// الألوان الدلالية للتطبيق: أحمر للدين، أخضر للدفعة، رمادي للمسدد.
class AppColors {
  AppColors._();

  /// اللون الأساسي الذي يُشتق منه باقي الثيم
  static const Color seed = Colors.teal;

  static const Color debt = Color(0xFFD32F2F);
  static const Color payment = Color(0xFF388E3C);
  static const Color settled = Color(0xFF757575);

  /// لون الرصيد: موجب = مستحق على العميل، سالب = له رصيد، صفر = مسدد
  static Color forBalance(double balance) {
    if (balance > 0) return debt;
    if (balance < 0) return payment;
    return settled;
  }
}