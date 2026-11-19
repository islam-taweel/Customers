import 'package:get/get.dart';

import '../../../data/models/erp_customer.dart';
import '../controllers/customer_statement_controller.dart';
import '../controllers/statement_customers_controller.dart';
import '../controllers/voucher_details_controller.dart';
import '../repository/erp_statement_repository.dart';

/// كل الـ Bindings تسجّل المتحكم كدالة إنشاء (lazyPut) فوق نفس
/// [ErpStatementRepository] المسجَّل دائمًا في InitialBinding — لا نسخ جديدة.
/// يُنشأ المتحكم عند أول Get.find في الشاشة، ويُحذف مع مساره (GetPageRoute).

class StatementCustomersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StatementCustomersController>(
      () => StatementCustomersController(Get.find<ErpStatementRepository>()),
    );
  }
}

class CustomerStatementBinding extends Bindings {
  CustomerStatementBinding(this.customer, {required this.tag});

  final ErpCustomer customer;
  final String tag;

  @override
  void dependencies() {
    Get.lazyPut<CustomerStatementController>(
      () => CustomerStatementController(
        Get.find<ErpStatementRepository>(),
        customer,
      ),
      tag: tag,
    );
  }
}

class VoucherDetailsBinding extends Bindings {
  VoucherDetailsBinding(this.doctype, this.name, {required this.tag});

  final String doctype;
  final String name;
  final String tag;

  @override
  void dependencies() {
    Get.lazyPut<VoucherDetailsController>(
      () => VoucherDetailsController(
        Get.find<ErpStatementRepository>(),
        doctype: doctype,
        name: name,
      ),
      tag: tag,
    );
  }
}

/// وسم فريد لكل مسار: نفس المستند قد يُفتح مرتين فوق بعضه
int _seq = 0;
String nextStatementTag(String prefix) => '$prefix#${++_seq}';
