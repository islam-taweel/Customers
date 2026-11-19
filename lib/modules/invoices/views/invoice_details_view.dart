import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/invoice_pdf_service.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/sales_invoice.dart';
import '../../../features/customers/screens/gl_entries_screen.dart';
import '../../../features/customers/screens/invoice_pdf_screen.dart';
import '../../../features/customers/widgets/invoice_card.dart';
import '../../../features/customers/widgets/offline_banner.dart';
import '../bindings/invoices_bindings.dart';
import '../controllers/invoice_details_controller.dart';

/// تفاصيل فاتورة معتمدة (عند الضغط عليها): رقمها واسم العميل وهاتفه والمبلغ
/// وأصنافها، مع زرّين: عرضها كملف PDF وطباعتها، وزر «القيود المحاسبية» للفاتورة المعتمدة.
/// الملف هو PDF الرسمي من ERPNext (download_pdf)، وعند تعذّره (دون اتصال مثلًا)
/// نولّد ملفًا من الفاتورة المعروضة على الشاشة.
class InvoiceDetailsScreen extends StatelessWidget {
  /// وسم المتحكم لهذا المسار
  final String tag;

  const InvoiceDetailsScreen({super.key, required this.tag});

  /// نفس الواجهة القديمة: المتحكم يصنعه CustomerDetailsController. (R3) يُسجَّل
  /// مع المسار (GetPageRoute) فيبدأ التحميل عند فتحه ويُحذف عند إغلاقه.
  static Route<void> route(InvoiceDetailsController controller) {
    final tag = nextInvoicesTag('invoice:${controller.invoiceName}');
    return GetPageRoute<void>(
      settings: const RouteSettings(name: '/invoice'),
      binding: InvoiceDetailsBinding(controller, tag: tag),
      transition: Transition.native,
      page: () => InvoiceDetailsScreen(tag: tag),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<InvoiceDetailsController>(tag: tag);

    return Scaffold(
      appBar: AppBar(title: Text(controller.invoiceName)),
      body: Obx(() => _buildBody(controller)),
    );
  }

  Widget _buildBody(InvoiceDetailsController controller) {
    if (controller.isLoading.value) return const LoadingView();

    final detail = controller.detail.value;
    if (controller.error.value != null || detail == null) {
      return ErrorView(
        message: controller.error.value ?? AppStrings.loadInvoiceError,
        onRetry: controller.load,
      );
    }

    return _InvoiceView(
      detail: detail,
      customerPhone: controller.customerPhone,
      notice: controller.notice.value,
      fetchServerPdf: controller.downloadServerPdf,
      // كل الحالات: الفاتورة (وقيود دفعاتها) أو الطلبية (تسليم/فوترة/دفعات)
      openGlEntries: controller.hasGlEntries
          ? (context) => Navigator.of(context).push(
              controller.doctype == 'Sales Invoice'
                  ? GlEntriesScreen.forInvoice(controller.invoiceName)
                  : GlEntriesScreen.forOrder(controller.invoiceName),
            )
          : null,
    );
  }
}

/// الفاتورة نفسها وزر PDF. StatefulWidget لأنها تحمل مفتاح الالتقاط وحالة «جارٍ التحويل» فقط.
class _InvoiceView extends StatefulWidget {
  final SalesInvoiceDetail detail;
  final String customerPhone;

  /// تنبيه «غير متصل، تُعرض بيانات محفوظة» (null = البيانات محدّثة)
  final String? notice;

  /// يطلب ملف PDF الرسمي من ERPNext
  final Future<Uint8List> Function() fetchServerPdf;

  /// يفتح القيود المحاسبية (null = لا زر: مسودة أو طلبية)
  final void Function(BuildContext context)? openGlEntries;

  const _InvoiceView({
    required this.detail,
    required this.customerPhone,
    required this.fetchServerPdf,
    this.notice,
    this.openGlEntries,
  });

  @override
  State<_InvoiceView> createState() => _InvoiceViewState();
}

class _InvoiceViewState extends State<_InvoiceView> {
  /// يحدد الجزء الذي يُلتقط كصورة ويُحوَّل إلى PDF
  final GlobalKey _invoiceKey = GlobalKey();
  bool _busy = false;

  /// اسم الملف: نستبدل الرموز غير المسموحة في أسماء الملفات
  String get _fileName =>
      'invoice-${widget.detail.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.pdf';

  /// PDF الرسمي من ERPNext، وإلا ملف مولَّد من الفاتورة المعروضة.
  Future<Uint8List> _pdfBytes() async {
    try {
      return await widget.fetchServerPdf();
    } catch (e) {
      debugPrint('download_pdf failed, using local capture: $e');
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
      debugPrint('invoice print failed: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.invoicePdfFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPdf() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);

    try {
      final pdf = await _pdfBytes();
      if (!mounted) return;
      await navigator.push(
        InvoicePdfScreen.route(bytes: pdf, fileName: _fileName),
      );
    } catch (e) {
      debugPrint('invoice pdf failed: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.invoicePdfFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // خارج RepaintBoundary حتى لا يظهر التنبيه داخل ملف الـ PDF
              if (widget.notice != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: OfflineBanner(message: widget.notice!),
                ),
                const SizedBox(height: 12),
              ],
              RepaintBoundary(
                key: _invoiceKey,
                child: InvoiceCard(
                  number: detail.name,
                  customerName: detail.customerName,
                  customerPhone: widget.customerPhone,
                  amount: detail.settlement?.documentTotal ?? detail.grandTotal,
                  date: detail.postingDate,
                  dueDate: detail.dueDate,
                  status: detail.status,
                  currency: displayCurrency(detail.currency),
                  items: detail.items,
                  taxes: detail.totalTaxesAndCharges,
                  // قيمة الفاتورة، المسدد من رصيد سابق، المدفوع، المتبقي (من ERPNext).
                  // المسودة: لا مسدد ولا متبقٍ نهائي قبل اعتمادها
                  settlement: detail.docstatus == 1 ? detail.settlement : null,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _openPdf,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(AppStrings.viewInvoicePdf),
                    ),
                  ),
                  const SizedBox(width: 12),
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
              if (widget.openGlEntries != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => widget.openGlEntries!(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.account_balance_outlined),
                  label: Text(AppStrings.glEntriesTitle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
