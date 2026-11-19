import 'package:get/get.dart';

import '../../../../data/repositories/erp_employee_repository.dart';
import '../controllers/hr_access_controller.dart';

/// (R5) المتحكم دالة إنشاء (lazyPut) فوق الـ repository الدائم المسجّل في
/// InitialBinding: يُنشأ عند فتح الشاشة ويُحذف عند إغلاق مسارها.
class HrHomeBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<HrAccessController>(
    () => HrAccessController(Get.find<ErpEmployeeRepository>()),
  );
}
