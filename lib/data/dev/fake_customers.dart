import 'dart:math';

import '../models/customer.dart';

/// بيانات وهمية لأغراض التطوير والاختبار فقط.
/// لا يُستدعى إلا خلف `kDebugMode`، فيُحذف من نسخة الإنتاج عند البناء.

const _firstNames = [
  'أحمد', 'محمد', 'محمود', 'خالد', 'يوسف', 'عمر', 'علي', 'إبراهيم', 'سامي', 'رامي',
  'ماجد', 'نبيل', 'سليم', 'وسام', 'هاني', 'كريم', 'طارق', 'زياد', 'باسل', 'مروان',
];

const _lastNames = [
  'الطويل', 'النجار', 'حداد', 'شاهين', 'الخطيب', 'دويك', 'عابد', 'صالح', 'قاسم', 'منصور',
  'الحلبي', 'البرغوثي', 'الشريف', 'عيسى', 'سلامة', 'الأسمر', 'حمدان', 'ياسين', 'دراغمة', 'الكرمي',
];

/// يولّد [count] عميلًا بأسماء عربية عشوائية وأرقام هواتف وهمية.
/// الأسماء قد تتكرر عمدًا (400 تركيبة ممكنة)، وهذا مفيد لاختبار ثبات
/// الترتيب بين الصفحات عند تساوي الاسم.
List<Customer> generateFakeCustomers(int count, {int? seed}) {
  final random = Random(seed);
  return List.generate(count, (_) {
    final first = _firstNames[random.nextInt(_firstNames.length)];
    final last = _lastNames[random.nextInt(_lastNames.length)];
    final digits = List.generate(7, (_) => random.nextInt(10)).join();
    return Customer(name: '$first $last', phone: '059$digits');
  });
}