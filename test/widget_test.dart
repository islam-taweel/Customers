import 'package:flutter_test/flutter_test.dart';

import 'package:customer/core/utils/formatters.dart';

void main() {
  test('formatAmount يستخدم ₪ افتراضيًا ويقبل عملة أخرى', () {
    expect(formatAmount(1250.5), '1,250.50 ₪');
    expect(formatAmount(100, currency: 'USD'), '100 USD');
  });

  test('parseAmount يقبل الأرقام العربية والفاصلة', () {
    expect(parseAmount('١٢٫٥'), 12.5);
    expect(parseAmount('abc'), isNull);
  });
}
