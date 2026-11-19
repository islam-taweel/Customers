import '../../../core/constants/ess_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/api/erp_api_client.dart';
import 'repository/hr_employee_identity.dart';

/// رسالة خطأ شاشات HR: غير مرتبط بموظف ← notLinked، 403 ← noPermission،
/// وإلا الرسالة العامة.
///
/// (R5) بديل الدالة `_message` التي كانت مكررة حرفيًا في كل شاشة.
/// [notLinked] = false للشاشات التي لم تكن تفحصه (مثل «فريقي»).
String hrErrorMessage(
  Object e, {
  required String fallback,
  bool notLinked = true,
}) {
  if (notLinked && e is EmployeeNotLinkedException) return EssStrings.notLinked;
  if (e is ErpApiException && e.type == ErpErrorType.forbidden) {
    return EssStrings.noPermission;
  }
  return describeError(e, fallback: fallback);
}

/// «الرسالة العامة\nنص ERPNext» عند رفض الخادم، وإلا الرسالة العامة (نفس صيغة
/// متحكمات البصمة وطلب الحضور).
String hrServerError(Object e, {required String fallback}) {
  final detail = e is ErpApiException && e.type == ErpErrorType.server
      ? e.detail
      : null;
  final base = describeError(e, fallback: fallback);
  return (detail == null || detail.isEmpty) ? base : '$fallback\n$detail';
}
