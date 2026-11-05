import 'package:flutter/foundation.dart';

import '../../../core/constants/ess_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/employee_models.dart';
import '../../../data/repositories/erp_employee_repository.dart';

/// حالة الموظف اليوم حسب آخر بصمة
enum CheckinStatus { notCheckedIn, onDuty, finished }

/// تسجيل الحضور والانصراف في ERPNext (Employee Checkin): بصمات اليوم، والزر
/// المتاح حسب آخر بصمة (آخرها IN ← انصراف، غير ذلك ← حضور).
class CheckinController extends ChangeNotifier {
  CheckinController(this._repository) {
    load();
  }

  final ErpEmployeeRepository _repository;

  bool _loading = false;
  Object? _error;
  bool _punching = false;
  bool _disposed = false;
  List<EmployeeCheckin> _punches = const [];

  bool get loading => _loading;
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
      final detail = e is ErpApiException && e.type == ErpErrorType.server
          ? e.detail
          : null;
      final base = describeError(e, fallback: EssStrings.punchFailed);
      return (detail == null || detail.isEmpty)
          ? base
          : '${EssStrings.punchFailed}\n$detail';
    } finally {
      _punching = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
