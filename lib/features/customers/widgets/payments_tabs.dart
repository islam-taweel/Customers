import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/payment_entry.dart';
import '../../statement/screens/voucher_details_screen.dart';
import '../controllers/customer_details_controller.dart';
import 'confirm_dialog.dart';

/// تحت زر «إضافة دفعة»: تبويبا «مسودة» و«معتمدة» لدفعات العميل في ERPNext
/// (بما فيها المسجلة من الفواتير). المسودة: «اعتماد» و«إلغاء» و«تفاصيل الدفعة»؛
/// المعتمدة: «تفاصيل الدفعة».
class PaymentsTabs extends StatefulWidget {
  const PaymentsTabs({super.key});

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

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CustomerDetailsController>();
    final drafts = c.draftPayments;
    final approved = c.approvedPayments;
    final showingDrafts = _tabs.index == 0;
    final list = showingDrafts ? drafts : approved;

    Widget body;
    if (c.paymentsLoading && drafts.isEmpty && approved.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (c.paymentsError != null && drafts.isEmpty && approved.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(c.paymentsError!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: c.loadPayments,
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
        children: [for (final p in list) _PaymentCard(payment: p)],
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
        if (c.paymentsLoading) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: body,
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentEntrySummary payment;

  const _PaymentCard({required this.payment});

  Future<void> _approve(BuildContext context) async {
    final c = context.read<CustomerDetailsController>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: AppStrings.paymentApproveTitle(payment.name),
      message: AppStrings.paymentApproveMessage,
      confirmLabel: AppStrings.paymentApprove,
      icon: Icons.verified_outlined,
    );
    if (!ok) return;
    final error = await c.approvePayment(payment);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? AppStrings.paymentApproved),
        duration: Duration(seconds: error == null ? 3 : 6),
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final c = context.read<CustomerDetailsController>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.show(
      context,
      title: AppStrings.paymentCancelTitle(payment.name),
      message: AppStrings.paymentCancelMessage,
      confirmLabel: AppStrings.paymentCancel,
      icon: Icons.delete_outline,
    );
    if (!ok) return;
    final error = await c.cancelPayment(payment);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? AppStrings.paymentCancelled)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CustomerDetailsController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy = c.isPaymentBusy(payment);
    final draft = payment.isDraft;
    final statusColor = draft ? scheme.tertiary : AppColors.payment;
    final differs = payment.accountCurrency.isNotEmpty &&
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
