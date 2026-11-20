import 'package:get/get.dart';

import '../controllers/advances_controller.dart';
import '../repository/advances_repository.dart';

/// (R6) المتحكم دالة إنشاء (lazyPut) فوق الـ repository الدائم المسجّل في
/// InitialBinding: يُنشأ عند فتح الشاشة ويُحذف عند إغلاق مسارها.
class AdvancesBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<AdvancesController>(
    () => AdvancesController(Get.find<AdvancesRepository>()),
  );
}
