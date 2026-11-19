import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/customers/widgets/confirm_dialog.dart';
import '../../statement/views/voucher_details_view.dart';
import '../controllers/customer_collections_controller.dart';
import '../models/payment_entry.dart';

/// تحت زر «إضافة دفعة»: تبويبا «مسودة» و«معتمدة» لدفعات العميل في ERPNext
/// (بما فيها المسجلة من الفواتير). المسودة: «اعتماد» و«إلغاء» و«تفاصيل الدفعة»؛
/// المعتمدة: «تفاصيل الدفعة».
///
/// الحالة في [CustomerCollectionsController] (وسم [tag] من مسار شاشة العمليات).
class PaymentsTabs extends StatefulWidget {
  final String tag;

  const PaymentsTabs({super.key, required this.tag});

  @override
  State<PaymentsTabs> createState() => _PaymentsTabsState();
}

class _PaymentsTabsState extends State<PaymentsTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  late final CustomerCollectionsController _c =
      Get.find<CustomerCollectionsController>(tag: widget.tag);

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final c = _c;
    final drafts = c.drafts;
    final approved = c.approved;
    final showingDrafts = _tabs.index == 0;
    final list = showingDrafts ? drafts : approved;

    Widget body;
    if (c.loading.value && drafts.isEmpty && approved.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (c.error.value != null && drafts.isEmpty && approved.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(c.error.value!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: c.load,
              icon: const Icon(Icons.refresh),
              label: Text(AppStrings.retry),
            ),
          ],
        ),
      );
    } else if (list.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            showingDrafts
                ? AppStrings.paymentsDraftEmpty
                : AppStrings.paymentsApprovedEmpty,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    } else {
      body = Column(
        children: [
          for (final p in list)
            _PaymentCard(payment: p, controller: c, busy: c.isBusy(p)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: AppStrings.paymentsDraftTab(drafts.length)),
            Tab(text: AppStrings.paymentsApprovedTab(approved.length)),
          ],
        ),
        if (c.loading.value) const LinearProgressIndicator(minHeight: 2),
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: body),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentEntrySummary payment;
  final CustomerCollectionsController controller;

  /// يُقرأ داخل Obx الأب فتتحدث البطاقة مع حالة «جارٍ»
  final bool busy;

  const _PaymentCard({
    required this.payment,
    required this.controller,
    required this.busy,
  });

  Future<void> _approve(BuildContext context) async {
    final c = controller;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: AppStrings.paymentApproveTitle(payment.name),
      message: AppStrings.paymentApproveMessage,
      confirmLabel: AppStrings.paymentApprove,
      icon: Icons.verified_outlined,
    );
    if (!ok) return;
    final error = await c.approve(payment);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? AppStrings.paymentApproved),
        duration: Duration(seconds: error == null ? 3 : 6),
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final c = controller;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: AppStrings.paymentCancelTitle(payment.name),
      message: AppStrings.paymentCancelMessage,
      confirmLabel: AppStrings.paymentCancel,
      icon: Icons.delete_outline,
    );
    if (!ok) return;
    final error = await c.cancel(payment);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? AppStrings.paymentCancelled)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final draft = payment.isDraft;
    final statusColor = draft ? scheme.tertiary : AppColors.payment;
    final differs =
        payment.accountCurrency.isNotEmpty &&
        payment.accountCurrency != payment.receivedCurrency;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatAmount(
                      payment.receivedAmount,
                      currency: displayCurrency(payment.receivedCurrency),
                    ),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.start,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    draft
                        ? AppStrings.paymentStatusDraft
                        : AppStrings.paymentStatusApproved,
                    style: TextStyle(fontSize: 12, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                payment.name,
                payment.postingDate,
                if (payment.modeOfPayment.isNotEmpty) payment.modeOfPayment,
              ].join('  •  '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (differs)
              Text(
                AppStrings.paymentCredited(
                  formatAmount(
                    payment.paidAmount,
                    currency: displayCurrency(payment.accountCurrency),
                  ),
                ),
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    VoucherDetailsScreen.route('Payment Entry', payment.name),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: Text(AppStrings.paymentDetails),
                ),
                if (draft && busy)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (draft) ...[
                  TextButton.icon(
                    onPressed: () => _cancel(context),
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(AppStrings.paymentCancel),
                  ),
                  FilledButton.icon(
                    onPressed: () => _approve(context),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(AppStrings.paymentApprove),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
