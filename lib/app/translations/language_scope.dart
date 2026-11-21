import 'package:flutter/widgets.dart';

import '../../core/localization/language_controller.dart';
import '../../core/localization/rebuild_all.dart';

/// (R7) نُقل كما هو من main.dart (كان _LanguageScope) ليُختبر مباشرة.
/// عند تغيّر اللغة نعيد بناء كل الشاشات المفتوحة،
/// لأن النصوص تُقرأ من AppStrings (وليس من InheritedWidget).
class LanguageScope extends StatefulWidget {
  final AppLanguage language;
  final Widget child;

  const LanguageScope({super.key, required this.language, required this.child});

  @override
  State<LanguageScope> createState() => LanguageScopeState();
}

class LanguageScopeState extends State<LanguageScope> {
  @override
  void didUpdateWidget(covariant LanguageScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) rebuildAllChildren(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
