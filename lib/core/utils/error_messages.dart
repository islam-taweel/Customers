import 'package:flutter/foundation.dart';

import '../../data/api/erp_api_client.dart';
import '../constants/app_strings.dart';

/// رسالة مفهومة للمستخدم من أي خطأ. أخطاء ERPNext لكل نوع منها رسالة تدل على
/// السبب (جلسة، صلاحية، اتصال...)، وغيرها يأخذ [fallback].
/// في وضع التطوير (debug) يُضاف نص الخطأ من ردّ ERPNext نفسه، لأنه يدل على
/// المشكلة بالضبط (مثل: Field not permitted in query).
String describeError(Object error, {required String fallback}) {
  if (error is! ErpApiException) return fallback;

  final message = switch (error.type) {
    ErpErrorType.sessionExpired => AppStrings.erpSessionExpired,
    ErpErrorType.forbidden => AppStrings.erpForbidden,
    ErpErrorType.network => AppStrings.erpNetworkError,
    ErpErrorType.notFound => AppStrings.erpNotFound,
    ErpErrorType.server ||
    ErpErrorType.badResponse => AppStrings.erpServerError,
  };
  final detail = error.detail;
  if (!kDebugMode || detail == null || detail.isEmpty) return message;
  final status = error.statusCode == null ? '' : '[${error.statusCode}] ';
  return '$message\n$status$detail';
}
