import 'package:customer/app/bindings/initial_binding.dart';
import 'package:customer/app/services/session_service.dart';
import 'package:customer/data/api/erp_api_client.dart';
import 'package:customer/data/api/erp_auth_service.dart';
import 'package:customer/data/api/session_store.dart';
import 'package:customer/data/repositories/erp_customer_repository.dart';
import 'package:customer/modules/statement/repository/erp_statement_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// InitialBinding يسجّل نفس الكائنات التي أُنشئت في main، ولا ينشئ نسخًا.
void main() {
  tearDown(Get.reset);

  test('Get.find يعيد نفس الكائنات المسجّلة، وكلها على store واحد', () {
    final store = SessionStore();
    final auth = ErpAuthService(store);
    final session = SessionService(store, auth);
    final api = ErpApiClient(session: store);

    final statement = ErpStatementRepository(api, ErpCustomerRepository(api));
    InitialBinding(
      session: session,
      api: api,
      auth: auth,
      statement: statement,
    ).dependencies();

    expect(identical(Get.find<SessionService>(), session), isTrue);
    expect(identical(Get.find<ErpApiClient>(), api), isTrue);
    expect(identical(Get.find<ErpAuthService>(), auth), isTrue);
    expect(identical(Get.find<SessionService>().store, store), isTrue);
    expect(identical(Get.find<ErpStatementRepository>(), statement), isTrue);
  });
}
