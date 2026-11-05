import 'package:flutter/foundation.dart';

import '../../../core/constants/ess_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/leave_models.dart';
import '../../../data/repositories/erp_employee_repository.dart';

/// رسالة رفض الخادم بالعربية: الرصيد غير كافٍ، تداخل مع طلب آخر، لا تخصيص.
/// غير ذلك: الرسالة العامة مع نص ERPNext نفسه.
String _leaveError(Object e) {
  final detail =
      e is ErpApiException && e.type == ErpErrorType.server ? e.detail : null;
  if (detail != null && detail.isNotEmpty) {
    final d = detail.toLowerCase();
    if (d.contains('insufficient') ||
        d.contains('not enough') ||
        d.contains('balance')) {
      return EssStrings.insufficientBalance;
    }
    if (d.contains('overlap') || d.contains('already applied')) {
      return EssStrings.leaveOverlap;
    }
    if (d.contains('no leave record') || d.contains('allocation')) {
      return EssStrings.noAllocation;
    }
    return '${EssStrings.leaveSendFailed}\n$detail';
  }
  return describeError(e, fallback: EssStrings.leaveSendFailed);
}

/// الإجازات من ERPNext: الأرصدة، نموذج الطلب (مع عدد الأيام من ERPNext)،
/// والطلبات السابقة.
class LeavesController extends ChangeNotifier {
  LeavesController(this._repository) {
    load();
  }

  final ErpEmployeeRepository _repository;

  bool _loading = false;
  Object? _error;
  bool _disposed = false;
  LeaveDetails _details =
      const LeaveDetails(balances: [], withoutPayTypes: []);
  List<LeaveRequest> _requests = const [];

  // النموذج
  String? _type;
  DateTime? _from;
  DateTime? _to;
  double? _days;
  bool _daysFromErp = false;
  bool _countingDays = false;
  bool _sending = false;
  int _countToken = 0;
  String reason = '';

  bool get loading => _loading;
  Object? get error => _error;
  LeaveDetails get details => _details;
  List<LeaveRequest> get requests => _requests;
  String? get type => _type;
  DateTime? get from => _from;
  DateTime? get to => _to;
  double? get days => _days;
  bool get daysFromErp => _daysFromErp;
  bool get countingDays => _countingDays;
  bool get sending => _sending;
  bool get isWithoutPay => _type != null && _details.isWithoutPay(_type!);

  /// خطأ التاريخين يظهر فورًا دون انتظار الإرسال
  bool get endBeforeStart =>
      _from != null && _to != null && _to!.isBefore(_from!);

  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();
    try {
      final results = await Future.wait([
        _repository.fetchLeaveDetails(),
        _repository.fetchLeaveRequests(),
      ]);
      _details = results[0] as LeaveDetails;
      _requests = results[1] as List<LeaveRequest>;
      if (_type != null && !_details.types.contains(_type)) _type = null;
    } catch (e) {
      debugPrint('LeavesController.load failed: $e');
      _error = e;
    } finally {
      _loading = false;
      _notify();
    }
  }

  void setType(String? value) {
    _type = value;
    _notify();
    _countDays();
  }

  void setFrom(DateTime value) {
    _from = value;
    // النهاية تتبع البداية إن لم تُحدَّد أو صارت قبلها
    if (_to == null || _to!.isBefore(value)) _to = value;
    _notify();
    _countDays();
  }

  void setTo(DateTime value) {
    _to = value;
    _notify();
    _countDays();
  }

  /// أيام الطلب: من ERPNext (يستثني العطل حسب النوع)، وإلا أيام التقويم شاملة.
  Future<void> _countDays() async {
    final type = _type, from = _from, to = _to;
    if (from == null || to == null || to.isBefore(from)) {
      _days = null;
      _notify();
      return;
    }
    final calendar = to.difference(from).inDays + 1.0;
    final token = ++_countToken;
    _days = calendar;
    _daysFromErp = false;
    if (type == null) {
      _notify();
      return;
    }
    _countingDays = true;
    _notify();
    try {
      final erp = await _repository.leaveDays(
        leaveType: type,
        from: from,
        to: to,
      );
      if (token != _countToken) return; // تغيّر النموذج أثناء الحساب
      _days = erp;
      _daysFromErp = true;
    } catch (e) {
      debugPrint('LeavesController.countDays failed: $e');
    } finally {
      if (token == _countToken) {
        _countingDays = false;
        _notify();
      }
    }
  }

  /// null = صالح. الحقول المطلوبة، ترتيب التاريخين، والرصيد للأنواع المخصصة.
  String? validate() {
    if (_type == null || _from == null || _to == null || reason.trim().isEmpty) {
      return EssStrings.requiredField;
    }
    if (endBeforeStart) return EssStrings.endBeforeStart;
    final balance = _details.balanceOf(_type!);
    final days = _days;
    if (balance != null && days != null && days > balance.remaining + 1e-9) {
      return EssStrings.exceedsBalance(EssStrings.daysValue(balance.remaining));
    }
    return null;
  }

  /// null = نجح، وإلا رسالة الخطأ.
  Future<String?> submit() async {
    final invalid = validate();
    if (invalid != null) return invalid;
    _sending = true;
    _notify();
    try {
      await _repository.submitLeave(
        leaveType: _type!,
        from: _from!,
        to: _to!,
        reason: reason,
      );
      _type = null;
      _from = null;
      _to = null;
      _days = null;
      reason = '';
      await load();
      return null;
    } catch (e) {
      debugPrint('LeavesController.submit failed: $e');
      return _leaveError(e);
    } finally {
      _sending = false;
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
