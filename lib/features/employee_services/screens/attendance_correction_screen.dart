import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ess_strings.dart';
import '../../../core/constants/visit_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/palestine_time.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/attendance_models.dart';
import '../../../data/repositories/erp_employee_repository.dart';
import '../controllers/correction_controller.dart';
import '../employee_service.dart';

/// «نسيت البصمة»: طلب حضور (Attendance Request) في ERPNext. نموذج الطلب
/// (التاريخ، نوع التصحيح، الوقت الصحيح، نوع الطلب، السبب، توضيحات) مع التحقق،
/// ثم طلباتي بحالاتها. لا أزرار موافقة أو رفض: ذلك من صلاحية الموارد البشرية.
class AttendanceCorrectionScreen extends StatelessWidget {
  const AttendanceCorrectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CorrectionController>(
      create: (ctx) => CorrectionController(ctx.read<ErpEmployeeRepository>()),
      child: const _CorrectionView(),
    );
  }
}

class _CorrectionView extends StatelessWidget {
  const _CorrectionView();

  String _message(Object e) {
    if (e is EmployeeNotLinkedException) return EssStrings.notLinked;
    if (e is ErpApiException && e.type == ErpErrorType.forbidden) {
      return EssStrings.noPermission;
    }
    return describeError(e, fallback: EssStrings.requestsLoadFailed);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CorrectionController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final requests = c.requests;

    Widget history;
    if (c.loading && requests.isEmpty) {
      history = SizedBox(
        height: 160,
        child: LoadingView(message: EssStrings.loadingRequests),
      );
    } else if (c.error != null && requests.isEmpty) {
      history = SizedBox(
        height: 260,
        child: ErrorView(message: _message(c.error!), onRetry: c.load),
      );
    } else if (requests.isEmpty) {
      history = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            EssStrings.noRequests,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    } else {
      history = Column(
        children: [for (final r in requests) _RequestCard(request: r)],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(EmployeeService.correction.title)),
      body: RefreshIndicator(
        onRefresh: c.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: scheme.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      EssStrings.requestApprovalNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _RequestForm(),
            const SizedBox(height: 20),
            Text(
              EssStrings.previousRequests,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            history,
          ],
        ),
      ),
    );
  }
}

class _RequestForm extends StatefulWidget {
  const _RequestForm();

  @override
  State<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<_RequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _date;
  CorrectionType _type = CorrectionType.forgotCheckIn;

  /// قيمة reason في ERPNext: On Duty أو Work From Home فقط
  String _kind = 'On Duty';
  TimeOfDay? _time;

  /// يظهر خطأ التاريخ والوقت بعد أول محاولة إرسال فقط
  bool _tried = false;

  @override
  void dispose() {
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = PalestineTime.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: DateTime(today.year - 1),
      // لا تصحيح لأيام لم تأتِ بعد
      lastDate: today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ??
          (_type == CorrectionType.forgotCheckIn
              ? const TimeOfDay(hour: 8, minute: 0)
              : const TimeOfDay(hour: 17, minute: 0)),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final c = context.read<CorrectionController>();
    final messenger = ScaffoldMessenger.of(context);
    final loc = MaterialLocalizations.of(context);
    setState(() => _tried = true);
    final fieldsOk = _formKey.currentState!.validate();
    if (!fieldsOk || _date == null || _time == null) return;

    final error = await c.submit(
      date: _date!,
      type: _type,
      // الوقت بصيغة 24 ساعة ليقرأه الموارد البشرية بلا لبس
      correctTime: loc.formatTimeOfDay(_time!, alwaysUse24HourFormat: true),
      reason: _kind,
      userReason: _reason.text,
      notes: _notes.text,
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? EssStrings.requestSent),
        duration: Duration(seconds: error == null ? 3 : 6),
      ),
    );
    if (error != null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _tried = false;
      _date = null;
      _time = null;
      _type = CorrectionType.forgotCheckIn;
      _kind = 'On Duty';
      _reason.clear();
      _notes.clear();
    });
    _formKey.currentState!.reset();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CorrectionController>();
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final isIn = _type == CorrectionType.forgotCheckIn;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                EssStrings.newRequest,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),

              // التاريخ
              _PickerField(
                label: EssStrings.requestDate,
                icon: Icons.calendar_today_outlined,
                value: _date == null
                    ? null
                    : '${VisitStrings.weekday(_date!.weekday)}  ${loc.formatMediumDate(_date!)}',
                hint: EssStrings.chooseDate,
                error: _tried && _date == null
                    ? EssStrings.requiredField
                    : (_date != null && c.hasPending(_date!)
                        ? EssStrings.pendingSameDay
                        : null),
                onTap: _pickDate,
              ),
              const SizedBox(height: 14),

              // نوع التصحيح
              Text(EssStrings.correctionType, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              SegmentedButton<CorrectionType>(
                segments: [
                  ButtonSegment(
                    value: CorrectionType.forgotCheckIn,
                    icon: const Icon(Icons.login),
                    label: Text(EssStrings.forgotCheckIn),
                  ),
                  ButtonSegment(
                    value: CorrectionType.forgotCheckOut,
                    icon: const Icon(Icons.logout),
                    label: Text(EssStrings.forgotCheckOut),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 14),

              // الوقت الصحيح
              _PickerField(
                label:
                    isIn ? EssStrings.correctInTime : EssStrings.correctOutTime,
                icon: Icons.schedule,
                value: _time == null ? null : loc.formatTimeOfDay(_time!),
                hint: EssStrings.chooseTime,
                error:
                    _tried && _time == null ? EssStrings.requiredField : null,
                onTap: _pickTime,
              ),
              const SizedBox(height: 14),

              // نوع الطلب في ERPNext
              Text(EssStrings.requestKind, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'On Duty',
                    icon: const Icon(Icons.work_outline),
                    label: Text(EssStrings.onDuty),
                  ),
                  ButtonSegment(
                    value: 'Work From Home',
                    icon: const Icon(Icons.home_work_outlined),
                    label: Text(EssStrings.workFromHome),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 14),

              // السبب
              TextFormField(
                controller: _reason,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: EssStrings.reason,
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.help_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (text.isEmpty) return EssStrings.requiredField;
                  if (text.length < 5) return EssStrings.reasonTooShort;
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // توضيحات إضافية
              TextFormField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: EssStrings.extraNotes,
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: c.sending ? null : _submit,
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
      ),
    );
  }
}

/// حقل للضغط يفتح منتقي التاريخ أو الوقت
class _PickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final String hint;
  final String? error;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.hint,
    required this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          errorText: error,
          errorMaxLines: 2,
        ),
        child: Text(
          value ?? hint,
          style:
              value == null ? TextStyle(color: scheme.onSurfaceVariant) : null,
        ),
      ),
    );
  }
}

/// طلب سابق: التاريخ، نوع التصحيح، نوع الطلب، الشرح، الحالة (للعرض فقط)
class _RequestCard extends StatelessWidget {
  final AttendanceRequestRecord request;

  const _RequestCard({required this.request});

  /// نوع التصحيح من أول سطر في الشرح (بأي من اللغتين)، null إن لم يُعرف
  static CorrectionType? _typeOf(String explanation) {
    final first = explanation.split('\n').first;
    if (first.contains('نسيان تسجيل الانصراف') ||
        first.contains('Forgot to check out')) {
      return CorrectionType.forgotCheckOut;
    }
    if (first.contains('نسيان تسجيل الحضور') ||
        first.contains('Forgot to check in')) {
      return CorrectionType.forgotCheckIn;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final r = request;

    final (color, icon, label) = switch (correctionStatusOf(r)) {
      CorrectionStatus.pending => (
          const Color(0xFFEF6C00),
          Icons.hourglass_top,
          EssStrings.statusPending,
        ),
      CorrectionStatus.approved => (
          const Color(0xFF2E7D32),
          Icons.check_circle_outline,
          EssStrings.statusApproved,
        ),
      CorrectionStatus.rejected => (
          scheme.error,
          Icons.cancel_outlined,
          EssStrings.statusRejected,
        ),
    };
    final type = _typeOf(r.explanation);
    final title = switch (type) {
      CorrectionType.forgotCheckIn => EssStrings.forgotCheckIn,
      CorrectionType.forgotCheckOut => EssStrings.forgotCheckOut,
      null => EssStrings.correction,
    };
    final kind =
        r.reason == 'Work From Home' ? EssStrings.workFromHome : EssStrings.onDuty;
    final sameDay = r.fromDate == r.toDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  switch (type) {
                    CorrectionType.forgotCheckIn => Icons.login,
                    CorrectionType.forgotCheckOut => Icons.logout,
                    null => Icons.edit_calendar_outlined,
                  },
                  size: 20,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
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
            Text(
              sameDay
                  ? '${VisitStrings.weekday(r.fromDate.weekday)}  ${loc.formatMediumDate(r.fromDate)}  •  $kind'
                  : '${EssStrings.period(loc.formatMediumDate(r.fromDate), loc.formatMediumDate(r.toDate))}  •  $kind',
              style: theme.textTheme.bodyMedium,
            ),
            if (r.explanation.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                r.explanation.trim(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              r.name,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
