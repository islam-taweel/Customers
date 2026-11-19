import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../../../core/constants/visit_strings.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../home/employee_service.dart';
import '../../shared/models/employee_models.dart';
import '../controllers/punch_controller.dart';

/// تسجيل الحضور والانصراف في ERPNext (Employee Checkin) بتوقيت فلسطين: التاريخ
/// والوقت الحاليان، حالة الموظف من آخر بصمة، زرا IN و OUT (المتاح حسب آخر
/// بصمة)، أوقات اليوم ومدة العمل، مكان لعرض الموقع (دون إذن موقع أو GPS)،
/// وبصمات اليوم.
///
/// (R5) الحالة والساعة في [CheckinController] (PunchBinding)؛ الواجهة تعرض فقط.
class CheckinScreen extends StatelessWidget {
  const CheckinScreen({super.key});

  @override
  Widget build(BuildContext context) => const _CheckinView();
}

class _CheckinView extends StatefulWidget {
  const _CheckinView();

  @override
  State<_CheckinView> createState() => _CheckinViewState();
}

class _CheckinViewState extends State<_CheckinView> {
  Future<void> _act(bool isIn) async {
    final c = Get.find<CheckinController>();
    final messenger = ScaffoldMessenger.of(context);
    final error = await c.punch(isIn: isIn);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error ?? (isIn ? EssStrings.checkedIn : EssStrings.checkedOut),
          ),
          duration: Duration(seconds: error == null ? 3 : 6),
        ),
      );
  }

  /// GetBuilder: نفس نقاط التحديث السابقة (update)؛ Obx: الساعة كل ثانية
  @override
  Widget build(BuildContext context) => GetBuilder<CheckinController>(
    builder: (c) => Obx(() => _build(context, c, c.now.value)),
  );

  Widget _build(BuildContext context, CheckinController c, DateTime now) {
    if (c.loading && !c.hasLoaded) {
      return Scaffold(
        appBar: AppBar(title: Text(EmployeeService.checkin.title)),
        body: LoadingView(message: EssStrings.loadingPunches),
      );
    }
    if (c.error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(EmployeeService.checkin.title)),
        body: ErrorView(message: c.errorMessage!, onRetry: c.load),
      );
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);

    String clock(DateTime d) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
    }

    final (statusText, statusColor, statusIcon) = switch (c.status) {
      CheckinStatus.notCheckedIn => (
        EssStrings.statusNotCheckedIn,
        scheme.outline,
        Icons.hourglass_empty,
      ),
      CheckinStatus.onDuty => (
        EssStrings.statusOnDuty,
        const Color(0xFF2E7D32),
        Icons.work_history_outlined,
      ),
      CheckinStatus.finished => (
        EssStrings.statusFinished,
        scheme.primary,
        Icons.task_alt,
      ),
    };

    final worked = c.worked(now);

    return Scaffold(
      appBar: AppBar(title: Text(EmployeeService.checkin.title)),
      body: RefreshIndicator(
        onRefresh: c.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // تنبيه الوضع التجريبي
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: scheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      EssStrings.punchNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 1) التاريخ والوقت الحاليان + 2) الحالة
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '${VisitStrings.weekday(now.weekday)}  ${loc.formatMediumDate(now)}',
                    style: TextStyle(
                      color: scheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clock(now),
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 18, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3) و 4) زرا الحضور والانصراف
            Row(
              children: [
                Expanded(
                  child: _PunchButton(
                    label: EssStrings.checkIn,
                    code: EssStrings.inLabel,
                    icon: Icons.login,
                    color: const Color(0xFF2E7D32),
                    onPressed: c.canCheckIn ? () => _act(true) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PunchButton(
                    label: EssStrings.checkOut,
                    code: EssStrings.outLabel,
                    icon: Icons.logout,
                    color: scheme.error,
                    onPressed: c.canCheckOut ? () => _act(false) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 6) وقتا الحضور والانصراف ومدة العمل
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    _TimeCell(
                      label: EssStrings.checkInTime,
                      value: c.checkInAt == null ? '—' : clock(c.checkInAt!),
                    ),
                    _TimeCell(
                      label: EssStrings.checkOutTime,
                      value: c.checkOutAt == null ? '—' : clock(c.checkOutAt!),
                    ),
                    _TimeCell(
                      label: EssStrings.workedTime,
                      value: worked == null
                          ? '—'
                          : EssStrings.hoursMinutes(
                              worked.inHours,
                              worked.inMinutes % 60,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 8) مكان الموقع الجغرافي: لا إذن موقع ولا GPS
            Text(
              EssStrings.location,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 36,
                    color: scheme.outline,
                  ),
                  const SizedBox(height: 6),
                  Text(EssStrings.locationPlaceholder),
                  const SizedBox(height: 2),
                  Text(
                    EssStrings.locationNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 7) آخر عمليات التسجيل
            Text(
              EssStrings.todayPunches,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (c.log.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    EssStrings.noPunchesToday,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < c.log.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      _LogTile(record: c.log[i], clock: clock),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PunchButton extends StatelessWidget {
  final String label;
  final String code;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _PunchButton({
    required this.label,
    required this.code,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(
            code,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  final String label;
  final String value;

  const _TimeCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final EmployeeCheckin record;
  final String Function(DateTime) clock;

  const _LogTile({required this.record, required this.clock});

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final color = record.isIn
        ? const Color(0xFF2E7D32)
        : Theme.of(context).colorScheme.error;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          record.isIn ? Icons.login : Icons.logout,
          size: 18,
          color: color,
        ),
      ),
      title: Text(
        '${record.isIn ? EssStrings.inLabel : EssStrings.outLabel}  •  '
        '${record.isIn ? EssStrings.checkIn : EssStrings.checkOut}',
        style: TextStyle(fontWeight: FontWeight.w700, color: color),
      ),
      subtitle: Text(loc.formatMediumDate(record.time)),
      trailing: Text(
        clock(record.time),
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
