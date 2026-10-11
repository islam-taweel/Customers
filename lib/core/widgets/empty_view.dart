import 'package:flutter/material.dart';

import 'state_message.dart';

/// حالة القائمة الفارغة: رسالة واضحة، وزر اختياري لإجراء مناسب
/// (مثل «إضافة أول عميل»). الزر يظهر فقط إذا حُدِّد [actionLabel] و[onAction] معًا.
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.actionIcon = Icons.add,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      actionIcon: actionIcon,
      onAction: onAction,
    );
  }
}