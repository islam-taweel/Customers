import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ess_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/leave_models.dart';
import '../../../data/repositories/erp_employee_repository.dart';
import '../../customers/widgets/confirm_dialog.dart';
import '../controllers/leaves_controller.dart';
import '../employee_service.dart';

const _green = Color(0xFF2E7D32);
const _orange = Color(0xFFEF6C00);

/// إجازاتي من ERPNext: أرصدة كل نوع، نموذج طلب إجازة (عدد الأيام يُحسب
/// تلقائيًا، وتنبيه أثر الإجازة على الراتب)، والطلبات السابقة بحالاتها.
class LeavesScreen extends StatelessWidget {
  const LeavesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LeavesController>(
      create: (ctx) => LeavesController(ctx.read<ErpEmployeeRepository>()),
      child: const _LeavesView(),
    );
  }
}

class _LeavesView extends StatelessWidget {
  const _LeavesView();

  String _message(Object e) {
    if (e is EmployeeNotLinkedException) return EssStrings.notLinked;
    if (e is ErpApiException && e.type == ErpErrorType.forbidden) {
      return EssStrings.noPermission;
    }
    return describeError(e, fallback: EssStrings.leavesLoadFailed);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LeavesController>();
    final theme = Theme.of(context);

    Widget body;
    if (c.loading && c.details.types.isEmpty && c.requests.isEmpty) {
      body = LoadingView(message: EssStrings.loadingLeaves);
    } else if (c.error != null && c.details.types.isEmpty) {
      body = ErrorView(message: _message(c.error!), onRetry: c.load);
    } else {
      body = RefreshIndicator(
        onRefresh: c.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // أولًا: الأرصدة
            Text(
              EssStrings.balances,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _Balances(details: c.details),
            const SizedBox(height: 20),
            // ثانيًا: نموذج الطلب
            const _LeaveForm(),
            const SizedBox(height: 20),
            // ثالثًا: الطلبات السابقة
            Text(
              EssStrings.leaveHistory,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (c.requests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    EssStrings.noLeaveRequests,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              for (final r in c.requests) _RequestCard(request: r),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(EmployeeService.leaves.title),
        bottom: c.loading && c.details.types.isNotEmpty
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: body,
    );
  }
}

/// بطاقة لكل نوع مخصص (المتبقي بارز، والإجمالي والمأخوذ والمعلّق)، ثم الأنواع
/// بدون راتب
class _Balances extends StatelessWidget {
  final LeaveDetails details;

  const _Balances({required this.details});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String n(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

    if (details.balances.isEmpty && details.withoutPayTypes.isEmpty) {
      return Text(
        EssStrings.noBalances,
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    }

    final cards = <Widget>[
      for (final b in details.balances)
        _BalanceCard(
          title: b.leaveType,
          icon: _iconFor(b.leaveType),
          color: b.remaining > 0 ? scheme.primary : scheme.error,
          value: n(b.remaining),
          valueLabel: EssStrings.remaining,
          detail: EssStrings.balanceDetail(n(b.total), n(b.taken), n(b.pending)),
          progress: b.total > 0 ? (b.remaining / b.total).clamp(0, 1) : 0,
        ),
      for (final t in details.withoutPayTypes)
        if (details.balanceOf(t) == null)
          _BalanceCard(
            title: t,
            icon: Icons.money_off_outlined,
            color: _orange,
            value: '—',
            valueLabel: EssStrings.withoutPay,
            detail: EssStrings.noBalanceLimit,
          ),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 600 ? 3 : 2;
        final width = (box.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final c in cards) SizedBox(width: width, child: c)],
        );
      },
    );
  }

  /// أيقونة تقريبية حسب اسم النوع (الأسماء تختلف بين المواقع)
  static IconData _iconFor(String type) {
    final t = type.toLowerCase();
    if (t.contains('sick') || t.contains('مرض')) {
      return Icons.medical_services_outlined;
    }
    if (t.contains('without pay') || t.contains('بدون')) {
      return Icons.money_off_outlined;
    }
    if (t.contains('annual') ||
        t.contains('privilege') ||
        t.contains('سنو')) {
      return Icons.beach_access_outlined;
    }
    return Icons.event_available_outlined;
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String value;
  final String valueLabel;
  final String detail;
  final double? progress;

  const _BalanceCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
    required this.valueLabel,
    required this.detail,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(valueLabel, style: theme.textTheme.bodySmall),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveForm extends StatefulWidget {
  const _LeaveForm();

  @override
  State<_LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends State<_LeaveForm> {
  final _reason = TextEditingController();
  bool _tried = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool start}) async {
    final c = context.read<LeavesController>();
    final now = DateTime.now();
    final initial = start ? (c.from ?? now) : (c.to ?? c.from ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    start ? c.setFrom(picked) : c.setTo(picked);
  }

  Future<void> _submit() async {
    final c = context.read<LeavesController>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _tried = true);
    c.reason = _reason.text;
    // الإجازة بدون راتب: تنبيه الخصم من الراتب وتأكيد قبل الإرسال
    if (c.isWithoutPay && c.validate() == null) {
      final ok = await ConfirmDialog.show(
        context,
        title: EssStrings.lwpConfirmTitle,
        message: EssStrings.lwpConfirmMessage(
          c.days == null ? '—' : EssStrings.daysValue(c.days!),
        ),
        confirmLabel: EssStrings.sendAnyway,
        icon: Icons.money_off_outlined,
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    final error = await c.submit();
    if (!mounted) return;
    if (error == null) {
      _reason.clear();
      setState(() => _tried = false);
      FocusScope.of(context).unfocus();
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? EssStrings.leaveSent),
        duration: Duration(seconds: error == null ? 3 : 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LeavesController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    String? req(bool missing) =>
        _tried && missing ? EssStrings.requiredField : null;

    Widget dateField(String label, DateTime? value, bool start, String? error) =>
        InkWell(
          onTap: c.sending ? null : () => _pick(start: start),
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              border: const OutlineInputBorder(),
              errorText: error,
              errorMaxLines: 2,
            ),
            child: Text(
              value == null ? EssStrings.chooseDate : loc.formatMediumDate(value),
              style: value == null
                  ? TextStyle(color: scheme.onSurfaceVariant)
                  : null,
            ),
          ),
        );

    final warningColor = c.isWithoutPay ? scheme.error : _orange;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              EssStrings.newLeave,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: ValueKey('type-${c.type}'),
              initialValue: c.type,
              isExpanded: true,
              items: [
                for (final t in c.details.types)
                  DropdownMenuItem(
                    value: t,
                    child: Text(
                      c.details.isWithoutPay(t)
                          ? '$t  (${EssStrings.withoutPay})'
                          : t,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: c.sending ? null : c.setType,
              decoration: InputDecoration(
                labelText: EssStrings.leaveType,
                hintText: EssStrings.chooseLeaveType,
                prefixIcon: const Icon(Icons.category_outlined),
                border: const OutlineInputBorder(),
                errorText: req(c.type == null),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: dateField(
                    EssStrings.fromDate,
                    c.from,
                    true,
                    req(c.from == null),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: dateField(
                    EssStrings.toDate,
                    c.to,
                    false,
                    c.endBeforeStart
                        ? EssStrings.endBeforeStart
                        : req(c.to == null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // عدد الأيام: تلقائي
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.functions, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(EssStrings.daysCount),
                        if (c.daysFromErp)
                          Text(
                            EssStrings.daysByErp,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (c.countingDays)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      c.days == null ? '—' : EssStrings.daysValue(c.days!),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              minLines: 2,
              maxLines: 4,
              enabled: !c.sending,
              onChanged: (v) {
                c.reason = v;
                if (_tried) setState(() {});
              },
              decoration: InputDecoration(
                labelText: EssStrings.leaveReason,
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.edit_note),
                border: const OutlineInputBorder(),
                errorText: req(_reason.text.trim().isEmpty),
              ),
            ),
            const SizedBox(height: 12),

            // تنبيه أثر الإجازة على الراتب
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: warningColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: warningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.isWithoutPay
                          ? EssStrings.salaryWarningLwp
                          : EssStrings.salaryWarning,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: c.sending || c.endBeforeStart ? null : _submit,
              icon: c.sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(EssStrings.submitRequest),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// طلب سابق: النوع، الفترة، عدد الأيام، تاريخ التقديم، الحالة
class _RequestCard extends StatelessWidget {
  final LeaveRequest request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final r = request;
    final (color, icon, label) = switch (r.status) {
      LeaveRequestStatus.pending => (
          _orange,
          Icons.hourglass_top,
          EssStrings.statusPending,
        ),
      LeaveRequestStatus.approved => (
          _green,
          Icons.check_circle_outline,
          EssStrings.statusApproved,
        ),
      LeaveRequestStatus.rejected => (
          scheme.error,
          Icons.cancel_outlined,
          EssStrings.statusRejected,
        ),
      LeaveRequestStatus.cancelled => (
          scheme.outline,
          Icons.block,
          EssStrings.statusCancelled,
        ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.leaveType,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.date_range_outlined,
                    size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    EssStrings.period(
                      loc.formatMediumDate(r.from),
                      loc.formatMediumDate(r.to),
                    ),
                  ),
                ),
                Text(
                  EssStrings.daysValue(r.days),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (r.reason.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                r.reason.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (r.postedOn != null) ...[
              const SizedBox(height: 4),
              Text(
                EssStrings.submittedOn(loc.formatMediumDate(r.postedOn!)),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
