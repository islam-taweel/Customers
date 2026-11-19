import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../../../core/utils/palestine_time.dart';
import '../../shared/hr_errors.dart';
import '../../shared/models/employee_models.dart';
import '../repository/punch_repository.dart';

/// حالة الموظف اليوم حسب آخر بصمة
enum CheckinStatus { notCheckedIn, onDuty, finished }

/// تسجيل الحضور والانصراف في ERPNext (Employee Checkin): بصمات اليوم، والزر
/// المتاح حسب آخر بصمة (آخرها IN ← انصراف، غير ذلك ← حضور).
class CheckinController extends GetxController {
  CheckinController(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? PalestineTime.now;

  final PunchRepository _repository;
  final DateTime Function() _clock;

  /// الساعة المعروضة بتوقيت فلسطين، تتحدث كل ثانية (كانت Timer في الواجهة)
  late final now = _clock().obs;
  Timer? _ticker;

  @override
  void onInit() {
    super.onInit();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = _clock();
    });
    load();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  bool _loading = false;
  Object? _error;
  bool _punching = false;
  List<EmployeeCheckin> _punches = const [];

  bool get loading => _loading;

  /// رسالة الخطأ للعرض (غير مرتبط ← notLinked، 403 ← noPermission)
  String? get errorMessage {
    final e = _error;
    return e == null
        ? null
        : hrErrorMessage(e, fallback: EssStrings.punchesLoadFailed);
  }

  Object? get error => _error;
  bool get punching => _punching;

  /// بصمات اليوم، الأحدث أولًا للعرض
  List<EmployeeCheckin> get log => _punches.reversed.toList();
  bool get hasLoaded => !_loading || _punches.isNotEmpty;

  EmployeeCheckin? get _last => _punches.isEmpty ? null : _punches.last;

  CheckinStatus get status {
    final last = _last;
    if (last == null) return CheckinStatus.notCheckedIn;
    return last.isIn ? CheckinStatus.onDuty : CheckinStatus.finished;
  }

  bool get canCheckIn => !_punching && !_loading && !(_last?.isIn ?? false);
  bool get canCheckOut => !_punching && !_loading && (_last?.isIn ?? false);

  /// أول حضور اليوم
  DateTime? get checkInAt {
    for (final p in _punches) {
      if (p.isIn) return p.time;
    }
    return null;
  }

  /// آخر انصراف، إن لم تكن بعده بصمة حضور
  DateTime? get checkOutAt {
    final last = _last;
    return last != null && !last.isIn ? last.time : null;
  }

  /// مجموع فترات IN ← OUT اليوم، والفترة المفتوحة حتى [now]
  Duration? worked(DateTime now) {
    if (_punches.isEmpty) return null;
    var total = Duration.zero;
    DateTime? open;
    for (final p in _punches) {
      if (p.isIn) {
        open ??= p.time;
      } else if (open != null) {
        total += p.time.difference(open);
        open = null;
      }
    }
    if (open != null) total += now.difference(open);
    return total.isNegative ? Duration.zero : total;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();
    try {
      _punches = await _repository.fetchTodayPunches();
    } catch (e) {
      debugPrint('CheckinController.load failed: $e');
      _error = e;
    } finally {
      _loading = false;
      _notify();
    }
  }

  /// null = نجح، وإلا رسالة الخطأ.
  Future<String?> punch({required bool isIn}) async {
    if (isIn ? !canCheckIn : !canCheckOut) return null;
    _punching = true;
    _notify();
    try {
      final p = await _repository.punch(isIn: isIn);
      _punches = [..._punches, p];
      return null;
    } catch (e) {
      debugPrint('CheckinController.punch failed: $e');
      return hrServerError(e, fallback: EssStrings.punchFailed);
    } finally {
      _punching = false;
      _notify();
    }
  }

  /// GetBuilder يُعاد بناؤه (نفس توقيت notifyListeners السابق)
  void _notify() {
    if (!isClosed) update();
  }
}
