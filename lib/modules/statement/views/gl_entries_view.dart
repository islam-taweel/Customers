import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../bindings/statement_bindings.dart';
import '../controllers/gl_entries_controller.dart';
import '../widgets/gl_ledger_table.dart';

/// القيود المحاسبية للفاتورة على حساب العميل: جدول (البيان، مدين، دائن).
/// المدين = قيمة الفاتورة، والدائن = كل ما سُدد منها (دفعات، رصيد سابق، إشعار دائن).
/// لم يُدفع شيء أو دُفع جزء: غير متوازنة والفرق هو المتبقي. دُفعت كاملة: متوازنة.
///
/// (R4) الحالة في [GlEntriesController]؛ المجاميع من CustomerLedger.
class GlEntriesScreen extends StatelessWidget {
  final String title;

  /// وسم المتحكم لهذا المسار
  final String tag;

  const GlEntriesScreen({super.key, required this.title, required this.tag});

  /// فاتورة مبيعات واحدة
  static Route<void> forInvoice(String invoice) =>
      _route(invoice, (ledger) => ledger.forInvoice(invoice));

  /// كل فواتير طلبية (لا قيود على العميل قبل فوترتها)
  static Route<void> forOrder(String orderId) =>
      _route(orderId, (ledger) => ledger.forOrder(orderId));

  static Route<void> _route(String title, LedgerLoader loader) {
    final tag = nextStatementTag('gl:$title');
    return GetPageRoute<void>(
      settings: const RouteSettings(name: '/gl-entries'),
      binding: GlEntriesBinding(loader, tag: tag),
      transition: Transition.native,
      page: () => GlEntriesScreen(title: title, tag: tag),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<GlEntriesController>(tag: tag);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.glEntriesTitle),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
      // (R7) controller.obx: تحميل / خطأ / فارغ (مسودة فقط) / بيانات
      body: c.obx(
        onLoading: LoadingView(message: AppStrings.glEntriesLoading),
        onError: (message) => ErrorView(message: message!, onRetry: c.load),
        // مسودة فقط (أو لا شيء بعد): لا قيود قبل الاعتماد
        onEmpty: Builder(
          builder: (_) => EmptyView(
            icon: Icons.account_balance_outlined,
            title: AppStrings.glEntriesEmptyTitle,
            message: c.emptyMessage,
          ),
        ),
        (state) {
          final ledger = state!;
          return RefreshIndicator(
            onRefresh: c.load,
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.pagePadding),
              children: [
                GlLedgerTable(ledger: ledger),
                const SizedBox(height: 16),
                GlTotals(ledger: ledger),
              ],
            ),
          );
        },
      ),
    );
  }
}
