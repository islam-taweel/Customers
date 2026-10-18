import '../../data/api/erp_api_client.dart';
import '../constants/app_strings.dart';

/// رسالة مفهومة للمستخدم من أي خطأ. أخطاء ERPNext لكل نوع منها رسالة تدل على
/// السبب (مفاتيح، اتصال...)، وغيرها يأخذ [fallback].
String describeError(Object error, {required String fallback}) {
  if (error is! ErpApiException) return fallback;

  return switch (error.type) {
    ErpErrorType.missingCredentials => AppStrings.erpMissingCredentials,
    ErpErrorType.unauthorized => AppStrings.erpUnauthorized,
    ErpErrorType.network => AppStrings.erpNetworkError,
    ErpErrorType.notFound => AppStrings.erpNotFound,
    ErpErrorType.server || ErpErrorType.badResponse => AppStrings.erpServerError,
  };
}
