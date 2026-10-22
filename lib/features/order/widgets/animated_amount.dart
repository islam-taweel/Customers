import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';

/// مبلغ يتحرك رقمه بسلاسة من القيمة السابقة إلى الجديدة (الإجمالي الحي).
class AnimatedAmount extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// عملة المبلغ (null = الشيكل)
  final String? currency;

  const AnimatedAmount({
    super.key,
    required this.value,
    this.style,
    this.textAlign,
    this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(
        formatAmount(v, currency: currency),
        style: style,
        textAlign: textAlign,
        textDirection: TextDirection.ltr,
      ),
    );
  }
}
