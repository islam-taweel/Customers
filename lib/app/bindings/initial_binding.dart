import 'package:get/get.dart';

import '../../data/api/erp_api_client.dart';
import '../../data/api/erp_auth_service.dart';
import '../../data/repositories/erp_employee_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../modules/collections/repository/erp_payment_repository.dart';
import '../../modules/collections/repository/invoice_collections_repository.dart';
import '../../modules/hr/attendance/repository/attendance_repository.dart';
import '../../modules/hr/leaves/repository/leaves_repository.dart';
import '../../modules/hr/profile/repository/profile_repository.dart';
import '../../modules/hr/punch/repository/punch_repository.dart';
import '../../modules/hr/shared/hr_repositories.dart';
import '../../modules/hr/shared/repository/hr_employee_identity.dart';
import '../../modules/invoices/repository/sales_invoices_repository.dart';
import '../../modules/statement/repository/erp_ledger_repository.dart';
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
    required this.ledger,
    required this.salesInvoices,
    required this.invoiceCollections,
    required this.payments,
    required this.localInvoices,
    required this.hr,
  });

  final SessionService session;
  final ErpApiClient api;
  final ErpAuthService auth;

  /// R2: وحدة statement
  final ErpStatementRepository statement;

  /// R4: القيود المحاسبية (GL Entries). نفس الكائن ما زال في MultiProvider لأن
  /// order_details_screen يقرؤه منه (orderInvoices).
  final ErpLedgerRepository ledger;

  /// R3: وحدة invoices (قائمة فواتير المبيعات)
  final ErpSalesInvoicesRepository salesInvoices;

  /// R3: وحدة collections (تحصيل الفواتير، ودفعات العميل في ERPNext).
  /// [payments] نفس الكائن الذي يستخدمه CustomerDetailsController (Provider).
  final ErpInvoiceCollectionsRepository invoiceCollections;
  final ErpPaymentRepository payments;

  /// فواتير الطلبيات المحلية (ما زالت في MultiProvider أيضًا لمستهلكيها القدامى)
  final InvoiceRepository localInvoices;

  /// R5: repositories الموارد البشرية (وhr.legacy لوحدات R6 حتى ترحيلها)
  final HrRepositories hr;

  @override
  void dependencies() {
    _putOnce<SessionService>(session);
    _putOnce<ErpApiClient>(api);
    _putOnce<ErpAuthService>(auth);
    _putOnce<ErpStatementRepository>(statement);
    _putOnce<ErpLedgerRepository>(ledger);
    _putOnce<ErpSalesInvoicesRepository>(salesInvoices);
    _putOnce<ErpInvoiceCollectionsRepository>(invoiceCollections);
    _putOnce<ErpPaymentRepository>(payments);
    _putOnce<InvoiceRepository>(localInvoices);
    _putOnce<HrEmployeeIdentity>(hr.identity);
    _putOnce<ProfileRepository>(hr.profile);
    _putOnce<PunchRepository>(hr.punch);
    _putOnce<AttendanceRepository>(hr.attendance);
    _putOnce<LeavesRepository>(hr.leaves);
    _putOnce<ErpEmployeeRepository>(hr.legacy);
  }

  static void _putOnce<T>(T instance) {
    assert(!Get.isRegistered<T>(), '$T registered twice');
    if (!Get.isRegistered<T>()) Get.put<T>(instance, permanent: true);
  }
}
