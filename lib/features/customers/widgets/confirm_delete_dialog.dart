import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';

/// نافذة تأكيد حذف عميل. تُرجع true إن وافق المستخدم، وfalse إن ألغى
/// (أو ضغط خارج النافذة)، فيبقى العميل في مكانه.
class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDeleteDialog(),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.delete_outline, color: scheme.error, size: 32),
      title: const Text(AppStrings.deleteCustomerTitle),
      content: const Text(AppStrings.deleteCustomerMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: const Text(AppStrings.delete),
        ),
      ],
    );
  }
}