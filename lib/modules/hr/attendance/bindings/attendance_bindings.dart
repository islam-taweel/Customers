import 'package:get/get.dart';

import '../controllers/attendance_controller.dart';
import '../controllers/correction_controller.dart';
import '../repository/attendance_repository.dart';

/// (R5) المتحكم دالة إنشاء (lazyPut) فوق الـ repository الدائم المسجّل في
/// InitialBinding: يُنشأ عند فتح الشاشة ويُحذف عند إغلاق مسارها.
class AttendanceBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<AttendanceController>(
    () => AttendanceController(Get.find<AttendanceRepository>()),
  );
}

class CorrectionBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<CorrectionController>(
    () => CorrectionController(Get.find<AttendanceRepository>()),
  );
}
