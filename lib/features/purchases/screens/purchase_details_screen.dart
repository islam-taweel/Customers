import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/purchase_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/purchase_models.dart';
import '../../customers/widgets/confirm_dialog.dart';
import '../controllers/purchases_controller.dart';
import '../widgets/purchase_print.dart';
import 'edit_purchase_items_screen.dart';

/// تفاصيل مستند مشتريات (أمر شراء / استلام / فاتورة): محتوياته، وبالأسفل أزرار بحسب
/// المرحلة. لأمر الشراء: «استلام» و«طباعة» (بانتظار الاستلام)، «فوترة» و«طباعة»
/// (بانتظار الفوترة)، «طباعة» (مكتمل)، و«اعتماد» و«حذف» (مسودة).
class PurchaseDetailsScreen extends StatefulWidget {
  final String doctype;
  final String name;

  const PurchaseDetailsScreen({
    super.key,
    required this.doctype,
    required this.name,
  });

  static Route<void> route(
    PurchasesController controller, {
    required String doctype,
    required String name,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<PurchasesController>.value(
        value: controller,
        child: PurchaseDetailsScreen(doctype: doctype, name: name),
      ),
    );
  }

  @override
  State<PurchaseDetailsScreen> createState() => _PurchaseDetailsScreenState();
}

class _PurchaseDetailsScreenState extends State<PurchaseDetailsScreen> {
  late Future<PurchaseDocDetail> _future;
  bool _busy = false;

  bool get _isOrder => widget.doctype == 'Purchase Order';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PurchaseDocDetail> _load() =>
      context.read<PurchasesController>().detail(widget.doctype, widget.name);

  Future<void> _run({
    required Future<String?> Function(PurchasesController c) action,
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    required String successMessage,
    bool destructive = false,
  }) async {
    if (_busy) return;
    final controller = context.read<PurchasesController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await ConfirmDialog.show(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      icon: icon,
      destructive: destructive,
    );
    if (!ok || !mounted) return;

    setState(() => _busy = true);
    final error = await action(controller);
    if (!mounted) return;
    setState(() => _busy = false);

    if (error == null) {
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      navigator.pop();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  /// تعديل كمية/سعر/وحدة بنود المستند المسودة؛ يعيد المستند كما حسبه ERPNext
  Future<void> _editItems(PurchaseDocDetail detail) async {
    final controller = context.read<PurchasesController>();
    final updated = await Navigator.of(context).push<PurchaseDocDetail>(
      EditPurchaseItemsScreen.route(
        controller,
        doctype: widget.doctype,
        detail: detail,
      ),
    );
    if (updated == null || !mounted) return;
    // المبالغ المعروضة هي التي أعادها ERPNext بعد الحفظ
    setState(() => _future = Future.value(updated));
  }

  Widget _busyIcon(IconData icon) => _busy
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Icon(icon);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PurchasesController>();
    final order = _isOrder ? controller.orderByName(widget.name) : null;

    final buttons = <Widget>[];
    if (order != null) {
      switch (order.stage) {
        case PurchaseStage.draft:
          buttons.add(Expanded(
            child: FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(
                        action: (c) => c.approveOrder(order),
                        title: PurchaseStrings.approveOrderTitle,
                        message: PurchaseStrings.approveOrderMessage,
                        confirmLabel: PurchaseStrings.approve,
                        icon: Icons.verified_outlined,
                        successMessage: PurchaseStrings.orderApproved,
                      ),
              icon: _busyIcon(Icons.verified_outlined),
              label: Text(PurchaseStrings.approve),
            ),
          ));
          buttons.add(const SizedBox(width: 12));
          buttons.add(Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(
                        action: (c) => c.deleteOrder(order),
                        title: PurchaseStrings.deleteOrderTitle,
                        message: PurchaseStrings.deleteOrderMessage,
                        confirmLabel: AppStrings.delete,
                        icon: Icons.delete_outline,
                        successMessage: PurchaseStrings.orderDeleted,
                        destructive: true,
                      ),
              icon: const Icon(Icons.delete_outline),
              label: Text(AppStrings.delete),
            ),
          ));
        case PurchaseStage.toReceive:
          buttons.add(Expanded(
            child: FilledButton.icon(
              onPressed: (_busy || !order.canReceive)
                  ? null
                  : () => _run(
                        action: (c) => c.receive(order),
                        title: PurchaseStrings.receiveTitle,
                        message: PurchaseStrings.receiveMessage,
                        confirmLabel: PurchaseStrings.receive,
                        icon: Icons.move_to_inbox_outlined,
                        successMessage: PurchaseStrings.orderReceived,
                      ),
              icon: _busyIcon(Icons.move_to_inbox_outlined),
              label: Text(PurchaseStrings.receive),
            ),
          ));
          buttons.add(const SizedBox(width: 12));
          buttons.add(Expanded(
            child: PrintButton(
              controller: controller,
              doctype: widget.doctype,
              name: widget.name,
            ),
          ));
        case PurchaseStage.toBill:
          buttons.add(Expanded(
            child: FilledButton.icon(
              // مظلل حتى يعتمد ERPNext الاستلام
              onPressed: (_busy || !order.canBill)
                  ? null
                  : () => _run(
                        action: (c) => c.billOrder(order),
                        title: PurchaseStrings.billTitle,
                        message: PurchaseStrings.billMessage,
                        confirmLabel: PurchaseStrings.bill,
                        icon: Icons.request_quote_outlined,
                        successMessage: PurchaseStrings.billed,
                      ),
              icon: _busyIcon(Icons.request_quote_outlined),
              label: Text(PurchaseStrings.bill),
            ),
          ));
          buttons.add(const SizedBox(width: 12));
          buttons.add(Expanded(
            child: PrintButton(
              controller: controller,
              doctype: widget.doctype,
              name: widget.name,
            ),
          ));
        case PurchaseStage.completed:
          buttons.add(Expanded(
            child: PrintButton(
              controller: controller,
              doctype: widget.doctype,
              name: widget.name,
            ),
          ));
      }
    } else {
      buttons.add(Expanded(
        child: PrintButton(
          controller: controller,
          doctype: widget.doctype,
          name: widget.name,
        ),
      ));
    }

    final hint = (order != null && order.stage == PurchaseStage.toBill && !order.canBill)
        ? PurchaseStrings.billWaitingApproval
        : (order != null && order.awaitingReceiptApproval)
            ? PurchaseStrings.receiptAwaitingApproval
            : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: FutureBuilder<PurchaseDocDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppStrings.loadInvoicesError),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DetailCard(detail: snap.data!),
                    // البنود تُعدَّل ما دام المستند مسودة (docstatus 0)
                    if (snap.data!.isDraft && snap.data!.lines.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : () => _editItems(snap.data!),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(PurchaseStrings.editItems),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: buttons),
                  if (hint != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        hint,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final PurchaseDocDetail detail;

  const _DetailCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cur = displayCurrency(detail.currency);
    String money(double v) => formatSignedAmount(v, currency: cur);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              detail.supplierName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              '${detail.name}${detail.date.isEmpty ? '' : ' • ${detail.date}'}',
              textDirection: TextDirection.ltr,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const Divider(height: 28),
            for (final l in detail.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.itemName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${_n(l.qty)}${l.uom.isEmpty ? '' : ' ${l.uom}'} × ${money(l.rate)}',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      money(l.amount),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            const Divider(height: 28),
            _Row(PurchaseStrings.subtotal, money(detail.netTotal)),
            if (detail.taxes != 0) _Row(PurchaseStrings.taxes, money(detail.taxes)),
            _Row(PurchaseStrings.total, money(detail.grandTotal), bold: true),
          ],
        ),
      ),
    );
  }

  static String _n(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
