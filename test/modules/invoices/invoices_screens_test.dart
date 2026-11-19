import 'package:customer/core/constants/app_strings.dart';
import 'package:customer/data/repositories/invoice_repository.dart';
import 'package:customer/modules/collections/bindings/collections_bindings.dart';
import 'package:customer/modules/collections/controllers/customer_collections_controller.dart';
import 'package:customer/modules/collections/controllers/invoice_collections_controller.dart';
import 'package:customer/modules/collections/controllers/payment_sheet_controller.dart';
import 'package:customer/modules/collections/repository/erp_payment_repository.dart';
import 'package:customer/modules/collections/repository/invoice_collections_repository.dart';
import 'package:customer/modules/collections/widgets/payments_tabs.dart';
import 'package:customer/modules/invoices/bindings/invoices_bindings.dart';
import 'package:customer/modules/invoices/controllers/sales_invoices_controller.dart';
import 'package:customer/modules/invoices/repository/sales_invoices_repository.dart';
import 'package:customer/modules/invoices/views/invoices_tabs_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../collections/customer_collections_test.dart' show FakeHost, pe;
import '../support/fakes.dart';

/// R3 — الشاشات: قسم الفواتير بمساره (GetPageRoute + Bindings)، نافذة الدفع،
/// وتبويبات تحصيلات العميل. لا متحكم يُنشأ مرتين، وكل متحكم يُحذف مع مساره.
void main() {
  late GlobalKey<NavigatorState> nav;
  late List<Sent> sent;

  setUp(() => nav = GlobalKey<NavigatorState>());
  tearDown(Get.reset);

  Future<void> register() async {
    final f = await fakeApi((r) {
      if (r.pathText == 'api/resource/Sales Invoice') {
        return {
          'data': [
            invoiceRow('SINV-1', total: 250, outstanding: 250),
            invoiceRow('SINV-3', outstanding: 0, status: 'Paid'),
          ],
        };
      }
      if (r.method == 'DELETE') return {'message': 'ok'};
      if (r.pathText == 'api/resource/Payment Entry') {
        return {
          'data': [
            if (!sent.any((s) => s.method == 'DELETE')) pe('PE-9', 0, 30),
          ],
        };
      }
      return {'data': []};
    });
    sent = f.sent;
    final cache = MemoryCache();
    Get.put(ErpSalesInvoicesRepository(f.api, cache), permanent: true);
    Get.put(
      ErpInvoiceCollectionsRepository(
        f.api,
        cache,
        FakeLookup()..modes = ['Cash'],
      ),
      permanent: true,
    );
    Get.put(ErpPaymentRepository(f.api), permanent: true);
    Get.put<InvoiceRepository>(FakeLocalInvoices(), permanent: true);
  }

  /// نفس مسار OrdersScreen.route() لكن بقسم الفواتير وحده (بلا OrdersController)
  Route<void> invoicesRoute() => GetPageRoute<void>(
    bindings: [InvoiceCollectionsBinding(), SalesInvoicesBinding()],
    page: () => const InvoicesTabsView(),
  );

  testWidgets(
    'قسم الفواتير: طلب واحد، دفع ← مسودة، والمتحكمات تُحذف مع المسار',
    (tester) async {
      await tester.runAsync(register);

      await tester.pumpWidget(
        GetMaterialApp(navigatorKey: nav, home: const Scaffold()),
      );
      nav.currentState!.push(invoicesRoute());
      await tester.runAsync(() => pumpEventQueue(times: 50));
      await tester.pumpAndSettle();

      // تبويب «غير مدفوعة»
      await tester.tap(find.text(AppStrings.tabUnpaid));
      await tester.pumpAndSettle();
      expect(find.text('SINV-1'), findsOneWidget);
      expect(
        sent.where((s) => s.pathText == 'api/resource/Sales Invoice').length,
        1,
      );

      // «دفع» يفتح النافذة بمتحكم خاص بها
      await tester.tap(find.text(AppStrings.payAction));
      await tester.runAsync(() => pumpEventQueue(times: 20));
      await tester.pumpAndSettle();
      expect(
        Get.isRegistered<PaymentSheetController>(tag: 'pay:SINV-1#1'),
        isTrue,
      );
      await tester.enterText(find.byType(TextField).first, '300');
      await tester.pump();
      final sheet = Get.find<PaymentSheetController>(tag: 'pay:SINV-1#1');
      expect(sheet.amountWarning, isNotNull, reason: 'أكثر من المستحق');
      expect(sheet.canSave, isFalse);

      // إغلاق النافذة ← حذف متحكمها بعد إزالتها من الشجرة
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(
        Get.isRegistered<PaymentSheetController>(tag: 'pay:SINV-1#1'),
        isFalse,
      );

      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(Get.isRegistered<SalesInvoicesController>(), isFalse);
      expect(Get.isRegistered<InvoiceCollectionsController>(), isFalse);
      expect(Get.isRegistered<ErpSalesInvoicesRepository>(), isTrue);
    },
  );

  testWidgets('تبويبات تحصيلات العميل: حذف مسودة من الواجهة بعد التأكيد', (
    tester,
  ) async {
    await tester.runAsync(register);
    final tag = nextCollectionsTag('customer:1');
    CustomerCollectionsBinding(FakeHost(), tag: tag).dependencies();

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: PaymentsTabs(tag: tag)),
        ),
      ),
    );
    await tester.runAsync(() => pumpEventQueue(times: 20));
    await tester.pumpAndSettle();
    expect(find.text('PE-9  •  2026-11-18  •  Cash'), findsOneWidget);

    await tester.tap(find.text(AppStrings.paymentCancel));
    await tester.pumpAndSettle();
    // نافذة التأكيد: زر التأكيد بنفس النص
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.paymentCancel),
    );
    await tester.runAsync(() => pumpEventQueue(times: 20));
    await tester.pumpAndSettle();

    expect(
      sent.where((s) => s.method == 'DELETE').single.pathText,
      'api/resource/Payment Entry/PE-9',
    );
    expect(find.text(AppStrings.paymentCancelled), findsOneWidget);
    expect(find.text(AppStrings.paymentsDraftEmpty), findsOneWidget);
    expect(Get.find<CustomerCollectionsController>(tag: tag).drafts, isEmpty);
  });
}
