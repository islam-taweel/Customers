import 'package:get/get.dart';

import '../controllers/punch_controller.dart';
import '../repository/punch_repository.dart';

/// (R5) المتحكم دالة إنشاء (lazyPut) فوق الـ repository الدائم المسجّل في
/// InitialBinding: يُنشأ عند فتح الشاشة ويُحذف عند إغلاق مسارها.
class PunchBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<CheckinController>(
    () => CheckinController(Get.find<PunchRepository>()),
  );
}
