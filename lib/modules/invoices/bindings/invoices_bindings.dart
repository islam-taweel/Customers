import 'package:get/get.dart';

import '../../../data/repositories/invoice_repository.dart';
import '../../collections/controllers/invoice_collections_controller.dart';
import '../controllers/invoice_details_controller.dart';
import '../controllers/sales_invoices_controller.dart';
import '../repository/sales_invoices_repository.dart';

/// قسم «الفواتير» (داخل قسم «الطلبات»). يحتاج InvoiceCollectionsBinding قبله في
/// نفس المسار (الدفعات المعلّقة على الفواتير).
class SalesInvoicesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalesInvoicesController>(
      () => SalesInvoicesController(
        Get.find<ErpSalesInvoicesRepository>(),
        Get.find<InvoiceRepository>(),
        Get.find<InvoiceCollectionsController>(),
      ),
    );
  }
}

/// تفاصيل فاتورة: المتحكم يصنعه CustomerDetailsController (openInvoice /
/// openLocalInvoice) كما كان، وهنا يُسجَّل بوسم المسار فقط.
class InvoiceDetailsBinding extends Bindings {
  InvoiceDetailsBinding(this.controller, {required this.tag});

  final InvoiceDetailsController controller;
  final String tag;

  @override
  void dependencies() {
    Get.lazyPut<InvoiceDetailsController>(() => controller, tag: tag);
  }
}

int _seq = 0;
String nextInvoicesTag(String prefix) => '$prefix#${++_seq}';
