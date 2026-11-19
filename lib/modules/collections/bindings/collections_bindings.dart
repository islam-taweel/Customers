import 'package:get/get.dart';

import '../../../data/models/sales_invoice.dart';
import '../controllers/customer_collections_controller.dart';
import '../controllers/invoice_collections_controller.dart';
import '../controllers/payment_sheet_controller.dart';
import '../repository/erp_payment_repository.dart';
import '../repository/invoice_collections_repository.dart';

/// الـ repositories مسجّلة مرة واحدة (permanent) في InitialBinding بنفس كائنات
/// main()؛ هنا تُسجَّل المتحكمات فقط كدوال إنشاء (lazyPut).

/// تحصيلات الفواتير: مع قسم «الطلبات» (يُحذف عند إغلاقه)
class InvoiceCollectionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InvoiceCollectionsController>(
      () => InvoiceCollectionsController(
        Get.find<ErpInvoiceCollectionsRepository>(),
      ),
    );
  }
}

/// نافذة «دفع فاتورة»: متحكم لكل نافذة (وسم)، تحذفه النافذة عند إغلاقها
class PaymentSheetBinding extends Bindings {
  PaymentSheetBinding(this.invoice, {required this.tag});

  final SalesInvoice invoice;
  final String tag;

  @override
  void dependencies() {
    Get.lazyPut<PaymentSheetController>(
      () => PaymentSheetController(
        invoice,
        Get.find<InvoiceCollectionsController>(),
      ),
      tag: tag,
    );
  }
}

/// تحصيلات عميل (شاشة «العمليات»): متحكم لكل مسار (وسم)
class CustomerCollectionsBinding extends Bindings {
  CustomerCollectionsBinding(this.host, {required this.tag});

  final CustomerCollectionsHost host;
  final String tag;

  @override
  void dependencies() {
    Get.lazyPut<CustomerCollectionsController>(
      () =>
          CustomerCollectionsController(Get.find<ErpPaymentRepository>(), host),
      tag: tag,
    );
  }
}

int _seq = 0;
String nextCollectionsTag(String prefix) => '$prefix#${++_seq}';
