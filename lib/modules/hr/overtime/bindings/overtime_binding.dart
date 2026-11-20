import 'package:get/get.dart';

import '../controllers/overtime_controller.dart';
import '../repository/overtime_repository.dart';

/// (R6) المتحكم دالة إنشاء (lazyPut) فوق الـ repository الدائم المسجّل في
/// InitialBinding: يُنشأ عند فتح الشاشة ويُحذف عند إغلاق مسارها.
class OvertimeBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<OvertimeController>(
    () => OvertimeController(Get.find<OvertimeRepository>()),
  );
}
