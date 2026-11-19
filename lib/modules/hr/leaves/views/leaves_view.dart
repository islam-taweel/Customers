import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../features/customers/widgets/confirm_dialog.dart';
import '../../home/employee_service.dart';
import '../controllers/leaves_controller.dart';
import '../widgets/leave_widgets.dart';

/// إجازاتي من ERPNext: أرصدة كل نوع، نموذج طلب إجازة (عدد الأيام يُحسب
/// تلقائيًا، وتنبيه أثر الإجازة على الراتب)، والطلبات السابقة بحالاتها.
class LeavesScreen extends StatelessWidget {
  const LeavesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LeavesView();
  }
}

class _LeavesView extends StatelessWidget {
  const _LeavesView();

  @override
  Widget build(BuildContext context) =>
      GetBuilder<LeavesController>(builder: (c) => _build(context, c));

  Widget _build(BuildContext context, LeavesController c) {
    final theme = Theme.of(context);

    Widget body;
    if (c.loading && c.details.types.isEmpty && c.requests.isEmpty) {
      body = LoadingView(message: EssStrings.loadingLeaves);
    } else if (c.error != null && c.details.types.isEmpty) {
      body = ErrorView(message: c.errorMessage!, onRetry: c.load);
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
            Balances(details: c.details),
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
              for (final r in c.requests) RequestCard(request: r),
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
    final c = Get.find<LeavesController>();
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
    final c = Get.find<LeavesController>();
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
  Widget build(BuildContext context) =>
      GetBuilder<LeavesController>(builder: (c) => _build(context, c));

  Widget _build(BuildContext context, LeavesController c) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    String? req(bool missing) =>
        _tried && missing ? EssStrings.requiredField : null;

    Widget dateField(
      String label,
      DateTime? value,
      bool start,
      String? error,
    ) => InkWell(
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

    final warningColor = c.isWithoutPay ? scheme.error : orange;

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
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: warningColor,
                  ),
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
