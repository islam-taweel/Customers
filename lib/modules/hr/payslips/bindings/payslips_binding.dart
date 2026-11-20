import 'package:get/get.dart';

import '../controllers/payslips_controller.dart';
import '../repository/payslips_repository.dart';

/// (R6) المتحكم دالة إنشاء (lazyPut) فوق الـ repository الدائم المسجّل في
/// InitialBinding: يُنشأ عند فتح الشاشة ويُحذف عند إغلاق مسارها.
class PayslipsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<PayslipsController>(
    () => PayslipsController(Get.find<PayslipsRepository>()),
  );
}

/// تفاصيل كشف واحد: رقم الكشف يصل في arguments (Get.toNamed)، وهو tag المتحكم،
/// فلكل كشف متحكمه الخاص كما كان قبل الترحيل.
class PayslipDetailBinding extends Bindings {
  @override
  void dependencies() {
    final name = Get.arguments as String;
    Get.lazyPut<PayslipDetailController>(
      () => PayslipDetailController(Get.find<PayslipsRepository>(), name),
      tag: name,
    );
  }
}
