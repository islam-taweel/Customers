import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import 'state_message.dart';

/// حالة الخطأ: رسالة واضحة بالعربية وزر لإعادة المحاولة.
/// [message] يجب أن تكون رسالة مفهومة للمستخدم (لا نص الاستثناء الخام).
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String? title;
  final String? retryLabel;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.title,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      icon: Icons.error_outline,
      iconColor: Theme.of(context).colorScheme.error,
      title: title ?? AppStrings.errorTitle,
      message: message,
      actionLabel: retryLabel ?? AppStrings.retry,
      actionIcon: Icons.refresh,
      onAction: onRetry,
    );
  }
}