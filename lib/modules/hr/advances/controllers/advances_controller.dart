import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../shared/hr_errors.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../data/api/erp_api_client.dart';
import '../../advances/models/advance_models.dart';
import '../repository/advances_repository.dart';

/// سلفي (GetX): سلف الموظف المسجّل دخوله فقط من ERPNext، تُحدَّث عند فتح
/// الشاشة، وتقديم طلب سلفة جديد (مسودة = قيد المراجعة). لا موافقة ولا دفع
/// ولا إلغاء من التطبيق: ذلك من صلاحية الموارد البشرية.
class AdvancesController extends GetxController
    with StateMixin<List<EmployeeAdvance>> {
  AdvancesController(this._repository);

  final AdvancesRepository _repository;

  final advances = <EmployeeAdvance>[].obs;
  final loading = false.obs;
  final sending = false.obs;

  /// خطأ التحميل (null = لا خطأ)
  final error = Rxn<Object>();

  /// رسالة الخطأ للعرض (R6: كانت دالة في الواجهة)
  String? get errorMessage {
    final e = error.value;
    return e == null
        ? null
        : hrErrorMessage(e, fallback: EssStrings.advancesLoadFailed);
  }

  /// المتبقي مع الموظف من كل السلف المدفوعة
  double get totalRemaining =>
      advances.fold<double>(0, (s, a) => s + a.remainingAmount);

  /// (R7) حالة العرض لـ controller.obx، محسوبة من نفس الشروط وبنفس ترتيبها:
  /// تحميل والقائمة فارغة ← loading؛ خطأ والقائمة فارغة ← error؛ فارغة ←
  /// empty؛ وإلا success (القائمة تبقى ظاهرة أثناء إعادة التحميل كما كانت).
  Worker? _statusWorker;

  void _syncStatus() {
    final list = advances.toList();
    if (loading.value && list.isEmpty) {
      change(list, status: RxStatus.loading());
    } else if (error.value != null && list.isEmpty) {
      change(list, status: RxStatus.error(errorMessage));
    } else if (list.isEmpty) {
      change(list, status: RxStatus.empty());
    } else {
      change(list, status: RxStatus.success());
    }
  }

  @override
  void onClose() {
    _statusWorker?.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    _statusWorker = everAll([loading, error, advances], (_) => _syncStatus());
    _syncStatus();
    // تحديث البيانات من ERPNext عند فتح الشاشة
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      advances.assignAll(await _repository.fetchAdvances());
    } catch (e) {
      debugPrint('AdvancesController.load failed: $e');
      error.value = e;
    } finally {
      loading.value = false;
    }
  }

  /// null = صالح
  static String? validateAmount(double? amount) =>
      amount == null || amount <= 0 ? EssStrings.amountInvalid : null;

  /// null = نجح، وإلا رسالة الخطأ (مع نص ERPNext عند رفض الخادم).
  Future<String?> submit({
    required double amount,
    required String purpose,
  }) async {
    final invalid =
        validateAmount(amount) ??
        (purpose.trim().isEmpty ? EssStrings.requiredField : null);
    if (invalid != null) return invalid;
    if (sending.value) return null;

    sending.value = true;
    try {
      await _repository.submitAdvance(amount: amount, purpose: purpose);
      await load();
      return null;
    } catch (e) {
      debugPrint('AdvancesController.submit failed: $e');
      final detail = e is ErpApiException && e.type == ErpErrorType.server
          ? e.detail
          : null;
      final base = describeError(e, fallback: EssStrings.advanceSendFailed);
      return (detail == null || detail.isEmpty)
          ? base
          : '${EssStrings.advanceSendFailed}\n$detail';
    } finally {
      sending.value = false;
    }
  }
}
