import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../models/gl_entry.dart';
import '../repository/erp_ledger_repository.dart';

/// ما تحمّله الشاشة: فاتورة واحدة (forInvoice) أو كل فواتير طلبية (forOrder)
typedef LedgerLoader = Future<CustomerLedger> Function(
  ErpLedgerRepository ledger,
);

/// القيود المحاسبية على حساب العميل لفاتورة أو طلبية (للقراءة فقط).
/// المجاميع والتوازن والفرق تُحسب في [CustomerLedger] نفسه (لا في الواجهة).
///
/// (R4) بديل FutureBuilder في GlEntriesScreen: نفس الطلبات ونفس الرسائل.
class GlEntriesController extends GetxController {
  GlEntriesController(this._repository, this._loader);

  final ErpLedgerRepository _repository;
  final LedgerLoader _loader;

  final ledger = Rxn<CustomerLedger>();
  final isLoading = true.obs;
  final error = Rxn<Object>();

  int _request = 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// لا يرمي: الخطأ في [error]. يُهمل رد أي طلب أقدم (كما كان FutureBuilder).
  Future<void> load() async {
    final request = ++_request;
    isLoading.value = true;
    error.value = null;
    try {
      final result = await _loader(_repository);
      if (request != _request) return;
      ledger.value = result;
    } catch (e) {
      if (request != _request) return;
      error.value = e;
    } finally {
      if (request == _request) isLoading.value = false;
    }
  }

  String? get errorMessage {
    final e = error.value;
    return e == null
        ? null
        : describeError(e, fallback: AppStrings.glEntriesLoadFailed);
  }

  /// لا قيود بعد: مسودة فقط (أو لا شيء)
  String get emptyMessage {
    final drafts = ledger.value?.drafts ?? const [];
    return drafts.isNotEmpty
        ? AppStrings.glDraftsPending(drafts.map((d) => d.name).join('، '))
        : AppStrings.glEntriesEmptyMessage;
  }
}
