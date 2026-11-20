import 'package:get/get.dart';

import '../../shared/hr_approver_access.dart';
import '../controllers/team_controller.dart';
import '../repository/team_repository.dart';

/// (R6) المتحكم دالة إنشاء (lazyPut) فوق الـ repository الدائم المسجّل في
/// InitialBinding: يُنشأ عند فتح الشاشة ويُحذف عند إغلاق مسارها.
class TeamBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<TeamController>(
    () => TeamController(
      Get.find<TeamRepository>(),
      Get.find<HrApproverAccess>(),
    ),
  );
}
