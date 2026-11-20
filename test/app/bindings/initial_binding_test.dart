import 'package:customer/app/bindings/initial_binding.dart';
import 'package:customer/app/services/session_service.dart';
import 'package:customer/data/api/erp_api_client.dart';
import 'package:customer/data/api/erp_auth_service.dart';
import 'package:customer/data/api/session_store.dart';
import 'package:customer/data/database/database_helper.dart';
import 'package:customer/data/repositories/erp_cache_store.dart';
import 'package:customer/data/repositories/erp_customer_repository.dart';
import 'package:customer/data/repositories/erp_lookup_repository.dart';
import 'package:customer/data/repositories/invoice_repository.dart';
import 'package:customer/modules/collections/repository/erp_payment_repository.dart';
import 'package:customer/modules/collections/repository/invoice_collections_repository.dart';
import 'package:customer/modules/hr/advances/repository/advances_repository.dart';
import 'package:customer/modules/hr/attendance/repository/attendance_repository.dart';
import 'package:customer/modules/hr/expenses/repository/expenses_repository.dart';
import 'package:customer/modules/hr/leaves/repository/leaves_repository.dart';
import 'package:customer/modules/hr/overtime/repository/overtime_repository.dart';
import 'package:customer/modules/hr/payslips/repository/payslips_repository.dart';
import 'package:customer/modules/hr/profile/repository/profile_repository.dart';
import 'package:customer/modules/hr/punch/repository/punch_repository.dart';
import 'package:customer/modules/hr/shared/hr_approver_access.dart';
import 'package:customer/modules/hr/shared/hr_repositories.dart';
import 'package:customer/modules/hr/shared/repository/hr_employee_identity.dart';
import 'package:customer/modules/hr/team/repository/team_repository.dart';
import 'package:customer/modules/invoices/repository/sales_invoices_repository.dart';
import 'package:customer/modules/statement/repository/erp_ledger_repository.dart';
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
    // لا يُفتح ملف قاعدة البيانات: الكائنات تُنشأ فقط ولا تُستدعى
    final db = DatabaseHelper.instance;
    final cache = ErpCacheStore(db);

    final statement = ErpStatementRepository(api, ErpCustomerRepository(api));
    final salesInvoices = ErpSalesInvoicesRepository(api, cache);
    final collections = ErpInvoiceCollectionsRepository(
      api,
      cache,
      ErpLookupRepository(api, cache),
    );
    final payments = ErpPaymentRepository(api);
    final ledger = ErpLedgerRepository(api);
    final localInvoices = InvoiceRepository(db);
    final hr = HrRepositories(api);
    InitialBinding(
      session: session,
      api: api,
      auth: auth,
      statement: statement,
      ledger: ledger,
      salesInvoices: salesInvoices,
      invoiceCollections: collections,
      payments: payments,
      localInvoices: localInvoices,
      hr: hr,
    ).dependencies();

    expect(identical(Get.find<SessionService>(), session), isTrue);
    expect(identical(Get.find<ErpApiClient>(), api), isTrue);
    expect(identical(Get.find<ErpAuthService>(), auth), isTrue);
    expect(identical(Get.find<SessionService>().store, store), isTrue);
    expect(identical(Get.find<ErpStatementRepository>(), statement), isTrue);
    expect(
      identical(Get.find<ErpSalesInvoicesRepository>(), salesInvoices),
      isTrue,
    );
    expect(
      identical(Get.find<ErpInvoiceCollectionsRepository>(), collections),
      isTrue,
    );
    expect(identical(Get.find<ErpPaymentRepository>(), payments), isTrue);
    expect(identical(Get.find<ErpLedgerRepository>(), ledger), isTrue);
    expect(identical(Get.find<InvoiceRepository>(), localInvoices), isTrue);

    // HR: كل repository كائن واحد، لا نسخ مكررة
    expect(identical(Get.find<HrEmployeeIdentity>(), hr.identity), isTrue);
    expect(identical(Get.find<ProfileRepository>(), hr.profile), isTrue);
    expect(identical(Get.find<PunchRepository>(), hr.punch), isTrue);
    expect(identical(Get.find<AttendanceRepository>(), hr.attendance), isTrue);
    expect(identical(Get.find<LeavesRepository>(), hr.leaves), isTrue);
    expect(identical(Get.find<OvertimeRepository>(), hr.overtime), isTrue);
    expect(identical(Get.find<AdvancesRepository>(), hr.advances), isTrue);
    expect(identical(Get.find<ExpensesRepository>(), hr.expenses), isTrue);
    expect(identical(Get.find<PayslipsRepository>(), hr.payslips), isTrue);
    expect(identical(Get.find<TeamRepository>(), hr.team), isTrue);

    // صلاحية المعتمِد (يقرؤها ManagerMiddleware): مسجّلة، وافتراضيًا لا صلاحية
    expect(Get.find<HrApproverAccess>().canSeeTeam, isFalse);
  });
}