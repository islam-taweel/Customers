import 'package:flutter/widgets.dart';

/// يُجبر كل الـ widgets تحت [context] على إعادة البناء.
/// نحتاجه عند تغيير اللغة لأن النصوص تُقرأ من AppStrings وليس من InheritedWidget.
void rebuildAllChildren(BuildContext context) {
  void rebuild(Element element) {
    element.markNeedsBuild();
    element.visitChildren(rebuild);
  }

  (context as Element).visitChildren(rebuild);
}
