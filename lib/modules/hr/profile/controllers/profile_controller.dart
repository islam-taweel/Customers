import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../shared/hr_errors.dart';
import '../../shared/models/employee_models.dart';
import '../repository/profile_repository.dart';

/// «حسابي»: بيانات الموظف ووردية اليوم، ثم صورته إن وُجدت.
/// حالات العرض عبر StateMixin: loading ← success أو error (رسالة جاهزة).
///
/// (R5) بديل FutureBuilder في MyAccountScreen وFutureBuilder الصورة في رأسها:
/// نفس الطلبات وبنفس الترتيب (البيانات أولًا، ثم الصورة بعد عرضها).
class ProfileController extends GetxController
    with StateMixin<EmployeeProfile> {
  ProfileController(this._repository);

  final ProfileRepository _repository;

  /// صورة الموظف (null = الأيقونة: لا صورة، أو لم تصل بعد، أو فشل تحميلها)
  final image = Rxn<Uint8List>();

  int _request = 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// لا يرمي. يُهمل رد أي طلب أقدم (كما كان FutureBuilder يتابع الأحدث فقط).
  Future<void> load() async {
    final request = ++_request;
    change(state, status: RxStatus.loading());
    image.value = null;
    try {
      final profile = await _repository.fetchProfile();
      if (request != _request || isClosed) return;
      change(profile, status: RxStatus.success());
      _loadImage(profile.image, request);
    } catch (e) {
      if (request != _request || isClosed) return;
      change(
        null,
        status: RxStatus.error(
          hrErrorMessage(e, fallback: EssStrings.profileLoadFailed),
        ),
      );
    }
  }

  /// الصورة معلومة إضافية: فشلها يُبقي الأيقونة كما كان (snap.hasData = false)
  Future<void> _loadImage(String path, int request) async {
    if (path.isEmpty) return;
    try {
      final bytes = await _repository.fetchImage(path);
      if (request != _request || isClosed) return;
      image.value = bytes;
    } catch (e) {
      debugPrint('ProfileController image failed: $e');
    }
  }
}
