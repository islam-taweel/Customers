import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';

/// نافذة تأكيد عامة. تُرجع true إن وافق المستخدم، وfalse إن ألغى أو ضغط خارجها.
/// [destructive] = زر التأكيد أحمر (حذف).
class ConfirmDialog {
  ConfirmDialog._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    IconData icon = Icons.help_outline,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Icon(
            icon,
            size: 32,
            color: destructive ? scheme.error : scheme.primary,
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                    )
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }
}
