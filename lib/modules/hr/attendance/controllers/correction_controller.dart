import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../shared/hr_errors.dart';
import '../models/attendance_models.dart';
import '../repository/attendance_repository.dart';

/// نوع التصحيح (يُكتب في explanation لأن Attendance Request لا يحفظه)
enum CorrectionType { forgotCheckIn, forgotCheckOut }

/// حالة الطلب من docstatus: 0 قيد المراجعة، 1 موافق عليه، 2 مرفوض
enum CorrectionStatus { pending, approved, rejected }

CorrectionStatus correctionStatusOf(AttendanceRequestRecord r) =>
    switch (r.docstatus) {
      1 => CorrectionStatus.approved,
      2 => CorrectionStatus.rejected,
      _ => CorrectionStatus.pending,
    };

/// «نسيت البصمة» عبر Attendance Request في ERPNext: الإرسال (مسودة = قيد
/// المراجعة) وقائمة طلباتي. لا موافقة ولا رفض من التطبيق.
class CorrectionController extends GetxController {
  CorrectionController(this._repository);

  final AttendanceRepository _repository;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  bool _loading = false;
  Object? _error;
  bool _sending = false;
  List<AttendanceRequestRecord> _requests = const [];

  bool get loading => _loading;

  /// رسالة الخطأ للعرض (غير مرتبط ← notLinked، 403 ← noPermission)
  String? get errorMessage {
    final e = _error;
    return e == null
        ? null
        : hrErrorMessage(e, fallback: EssStrings.requestsLoadFailed);
  }

  Object? get error => _error;
  bool get sending => _sending;
  List<AttendanceRequestRecord> get requests => _requests;

  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();
    try {
      _requests = await _repository.fetchAttendanceRequests();
    } catch (e) {
      debugPrint('CorrectionController.load failed: $e');
      _error = e;
    } finally {
      _loading = false;
      _notify();
    }
  }

  /// يوجد طلب قيد المراجعة يشمل هذا اليوم
  bool hasPending(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return _requests.any(
      (r) =>
          r.docstatus == 0 && !d.isBefore(r.fromDate) && !d.isAfter(r.toDate),
    );
  }

  /// null = نجح، وإلا رسالة الخطأ. [reason]: On Duty أو Work From Home.
  /// نوع التصحيح والوقت الصحيح والسبب والتوضيحات تُجمع في explanation.
  Future<String?> submit({
    required DateTime date,
    required CorrectionType type,
    required String correctTime,
    required String reason,
    required String userReason,
    String notes = '',
  }) async {
    if (hasPending(date)) return EssStrings.pendingSameDay;
    final isIn = type == CorrectionType.forgotCheckIn;
    final explanation = [
      '${isIn ? EssStrings.forgotCheckIn : EssStrings.forgotCheckOut} — '
          '${isIn ? EssStrings.correctInTime : EssStrings.correctOutTime}: $correctTime',
      userReason.trim(),
      if (notes.trim().isNotEmpty) notes.trim(),
    ].join('\n');

    _sending = true;
    _notify();
    try {
      await _repository.submitAttendanceRequest(
        date: date,
        reason: reason,
        explanation: explanation,
      );
      await load();
      return null;
    } catch (e) {
      debugPrint('CorrectionController.submit failed: $e');
      return hrServerError(e, fallback: EssStrings.requestSendFailed);
    } finally {
      _sending = false;
      _notify();
    }
  }

  /// GetBuilder يُعاد بناؤه (نفس توقيت notifyListeners السابق)
  void _notify() {
    if (!isClosed) update();
  }
}
