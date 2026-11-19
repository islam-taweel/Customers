/// أسماء المسارات المسماة (R1). التنقل الحالي بـ Navigator.push و static route()
/// يبقى كما هو؛ هذه المسارات تُضاف بجانبه.
abstract class Routes {
  Routes._();

  /// البوابة: تعرض الدخول أو MainShell حسب الجلسة (المسار الجذري، لا يُغلق)
  static const gate = '/';
  static const login = '/login';
  static const home = '/home';
}
