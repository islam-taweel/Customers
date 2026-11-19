import 'package:customer/data/models/erp_customer.dart';
import 'package:customer/modules/statement/controllers/statement_customers_controller.dart';
import 'package:customer/modules/statement/controllers/voucher_details_controller.dart';
import 'package:customer/modules/statement/models/statement_models.dart';
import 'package:customer/modules/statement/repository/erp_statement_repository.dart';
import 'package:customer/modules/statement/views/customer_statement_list_view.dart';
import 'package:customer/modules/statement/views/voucher_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Repo implements ErpStatementRepository {
  int customerCalls = 0;
  final voucherCalls = <String>[];

  @override
  Future<List<ErpCustomer>> fetchCustomers() async {
    customerCalls++;
    return const [ErpCustomer(id: 'CUST-001', name: 'Ahmad', phone: '')];
  }

  @override
  Future<CustomerStatement> fetchStatement(
    String customerId, {
    DateTime? from,
    DateTime? to,
  }) async => const CustomerStatement(opening: 0, lines: []);

  @override
  Future<Map<String, dynamic>> fetchVoucher(String doctype, String name) async {
    voucherCalls.add('$doctype/$name');
    return {
      'name': name,
      'docstatus': 1,
      'references': [
        {
          'reference_doctype': 'Sales Invoice',
          'reference_name': 'SINV-9',
          'allocated_amount': 10,
        },
      ],
    };
  }
}

/// الشاشات تُفتح بنفس الواجهة القديمة (Navigator.push(X.route(...)))، وكل متحكم
/// يُنشأ مرة واحدة ويُحذف مع مساره، والـ repository الدائم يبقى.
void main() {
  late _Repo repo;
  late GlobalKey<NavigatorState> nav;

  setUp(() {
    repo = _Repo();
    nav = GlobalKey<NavigatorState>();
    Get.put<ErpStatementRepository>(repo, permanent: true);
  });

  tearDown(Get.reset);

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    GetMaterialApp(navigatorKey: nav, home: const Scaffold()),
  );

  testWidgets('القائمة: طلب واحد، والمتحكم يُحذف عند الرجوع', (tester) async {
    await pumpApp(tester);
    nav.currentState!.push(CustomerStatementListScreen.route());
    await tester.pumpAndSettle();

    expect(find.text('Ahmad'), findsOneWidget);
    expect(repo.customerCalls, 1, reason: 'لا طلبات مكررة مع إعادة البناء');
    expect(Get.isRegistered<StatementCustomersController>(), isTrue);

    // إعادة بناء (مثل كتابة في البحث) لا تنشئ متحكمًا ولا طلبًا جديدًا
    await tester.enterText(find.byType(TextField), 'ah');
    await tester.pumpAndSettle();
    expect(repo.customerCalls, 1);
    expect(find.byIcon(Icons.clear), findsOneWidget);

    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(Get.isRegistered<StatementCustomersController>(), isFalse);
    expect(Get.isRegistered<ErpStatementRepository>(), isTrue);
  });

  testWidgets('المستندات المتداخلة: متحكم لكل مسار، ويُحذف كل منها مع مساره', (
    tester,
  ) async {
    await pumpApp(tester);
    // كما في payments_tabs.dart
    nav.currentState!.push(VoucherDetailsScreen.route('Payment Entry', 'PE-1'));
    await tester.pumpAndSettle();

    // الضغط على الفاتورة المخصص لها يفتح مستندًا ثانيًا فوقه
    await tester.tap(find.text('SINV-9'));
    await tester.pumpAndSettle();
    expect(repo.voucherCalls, ['Payment Entry/PE-1', 'Sales Invoice/SINV-9']);

    VoucherDetailsController top() => Get.find<VoucherDetailsController>(
      tag: tester
          .widget<VoucherDetailsScreen>(find.byType(VoucherDetailsScreen).last)
          .tag,
    );
    expect(top().name, 'SINV-9');
    final firstTag = tester
        .widget<VoucherDetailsScreen>(
          find.byType(VoucherDetailsScreen, skipOffstage: false).first,
        )
        .tag;
    final topTag = tester
        .widget<VoucherDetailsScreen>(find.byType(VoucherDetailsScreen).last)
        .tag;
    expect(firstTag == topTag, isFalse);

    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(Get.isRegistered<VoucherDetailsController>(tag: topTag), isFalse);
    expect(Get.isRegistered<VoucherDetailsController>(tag: firstTag), isTrue);
    expect(Get.find<VoucherDetailsController>(tag: firstTag).name, 'PE-1');
    expect(repo.voucherCalls.length, 2, reason: 'الرجوع لا يعيد الطلب');

    nav.currentState!.pop();
    await tester.pumpAndSettle();
    expect(Get.isRegistered<VoucherDetailsController>(tag: firstTag), isFalse);
  });
}
