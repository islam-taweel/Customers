import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/visit_strings.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/erp_customer.dart';
import '../../../data/models/visit_models.dart';
import '../../customers/widgets/confirm_dialog.dart';
import '../controllers/visits_controller.dart';

/// يفتح نموذج موعد جديد أو تعديل [existing]. تعديل موعد ملغى أو منجز يحتاج
/// تأكيدًا أولًا. [day]: يوم الموعد الجديد (اليوم المحدد في التقويم). يعيد true إن حُفظ.
Future<bool> openVisitForm(
  BuildContext context, {
  Visit? existing,
  DateTime? day,
}) async {
  if (existing != null && (existing.isCancelled || existing.isCompleted)) {
    final ok = await ConfirmDialog.show(
      context,
      title: VisitStrings.editClosedTitle(VisitStrings.status(existing.status)),
      message: VisitStrings.editClosedMessage,
      confirmLabel: VisitStrings.editAnyway,
      icon: Icons.edit_calendar_outlined,
    );
    if (!ok || !context.mounted) return false;
  }
  final factory = context.read<VisitsControllerFactory>();
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<VisitFormController>(
        create: (_) => factory.form(existing: existing, day: day),
        child: const VisitFormScreen(),
      ),
    ),
  );
  return saved == true;
}

/// إنشاء موعد زيارة بين المندوب والعميل أو تعديله: العميل، التاريخ والوقت،
/// التكرار الأسبوعي (الأيام وتاريخ النهاية)، والملاحظات.
class VisitFormScreen extends StatelessWidget {
  const VisitFormScreen({super.key});

  Future<void> _save(BuildContext context) async {
    final c = context.read<VisitFormController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final error = await c.save();
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), duration: const Duration(seconds: 6)),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(c.isEdit ? VisitStrings.updated : VisitStrings.created),
      ),
    );
    navigator.pop(true);
  }

  Future<void> _pickCustomer(BuildContext context) async {
    final c = context.read<VisitFormController>();
    final picked = await showModalBottomSheet<ErpCustomer>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: c,
        child: const _CustomerPicker(),
      ),
    );
    if (picked != null) c.setCustomer(picked);
  }

  Future<void> _pickDate(BuildContext context, {bool till = false}) async {
    final c = context.read<VisitFormController>();
    final now = DateTime.now();
    final initial = till ? (c.repeatTill ?? c.date) : c.date;
    final first = till ? c.date : DateTime(now.year - 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    till ? c.setRepeatTill(picked) : c.setDate(picked);
  }

  Future<void> _pickTime(BuildContext context, {bool end = false}) async {
    final c = context.read<VisitFormController>();
    final minutes = end ? (c.endMinutes ?? c.startMinutes + 60) : c.startMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60),
    );
    if (picked == null) return;
    final value = picked.hour * 60 + picked.minute;
    end ? c.setEnd(value) : c.setStart(value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<VisitFormController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    String time(int m) =>
        loc.formatTimeOfDay(TimeOfDay(hour: m ~/ 60, minute: m % 60));

    final customerText = c.customer?.name ??
        (c.loadingVisit || c.customersLoading
            ? VisitStrings.loadingCustomers
            : VisitStrings.chooseCustomer);

    return Scaffold(
      appBar: AppBar(
        title: Text(c.isEdit ? VisitStrings.editVisit : VisitStrings.newVisit),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (c.isEdit && c.existing!.repeats)
            Card(
              color: scheme.tertiaryContainer,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(Icons.info_outline,
                    color: scheme.onTertiaryContainer),
                title: Text(
                  VisitStrings.seriesNote,
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
            ),

          // العميل
          _Field(
            label: VisitStrings.customer,
            icon: Icons.person_outline,
            value: customerText,
            placeholder: c.customer == null,
            onTap: c.saving ? null : () => _pickCustomer(context),
          ),
          if (c.customersError != null && c.customers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      c.customersError!,
                      style: TextStyle(color: scheme.error, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    tooltip: AppStrings.retry,
                    onPressed: c.loadCustomers,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // التاريخ والوقت
          _Field(
            label: VisitStrings.date,
            icon: Icons.calendar_today_outlined,
            value: '${VisitStrings.weekday(c.date.weekday)}  ${loc.formatMediumDate(c.date)}',
            onTap: c.saving ? null : () => _pickDate(context),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: VisitStrings.startTime,
                  icon: Icons.schedule,
                  value: time(c.startMinutes),
                  onTap: c.saving ? null : () => _pickTime(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  label: VisitStrings.endTime,
                  icon: Icons.schedule_outlined,
                  value: c.endMinutes == null ? '—' : time(c.endMinutes!),
                  error: c.endMinutes != null && c.endMinutes! <= c.startMinutes
                      ? VisitStrings.endBeforeStart
                      : null,
                  onTap: c.saving ? null : () => _pickTime(context, end: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // التكرار الأسبوعي
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  value: c.weekly,
                  onChanged: c.saving ? null : c.setWeekly,
                  secondary: const Icon(Icons.repeat),
                  title: Text(VisitStrings.weekly),
                  subtitle: c.weekly ? Text(VisitStrings.weeklyHint) : null,
                ),
                if (c.weekly)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final d in const [6, 7, 1, 2, 3, 4, 5])
                          FilterChip(
                            label: Text(VisitStrings.weekday(d)),
                            selected: c.weekdays.contains(d),
                            onSelected: c.saving || d == c.date.weekday
                                ? null
                                : (_) => c.toggleWeekday(d),
                          ),
                      ],
                    ),
                  ),
                if (c.weekly)
                  ListTile(
                    leading: const Icon(Icons.event_repeat_outlined),
                    title: Text(VisitStrings.repeatTill),
                    subtitle: Text(
                      c.repeatTill == null
                          ? VisitStrings.noEndDate
                          : loc.formatMediumDate(c.repeatTill!),
                    ),
                    onTap: c.saving ? null : () => _pickDate(context, till: true),
                    trailing: c.repeatTill == null
                        ? const Icon(Icons.chevron_right)
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => c.setRepeatTill(null),
                          ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // الملاحظات
          TextFormField(
            initialValue: _plain(c.notes),
            minLines: 2,
            maxLines: 5,
            onChanged: (v) => c.notes = v,
            decoration: InputDecoration(
              labelText: VisitStrings.notes,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: c.saving ? null : () => _save(context),
            icon: c.saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(VisitStrings.save),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }

  /// الوصف في ERPNext قد يكون HTML (محرر النص)
  static String _plain(String html) => html
      .replaceAll(RegExp(r'<br\s*/?>|</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .trim();
}

/// حقل للضغط (يفتح منتقيًا) بشكل حقل إدخال
class _Field extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool placeholder;
  final String? error;
  final VoidCallback? onTap;

  const _Field({
    required this.label,
    required this.icon,
    required this.value,
    this.placeholder = false,
    this.error,
    this.onTap,
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
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: placeholder ? TextStyle(color: scheme.onSurfaceVariant) : null,
        ),
      ),
    );
  }
}

/// اختيار العميل مع البحث
class _CustomerPicker extends StatefulWidget {
  const _CustomerPicker();

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.watch<VisitFormController>();
    final list = c.filterCustomers(_query);

    Widget body;
    if (c.customersLoading && c.customers.isEmpty) {
      body = LoadingView(message: VisitStrings.loadingCustomers);
    } else if (c.customersError != null && c.customers.isEmpty) {
      body = ErrorView(message: c.customersError!, onRetry: c.loadCustomers);
    } else if (list.isEmpty) {
      body = Center(child: Text(VisitStrings.noCustomers));
    } else {
      body = ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final cu = list[i];
          return ListTile(
            leading: CircleAvatar(
              child: Text(cu.name.isEmpty ? '?' : cu.name.characters.first),
            ),
            title: Text(cu.name),
            subtitle: Text(
              cu.phone.isEmpty ? cu.id : '${cu.id}  •  ${cu.phone}',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
            ),
            selected: cu.id == c.customer?.id,
            onTap: () => Navigator.of(context).pop(cu),
          );
        },
      );
    }

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: VisitStrings.searchCustomer,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
