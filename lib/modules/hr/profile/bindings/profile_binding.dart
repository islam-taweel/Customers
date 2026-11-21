import 'package:get/get.dart';

import '../../../../app/services/session_service.dart';
import '../controllers/profile_controller.dart';
import '../repository/profile_repository.dart';

/// (R5) المتحكم دالة إنشاء (lazyPut) فوق الـ repository الدائم المسجّل في
/// InitialBinding: يُنشأ عند فتح الشاشة ويُحذف عند إغلاق مسارها.
class ProfileBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<ProfileController>(
    () => ProfileController(
      Get.find<ProfileRepository>(),
      Get.find<SessionService>(),
    ),
  );
}
