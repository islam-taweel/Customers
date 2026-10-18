import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/sales_invoice.dart';
import '../controllers/customer_details_controller.dart';
import '../controllers/customer_invoices_controller.dart';
import '../screens/invoice_details_screen.dart';
import 'offline_banner.dart';
import 'sales_invoice_tile.dart';

/// تبويب الفاتورة في شاشة تفاصيل العميل: فواتيره من ERPNext.
/// اضغط فاتورة لعرض تفاصيلها وأصنافها وتحويلها إلى PDF.
/// (الديون والدفعات تبقى محلية، وERPNext هنا للفواتير فقط.)
class InvoiceTab extends StatelessWidget {
  const InvoiceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CustomerInvoicesController>(
      create: (ctx) => ctx
          .read<CustomerDetailsController>()
          .createInvoicesController()
        ..load(),
      child: const _InvoicesView(),
    );
  }
}

class _InvoicesView extends StatelessWidget {
  const _InvoicesView();

  void _openInvoice(
    BuildContext context,
    CustomerInvoicesController list,
    SalesInvoice invoice,
  ) {
    final details = context.read<CustomerDetailsController>();
    final local = invoice.isLocal ? list.localDetail(invoice.name) : null;
    Navigator.push(
      context,
      InvoiceDetailsScreen.route(
        local != null
            ? details.openLocalInvoice(local)
            : details.openInvoice(invoice.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomerInvoicesController>();

    return Column(
      children: [
        // دون إنترنت أو فشل التحديث: نعرض المحفوظ مع تنبيه
        if (controller.notice != null) OfflineBanner(message: controller.notice!),
        // التحديث من ERPNext جارٍ بينما المحفوظ ظاهر
        if (controller.isRefreshing && !controller.isLoading)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _buildContent(context, controller)),
      ],
    );
  }

  Widget _buildContent(BuildContext context, CustomerInvoicesController controller) {
    if (controller.isLoading) return const LoadingView();

    if (controller.error != null) {
      return ErrorView(message: controller.error!, onRetry: controller.load);
    }

    // لا عميل مطابق في ERPNext وليس هناك فواتير محلية أيضًا
    if (!controller.matched && controller.invoices.isEmpty) {
      return EmptyView(
        icon: Icons.link_off,
        title: AppStrings.invoicesNoMatchTitle,
        message: AppStrings.invoicesNoMatchMessage,
      );
    }

    final invoices = controller.invoices;
    if (invoices.isEmpty) {
      return EmptyView(
        icon: Icons.receipt_long_outlined,
        title: AppStrings.noInvoicesTitle,
        message: AppStrings.noInvoicesMessage,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: invoices.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => SalesInvoiceTile(
        invoice: invoices[i],
        onTap: () => _openInvoice(context, controller, invoices[i]),
      ),
    );
  }
}
