import 'package:get/get.dart';

import '../controllers/expenses_controller.dart';
import '../repository/expenses_repository.dart';

/// (R6) المتحكم دالة إنشاء (lazyPut) فوق الـ repository الدائم المسجّل في
/// InitialBinding: يُنشأ عند فتح الشاشة ويُحذف عند إغلاق مسارها.
class ExpensesBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<ExpensesController>(
    () => ExpensesController(Get.find<ExpensesRepository>()),
  );
}
