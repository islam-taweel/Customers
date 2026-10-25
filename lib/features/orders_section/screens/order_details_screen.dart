import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/invoice_pdf_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/invoice.dart';
import '../../customers/widgets/confirm_dialog.dart';
import '../../customers/widgets/invoice_card.dart';
import '../controllers/orders_controller.dart';

/// تفاصيل طلبية معتمدة: تظهر كفاتورة بحالتها (بانتظار التسليم / الفوترة /
/// مكتملة)، وبالأسفل زر «تسليم» (إن كانت بانتظار التسليم) وزر «طباعة».
/// لا تعديل ولا حذف بعد الاعتماد. تُرجع true إن سُلِّمت الطلبية من هذه الشاشة.
class OrderDetailsScreen extends StatefulWidget {
  final Invoice invoice;

  const OrderDetailsScreen({super.key, required this.invoice});

  static Route<bool> route(Invoice invoice, OrdersController controller) {
    return MaterialPageRoute<bool>(
      builder: (_) => ChangeNotifierProvider<OrdersController>.value(
        value: controller,
        child: OrderDetailsScreen(invoice: invoice),
      ),
    );
  }

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  /// يحدد الجزء الذي يُلتقط كصورة عند تعذّر PDF الرسمي
  final GlobalKey _invoiceKey = GlobalKey();
  bool _busy = false;

  Invoice get _invoice => widget.invoice;

  String get _fileName =>
      'order-${_invoice.displayName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.pdf';

  /// PDF الرسمي من ERPNext، وإلا ملف مولَّد من الفاتورة المعروضة.
  Future<Uint8List> _pdfBytes() async {
    try {
      final orderId = _invoice.orderId ?? '';
      if (orderId.isEmpty) throw StateError('no order id');
      return await context.read<OrdersController>().downloadPdf(orderId);
    } catch (e) {
      debugPrint('order pdf failed, using local capture: $e');
      return InvoicePdfService.fromBoundary(_invoiceKey);
    }
  }

  Future<void> _print() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final pdf = await _pdfBytes();
      await Printing.layoutPdf(onLayout: (_) async => pdf, name: _fileName);
    } catch (e) {
      debugPrint('order print failed: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.invoicePdfFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deliver() async {
    if (_busy) return;
    final orders = context.read<OrdersController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.deliverTitle,
      message: AppStrings.deliverMessage,
      confirmLabel: AppStrings.deliver,
      icon: Icons.local_shipping_outlined,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final error = await orders.deliver(_invoice);
    if (!mounted) return;
    setState(() => _busy = false);

    if (error == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.orderDelivered)),
      );
      navigator.pop(true);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _invoice.toDetail();
    final canDeliver = _invoice.stage == OrderStage.toDeliver &&
        !_invoice.isErpDeliveryDraft;

    return Scaffold(
      appBar: AppBar(title: Text(_invoice.displayName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: RepaintBoundary(
              key: _invoiceKey,
              child: InvoiceCard(
                number: detail.name,
                customerName: detail.customerName,
                customerPhone: _invoice.customerPhone,
                amount: detail.grandTotal,
                date: detail.postingDate,
                dueDate: detail.dueDate,
                status: detail.status,
                currency: displayCurrency(detail.currency),
                items: detail.items,
                notes: _invoice.notes,
              ),
            ),
          ),
        ),
      ),
      // الأزرار ثابتة بالأسفل
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Row(
                children: [
                  if (canDeliver) ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _deliver,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.local_shipping_outlined),
                        label: Text(AppStrings.deliver),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _print,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.print_outlined),
                      label: Text(AppStrings.printInvoice),
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
