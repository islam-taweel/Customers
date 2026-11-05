import 'package:flutter/material.dart';

import '../../../core/constants/visit_strings.dart';
import '../../../data/models/visit_models.dart';
import '../../customers/widgets/confirm_dialog.dart';
import '../controllers/visits_controller.dart';
import '../screens/visit_form_screen.dart';

enum _Action { edit, complete, reopen, cancel, delete }

/// بطاقة موعد: الوقت والعنوان والحالة والتكرار والملاحظات، وقائمة إجراءات.
/// الملغى يظهر باهتًا. [showDate]: يظهر التاريخ مع الوقت. دون [actions]
/// (الرئيسية) تُعرض البطاقة فقط بلا قائمة إجراءات.
class VisitCard extends StatelessWidget {
  final Visit visit;
  final VisitActions? actions;
  final bool showDate;

  const VisitCard({
    super.key,
    required this.visit,
    this.actions,
    this.showDate = false,
  });

  Future<void> _onAction(BuildContext context, _Action action) async {
    final actions = this.actions;
    if (actions == null) return;
    final messenger = ScaffoldMessenger.of(context);
    void show(String? error, String success) => messenger.showSnackBar(
          SnackBar(
            content: Text(error ?? success),
            duration: Duration(seconds: error == null ? 3 : 6),
          ),
        );

    switch (action) {
      case _Action.edit:
        final saved = await openVisitForm(context, existing: visit);
        if (saved) await actions.load();
      case _Action.complete:
        show(
          await actions.setStatus(visit, 'Completed'),
          VisitStrings.completed,
        );
      case _Action.reopen:
        show(await actions.setStatus(visit, 'Open'), VisitStrings.reopened);
      case _Action.cancel:
        // الإلغاء يحتاج تأكيدًا دائمًا
        final ok = await ConfirmDialog.show(
          context,
          title: VisitStrings.cancelTitle(visit.subject),
          message: VisitStrings.cancelMessage(visit.repeats),
          confirmLabel: VisitStrings.cancel,
          icon: Icons.event_busy_outlined,
          destructive: true,
        );
        if (!ok) return;
        show(
          await actions.setStatus(visit, 'Cancelled'),
          VisitStrings.cancelled,
        );
      case _Action.delete:
        final ok = await ConfirmDialog.show(
          context,
          title: VisitStrings.deleteTitle(visit.subject),
          message: VisitStrings.deleteMessage,
          confirmLabel: VisitStrings.delete,
          icon: Icons.delete_outline,
          destructive: true,
        );
        if (!ok) return;
        show(await actions.delete(visit), VisitStrings.deleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final v = visit;
    final busy = actions?.isBusy(v) ?? false;

    String time(DateTime d) =>
        loc.formatTimeOfDay(TimeOfDay.fromDateTime(d));
    final when = [
      if (showDate) loc.formatMediumDate(v.startsOn),
      v.endsOn == null
          ? time(v.startsOn)
          : '${time(v.startsOn)} – ${time(v.endsOn!)}',
    ].join('  •  ');

    final statusColor = switch (v.status) {
      'Completed' => scheme.primary,
      'Cancelled' => scheme.outline,
      'Closed' => scheme.outline,
      _ => scheme.tertiary,
    };

    final repeat = v.isWeekly
        ? '${VisitStrings.weeklyOn(
            (v.weekdays.toList()..sort()).map(VisitStrings.weekday).join('، '),
          )}  •  ${v.repeatTill == null ? VisitStrings.forever : VisitStrings.until(loc.formatMediumDate(v.repeatTill!))}'
        : null;

    final card = Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 10, actions == null ? 14 : 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Icon(
                  v.isCancelled
                      ? Icons.event_busy_outlined
                      : v.isCompleted
                          ? Icons.event_available_outlined
                          : Icons.event_outlined,
                  size: 20,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.subject,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration:
                          v.isCancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    when,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          VisitStrings.status(v.status),
                          style: TextStyle(fontSize: 12, color: statusColor),
                        ),
                      ),
                      if (repeat != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.repeat, size: 14,
                                color: scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                repeat,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (v.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _plain(v.description),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (actions != null)
              PopupMenuButton<_Action>(
                onSelected: (a) => _onAction(context, a),
                itemBuilder: (_) => [
                  _item(_Action.edit, Icons.edit_outlined, VisitStrings.edit),
                  if (!v.isClosed)
                    _item(_Action.complete, Icons.task_alt,
                        VisitStrings.complete),
                  if (v.isClosed)
                    _item(_Action.reopen, Icons.restart_alt,
                        VisitStrings.reopen),
                  if (!v.isCancelled)
                    _item(_Action.cancel, Icons.event_busy_outlined,
                        VisitStrings.cancel),
                  _item(_Action.delete, Icons.delete_outline,
                      VisitStrings.delete),
                ],
              ),
          ],
        ),
      ),
    );

    // الملغى باهت حتى لا يبدو نشطًا
    return v.isCancelled ? Opacity(opacity: 0.5, child: card) : card;
  }

  static PopupMenuItem<_Action> _item(_Action a, IconData icon, String label) =>
      PopupMenuItem(
        value: a,
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      );

  /// الوصف في ERPNext قد يكون HTML (محرر النص)
  static String _plain(String html) => html
      .replaceAll(RegExp(r'<br\s*/?>|</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .trim();
}
