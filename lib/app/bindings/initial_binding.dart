import 'package:get/get.dart';

import '../../data/api/erp_api_client.dart';
import '../../data/api/erp_auth_service.dart';
import '../../modules/statement/repository/erp_statement_repository.dart';
import '../services/session_service.dart';

/// يسجّل الخدمات الدائمة في GetX: **نفس الكائنات** التي أنشأها main()، لا نسخًا
/// جديدة، فـ Get.find والـ repositories القديمة تشير إلى كائن واحد.
///
/// تُستدعى [dependencies] مرة واحدة يدويًا في main() قبل runApp، ولا تُمرَّر إلى
/// GetMaterialApp (الموجود داخل Consumer2)، فلا يوجد مسار يعيد التسجيل.
class InitialBinding extends Bindings {
  InitialBinding({
    required this.session,
    required this.api,
    required this.auth,
    required this.statement,
  });

  final SessionService session;
  final ErpApiClient api;
  final ErpAuthService auth;

  /// R2: أول repository يُنقل إلى GetX (وحدة statement). بقية الـ repositories
  /// ما زالت في MultiProvider حتى تُنقل وحداتها.
  final ErpStatementRepository statement;

  @override
  void dependencies() {
    _putOnce<SessionService>(session);
    _putOnce<ErpApiClient>(api);
    _putOnce<ErpAuthService>(auth);
    _putOnce<ErpStatementRepository>(statement);
  }

  static void _putOnce<T>(T instance) {
    assert(!Get.isRegistered<T>(), '$T registered twice');
    if (!Get.isRegistered<T>()) Get.put<T>(instance, permanent: true);
  }
}
