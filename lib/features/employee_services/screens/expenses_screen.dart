import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ess_strings.dart';
import '../../../core/constants/visit_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/palestine_time.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/expense_models.dart';
import '../../../data/repositories/erp_employee_repository.dart';
import '../controllers/expenses_controller.dart';
import '../employee_service.dart';

const _green = Color(0xFF2E7D32);
const _orange = Color(0xFFEF6C00);

/// مصاريفي: طلبات مصاريف الموظف الحالي فقط من ERPNext (تُحدَّث عند الفتح)،
/// وزر «إضافة مصروف» (النوع، المبلغ، التاريخ، الوصف، صورة الإيصال، وربط
/// اختياري بسلفة مفتوحة). عرض وتقديم فقط: لا موافقة ولا اعتماد ولا دفع.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late final ExpensesController _c;

  @override
  void initState() {
    super.initState();
    // متحكم مستقل للشاشة: يُنشأ عند فتحها ويُحذف عند إغلاقها
    _c = Get.put(ExpensesController(context.read<ErpEmployeeRepository>()));
  }

  @override
  void dispose() {
    Get.delete<ExpensesController>();
    super.dispose();
  }

  String _message(Object e) {
    if (e is EmployeeNotLinkedException) return EssStrings.notLinked;
    if (e is ErpApiException && e.type == ErpErrorType.forbidden) {
      return EssStrings.noPermission;
    }
    return describeError(e, fallback: EssStrings.expensesLoadFailed);
  }

  Future<void> _openForm() async {
    final messenger = ScaffoldMessenger.of(context);
    final warning = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ExpenseSheet(controller: _c),
    );
    if (warning == null) return; // أُغلقت دون إرسال
    messenger.showSnackBar(
      SnackBar(
        content: Text(warning.isEmpty ? EssStrings.expenseSent : warning),
        duration: Duration(seconds: warning.isEmpty ? 3 : 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(EmployeeService.expenses.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Obx(
            () => _c.loading.value && _c.claims.isNotEmpty
                ? const LinearProgressIndicator(minHeight: 2)
                : const SizedBox(height: 2),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: Text(EssStrings.addExpense),
      ),
      body: Obx(() {
        final list = _c.claims.toList();
        if (_c.loading.value && list.isEmpty) {
          return LoadingView(message: EssStrings.loadingExpenses);
        }
        final error = _c.error.value;
        if (error != null && list.isEmpty) {
          return ErrorView(message: _message(error), onRetry: _c.load);
        }
        return RefreshIndicator(
          onRefresh: _c.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        EssStrings.expenseApprovalNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyView(
                    icon: Icons.receipt_long_outlined,
                    title: EssStrings.noExpenses,
                    message: EssStrings.noExpensesHint,
                  ),
                )
              else
                for (final e in list) _ExpenseCard(claim: e),
            ],
          ),
        );
      }),
    );
  }
}

/// اسم نوع المصروف للعرض: مواصلات/وجبات بلغة التطبيق، وإلا الاسم كما في ERPNext
String _typeLabel(String erpName) {
  if (ExpenseKind.transport.matches(erpName)) return EssStrings.transport;
  if (ExpenseKind.meals.matches(erpName)) return EssStrings.meals;
  return erpName;
}

/// طلب مصروف سابق: النوع، المبلغ، التاريخ، رقم الطلب، الحالة
class _ExpenseCard extends StatelessWidget {
  final ExpenseClaimSummary claim;

  const _ExpenseCard({required this.claim});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final e = claim;
    final date = e.expenseDate ?? e.postingDate;

    final (color, icon, label) = switch (e.status) {
      ExpenseStatus.draft => (
        _orange,
        Icons.edit_note,
        EssStrings.expenseStatusDraft,
      ),
      ExpenseStatus.approved => (
        scheme.tertiary,
        Icons.thumb_up_alt_outlined,
        EssStrings.expenseStatusApproved,
      ),
      ExpenseStatus.submitted => (
        scheme.primary,
        Icons.verified_outlined,
        EssStrings.expenseStatusSubmitted,
      ),
      ExpenseStatus.paid => (
        _green,
        Icons.payments_outlined,
        EssStrings.expenseStatusPaid,
      ),
      ExpenseStatus.rejected => (
        scheme.error,
        Icons.cancel_outlined,
        EssStrings.expenseStatusRejected,
      ),
      ExpenseStatus.cancelled => (
        scheme.outline,
        Icons.block,
        EssStrings.expenseStatusCancelled,
      ),
    };

    final typeIcon = ExpenseKind.transport.matches(e.expenseType)
        ? Icons.directions_bus_outlined
        : ExpenseKind.meals.matches(e.expenseType)
        ? Icons.restaurant_outlined
        : Icons.receipt_long_outlined;

    final card = Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: scheme.primary.withValues(alpha: 0.1),
              child: Icon(typeIcon, color: scheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.expenseType.isEmpty
                              ? EssStrings.expenses
                              : _typeLabel(e.expenseType),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        formatAmount(
                          e.amount,
                          currency: displayCurrency(e.currency),
                        ),
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (date != null) loc.formatMediumDate(date),
                      e.name,
                    ].join('  •  '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (e.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      e.description.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 15, color: color),
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
            ),
          ],
        ),
      ),
    );

    return e.status == ExpenseStatus.cancelled
        ? Opacity(opacity: 0.55, child: card)
        : card;
  }
}

/// نموذج المصروف. يعيد عند الإرسال '' (نجح) أو تحذير رفع الإيصال، و null عند
/// الإغلاق دون إرسال.
class _ExpenseSheet extends StatefulWidget {
  final ExpensesController controller;

  const _ExpenseSheet({required this.controller});

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  ExpenseKind? _kind;
  DateTime _date = PalestineTime.today();
  OpenAdvance? _advance;
  Uint8List? _receipt;
  String _receiptName = 'receipt.jpg';
  bool _tried = false;

  ExpensesController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    // أول نوع معرّف في ERPNext
    for (final k in ExpenseKind.values) {
      if (_c.types.containsKey(k)) {
        _kind = k;
        break;
      }
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = PalestineTime.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(today.year - 1),
      // لا تاريخ في المستقبل
      lastDate: today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // صورة مصغّرة تكفي لقراءة الإيصال وتُرفع بسرعة
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _receipt = bytes;
        _receiptName = file.name.isEmpty ? 'receipt.jpg' : file.name;
      });
    } catch (e) {
      debugPrint('ExpenseSheet pick photo failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(EssStrings.photoFailed)));
    }
  }

  Future<void> _send() async {
    setState(() => _tried = true);
    if (!_formKey.currentState!.validate() || _kind == null) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await _c.submit(
      kind: _kind!,
      amount: parseAmount(_amount.text) ?? 0,
      date: _date,
      description: _notes.text,
      advance: _advance,
      receipt: _receipt,
      receiptName: _receiptName,
    );
    if (!mounted) return;
    if (result.error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.error!),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
    navigator.pop(result.warning ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Form(
          key: _formKey,
          child: Obx(() {
            final types = _c.types;
            final advances = _c.openAdvances.toList();
            final amount = parseAmount(_amount.text) ?? 0;
            final adv = _advance;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  EssStrings.newExpense,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),

                // نوع المصروف: مواصلات أو وجبات
                Text(EssStrings.expenseType, style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                SegmentedButton<ExpenseKind>(
                  emptySelectionAllowed: true,
                  segments: [
                    ButtonSegment(
                      value: ExpenseKind.transport,
                      icon: const Icon(Icons.directions_bus_outlined),
                      label: Text(EssStrings.transport),
                      enabled: types.containsKey(ExpenseKind.transport),
                    ),
                    ButtonSegment(
                      value: ExpenseKind.meals,
                      icon: const Icon(Icons.restaurant_outlined),
                      label: Text(EssStrings.meals),
                      enabled: types.containsKey(ExpenseKind.meals),
                    ),
                  ],
                  selected: {?_kind},
                  onSelectionChanged: (s) =>
                      setState(() => _kind = s.isEmpty ? _kind : s.first),
                ),
                if (types.length < ExpenseKind.values.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      EssStrings.typeMissing,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  )
                else if (_tried && _kind == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      EssStrings.requiredField,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),

                // المبلغ والتاريخ
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: EssStrings.expenseAmount,
                          prefixIcon: const Icon(Icons.payments_outlined),
                          suffixText: '₪',
                          border: const OutlineInputBorder(),
                          errorMaxLines: 2,
                        ),
                        validator: (v) => ExpensesController.validateAmount(
                          parseAmount(v ?? ''),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: EssStrings.expenseDate,
                            prefixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                            border: const OutlineInputBorder(),
                            errorText: ExpensesController.validateDate(_date),
                          ),
                          child: Text(
                            '${VisitStrings.weekday(_date.weekday)} ${loc.formatShortDate(_date)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // الوصف
                TextFormField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: EssStrings.expenseNotes,
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.edit_note),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // صورة الإيصال
                Text(EssStrings.receipt, style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                if (_receipt != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _receipt!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      PositionedDirectional(
                        top: 6,
                        end: 6,
                        child: IconButton.filledTonal(
                          tooltip: EssStrings.removePhoto,
                          onPressed: () => setState(() => _receipt = null),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    EssStrings.noReceipt,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(EssStrings.takePhoto),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(EssStrings.fromGallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // الربط بسلفة مفتوحة (اختياري)
                if (advances.isEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          EssStrings.noOpenAdvances,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    initialValue: adv?.name ?? '',
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: EssStrings.linkAdvance,
                      prefixIcon: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(EssStrings.noAdvanceLink),
                      ),
                      for (final a in advances)
                        DropdownMenuItem(
                          value: a.name,
                          child: Text(
                            EssStrings.advanceOption(
                              a.name,
                              formatAmount(a.unclaimedAmount),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _advance = advances
                          .where((a) => a.name == v)
                          .cast<OpenAdvance?>()
                          .firstWhere((_) => true, orElse: () => null);
                    }),
                  ),
                  if (adv != null && amount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        EssStrings.advanceDeduction(
                          formatAmount(
                            amount < adv.unclaimedAmount
                                ? amount
                                : adv.unclaimedAmount,
                          ),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _c.sending.value ? null : _send,
                  icon: _c.sending.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(EssStrings.sendExpense),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
