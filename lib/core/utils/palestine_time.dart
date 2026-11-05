import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// وقت فلسطين (Asia/Hebron): UTC+2 شتاءً و UTC+3 صيفًا. كل الأوقات المرسلة إلى
/// ERPNext والمقارنة بها بهذا التوقيت، بصيغة «YYYY-MM-DD HH:MM:SS» بلا Z ولا إزاحة.
/// لا نضيف ساعات إلى UTC يدويًا: قاعدة بيانات المناطق الزمنية تعرف التوقيت الصيفي.
class PalestineTime {
  PalestineTime._();

  static tz.Location? _location;

  /// مرة واحدة عند بدء التطبيق.
  static void init() {
    if (_location != null) return;
    tzdata.initializeTimeZones();
    _location = tz.getLocation('Asia/Hebron');
  }

  static tz.Location get _loc {
    init();
    return _location!;
  }

  /// الوقت الحالي في فلسطين، كقيم «جدار» عادية (السنة والشهر واليوم والساعة)
  static DateTime now() {
    final t = tz.TZDateTime.now(_loc);
    return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
  }

  /// تاريخ اليوم في فلسطين (بلا وقت)
  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }

  /// «YYYY-MM-DD HH:MM:SS»
  static String format(DateTime d) =>
      '${date(d)} ${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

  /// «YYYY-MM-DD»
  static String date(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}
