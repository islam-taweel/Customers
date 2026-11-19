import 'package:get/get.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../shared/hr_errors.dart';
import '../models/attendance_models.dart';
import '../repository/attendance_repository.dart';

/// «حضوري»: سجلات الحضور المعتمدة لشهر مختار، وملخص الشهر.
/// حالات العرض عبر StateMixin: loading، error، empty (لا سجلات)، success.
///
/// (R5) بديل FutureBuilder وحالة الشهر في AttendanceLogScreen. الشهر الافتراضي
/// هو شهر الجهاز الحالي (DateTime.now) كما كان. التأخير والخروج المبكر يحسبهما
/// النموذج من وقت الوردية (AttendanceRecord) كما كان؛ الملخص من AttendanceSummary.
class AttendanceController extends GetxController
    with StateMixin<List<AttendanceRecord>> {
  AttendanceController(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AttendanceRepository _repository;
  final DateTime Function() _clock;

  late final year = _clock().year.obs;
  late final month = _clock().month.obs;

  int _request = 0;

  /// ملخص الشهر المعروض (أصفار عند عدم وجود سجلات)
  AttendanceSummary get summary => AttendanceSummary.of(state ?? const []);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// نفس الشهر ← لا شيء (كما كان)
  void setPeriod(int y, int m) {
    if (y == year.value && m == month.value) return;
    year.value = y;
    month.value = m;
    load();
  }

  Future<void> load() async {
    final request = ++_request;
    change(state, status: RxStatus.loading());
    try {
      final records = await _repository.fetchAttendance(
        year.value,
        month.value,
      );
      if (request != _request || isClosed) return;
      change(
        records,
        status: records.isEmpty ? RxStatus.empty() : RxStatus.success(),
      );
    } catch (e) {
      if (request != _request || isClosed) return;
      change(
        null,
        status: RxStatus.error(
          hrErrorMessage(e, fallback: EssStrings.attendanceLoadFailed),
        ),
      );
    }
  }
}
