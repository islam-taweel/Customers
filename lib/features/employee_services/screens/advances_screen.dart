import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ess_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/advance_models.dart';
import '../../../data/repositories/erp_employee_repository.dart';
import '../controllers/advances_controller.dart';
import '../employee_service.dart';

const _green = Color(0xFF2E7D32);
const _orange = Color(0xFFEF6C00);

/// سلفي: كل سلف الموظف المسجّل دخوله من ERPNext (تُحدَّث عند الفتح)، وزر لطلب
/// سلفة جديدة (المبلغ والغرض). عرض فقط: لا موافقة ولا دفع ولا إلغاء.
class AdvancesScreen extends StatefulWidget {
  const AdvancesScreen({super.key});

  @override
  State<AdvancesScreen> createState() => _AdvancesScreenState();
}

class _AdvancesScreenState extends State<AdvancesScreen> {
  late final AdvancesController _c;

  @override
  void initState() {
    super.initState();
    // متحكم مستقل للشاشة: يُنشأ عند فتحها ويُحذف عند إغلاقها
    _c = Get.put(AdvancesController(context.read<ErpEmployeeRepository>()));
  }

  @override
  void dispose() {
    Get.delete<AdvancesController>();
    super.dispose();
  }

  String _message(Object e) {
    if (e is EmployeeNotLinkedException) return EssStrings.notLinked;
    if (e is ErpApiException && e.type == ErpErrorType.forbidden) {
      return EssStrings.noPermission;
    }
    return describeError(e, fallback: EssStrings.advancesLoadFailed);
  }

  Future<void> _openRequest() async {
    final messenger = ScaffoldMessenger.of(context);
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RequestSheet(controller: _c),
    );
    if (sent == true) {
      messenger.showSnackBar(SnackBar(content: Text(EssStrings.advanceSent)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(EmployeeService.advances.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Obx(
            () => _c.loading.value && _c.advances.isNotEmpty
                ? const LinearProgressIndicator(minHeight: 2)
                : const SizedBox(height: 2),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRequest,
        icon: const Icon(Icons.add),
        label: Text(EssStrings.requestAdvance),
      ),
      body: Obx(() {
        final list = _c.advances.toList();
        if (_c.loading.value && list.isEmpty) {
          return LoadingView(message: EssStrings.loadingAdvances);
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
              // تنبيه: الموافقة والدفع من الموارد البشرية
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
                        EssStrings.advanceApprovalNote,
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
                    icon: Icons.account_balance_wallet_outlined,
                    title: EssStrings.noAdvances,
                    message: EssStrings.noAdvancesHint,
                  ),
                )
              else ...[
                _TotalCard(amount: _c.totalRemaining, list: list),
                const SizedBox(height: 16),
                for (final a in list) _AdvanceCard(advance: a),
              ],
            ],
          ),
        );
      }),
    );
  }
}

/// المتبقي مع الموظف من كل السلف (بعملة أول سلفة)
class _TotalCard extends StatelessWidget {
  final double amount;
  final List<EmployeeAdvance> list;

  const _TotalCard({required this.amount, required this.list});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currency = displayCurrency(list.first.currency);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: scheme.onPrimary.withValues(alpha: 0.2),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: scheme.onPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  EssStrings.advancesTotal,
                  style: TextStyle(
                    color: scheme.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  formatAmount(amount, currency: currency),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// سلفة واحدة: الرقم والتاريخ والغرض والحالة، ثم المبالغ الخمسة
class _AdvanceCard extends StatelessWidget {
  final EmployeeAdvance advance;

  const _AdvanceCard({required this.advance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);
    final a = advance;
    final currency = displayCurrency(a.currency);

    final (color, icon, label) = switch (a.status) {
      AdvanceStatus.pending => (
        _orange,
        Icons.hourglass_top,
        EssStrings.advStatusPending,
      ),
      AdvanceStatus.unpaid => (
        scheme.tertiary,
        Icons.schedule,
        EssStrings.advStatusUnpaid,
      ),
      AdvanceStatus.paid => (
        _green,
        Icons.payments_outlined,
        EssStrings.advStatusPaid,
      ),
      AdvanceStatus.claimed => (
        scheme.primary,
        Icons.task_alt,
        EssStrings.advStatusClaimed,
      ),
      AdvanceStatus.returned => (
        scheme.primary,
        Icons.undo,
        EssStrings.advStatusReturned,
      ),
      AdvanceStatus.partlyClaimedAndReturned => (
        scheme.primary,
        Icons.call_split,
        EssStrings.advStatusPartly,
      ),
      AdvanceStatus.cancelled => (
        scheme.outline,
        Icons.block,
        EssStrings.advStatusCancelled,
      ),
    };

    Widget amount(String title, double value, {bool strong = false}) =>
        Expanded(
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatAmount(value, currency: currency),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                    color: strong ? scheme.primary : null,
                  ),
                ),
              ),
            ],
          ),
        );

    final card = Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.start,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (a.postingDate != null)
                        Text(
                          loc.formatMediumDate(a.postingDate!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
            if (a.purpose.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                a.purpose.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                amount(EssStrings.originalAmount, a.advanceAmount),
                amount(EssStrings.paidAmount, a.paidAmount),
                amount(EssStrings.claimedAmount, a.claimedAmount),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                amount(EssStrings.returnedAmount, a.returnAmount),
                amount(
                  EssStrings.remainingAmount,
                  a.remainingAmount,
                  strong: true,
                ),
                amount(EssStrings.pendingAmount, a.pendingAmount),
              ],
            ),
          ],
        ),
      ),
    );

    // الملغاة باهتة حتى لا تبدو نشطة
    return a.status == AdvanceStatus.cancelled
        ? Opacity(opacity: 0.55, child: card)
        : card;
  }
}

/// نافذة طلب سلفة: المبلغ والغرض، مع التحقق قبل الإرسال
class _RequestSheet extends StatefulWidget {
  final AdvancesController controller;

  const _RequestSheet({required this.controller});

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _purpose = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _purpose.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final error = await widget.controller.submit(
      amount: parseAmount(_amount.text) ?? 0,
      purpose: _purpose.text,
    );
    if (!mounted) return;
    if (error == null) {
      navigator.pop(true);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(error), duration: const Duration(seconds: 6)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.controller;

    return Padding(
      // فوق لوحة المفاتيح
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                EssStrings.newAdvance,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: EssStrings.advanceAmountLabel,
                  prefixIcon: const Icon(Icons.payments_outlined),
                  suffixText: '₪',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    AdvancesController.validateAmount(parseAmount(v ?? '')),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _purpose,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: EssStrings.advancePurpose,
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.edit_note),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v?.trim() ?? '').isEmpty ? EssStrings.requiredField : null,
              ),
              const SizedBox(height: 16),
              Obx(
                () => FilledButton.icon(
                  onPressed: c.sending.value ? null : _send,
                  icon: c.sending.value
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
