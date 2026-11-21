import 'package:get/get.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../../../core/utils/palestine_time.dart';
import '../../attendance/models/attendance_models.dart';
import '../../shared/hr_errors.dart';
import '../repository/overtime_repository.dart';

/// «عملي الإضافي» للشهر المختار كما حسبه ERPNext (لا حساب للمبالغ في التطبيق).
/// حالات العرض عبر StateMixin: loading، error، empty (لا مبالغ ولا ساعات)، success.
///
/// (R6) بديل FutureBuilder وحالة الشهر في OvertimeScreen. الشهر الافتراضي من
/// PalestineTime.today() كما كان. التجميع اليومي للرسم (كان داخل الواجهة) هنا.
class OvertimeController extends GetxController with StateMixin<OvertimeMonth> {
  OvertimeController(this._repository, {DateTime Function()? today})
    : _today = today ?? PalestineTime.today;

  final OvertimeRepository _repository;
  final DateTime Function() _today;

  late final year = _today().year.obs;
  late final month = _today().month.obs;

  int _request = 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

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
      final data = await _repository.fetchOvertimeMonth(
        year.value,
        month.value,
      );
      if (request != _request || isClosed) return;
      change(
        data,
        status: data.isEmpty ? RxStatus.empty() : RxStatus.success(),
      );
    } catch (e) {
      if (request != _request || isClosed) return;
      change(
        null,
        status: RxStatus.error(
          hrErrorMessage(e, fallback: EssStrings.overtimeLoadFailed),
        ),
      );
    }
  }

  int get _daysInMonth => DateTime(year.value, month.value + 1, 0).day;

  /// ساعات كل يوم (بالثواني) من بنود Overtime Slip، كما كانت تُجمع في الواجهة
  List<double> hoursByDay(OvertimeMonth data) {
    final values = List<double>.filled(_daysInMonth, 0);
    for (final d in data.days) {
      values[d.date.day - 1] += d.durationSeconds;
    }
    return values;
  }

  /// مبالغ كل يوم من Additional Salary
  List<double> amountsByDay(OvertimeMonth data) {
    final values = List<double>.filled(_daysInMonth, 0);
    for (final p in data.payments) {
      values[p.payrollDate.day - 1] += p.amount;
    }
    return values;
  }
}
