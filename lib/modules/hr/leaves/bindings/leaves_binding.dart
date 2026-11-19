import 'package:get/get.dart';

import '../controllers/leaves_controller.dart';
import '../repository/leaves_repository.dart';

/// (R5) المتحكم دالة إنشاء (lazyPut) فوق الـ repository الدائم المسجّل في
/// InitialBinding: يُنشأ عند فتح الشاشة ويُحذف عند إغلاق مسارها.
class LeavesBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<LeavesController>(
    () => LeavesController(Get.find<LeavesRepository>()),
  );
}
