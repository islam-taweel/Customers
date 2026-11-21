import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/statement_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/erp_customer.dart';
import '../repository/erp_statement_repository.dart';

/// قائمة عملاء «كشف حساب العملاء»: التحميل والبحث. لا يعرف BuildContext ولا HTTP،
/// يمرّ كل شيء عبر [ErpStatementRepository].
class StatementCustomersController extends GetxController
    with StateMixin<List<ErpCustomer>> {
  StatementCustomersController(this._repo);

  final ErpStatementRepository _repo;

  /// حقل البحث (يُغلق مع المتحكم)
  final search = TextEditingController();

  final customers = <ErpCustomer>[].obs;
  final query = ''.obs;
  final isLoading = true.obs;
  final error = Rxn<Object>();

  /// رقم آخر طلب: تُهمَل نتيجة أي طلب أقدم (كما كان FutureBuilder يتابع الأحدث فقط)
  int _request = 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// لا يرمي أبدًا: الخطأ يُحفظ في [error]
  Future<void> load() async {
    final request = ++_request;
    isLoading.value = true;
    error.value = null;
    // (R7) StateMixin: نفس نقاط الحالة (تحميل ← بيانات/فارغ ← خطأ)
    change(state, status: RxStatus.loading());
    try {
      final list = await _repo.fetchCustomers();
      if (request != _request) return;
      customers.assignAll(list);
      change(
        list,
        status: list.isEmpty ? RxStatus.empty() : RxStatus.success(),
      );
    } catch (e) {
      if (request != _request) return;
      error.value = e;
      change(null, status: RxStatus.error(errorMessage));
    } finally {
      if (request == _request) isLoading.value = false;
    }
  }

  void setQuery(String value) => query.value = value;

  void clearQuery() {
    search.clear();
    query.value = '';
  }

  /// بالاسم أو الرقم أو الهاتف (الأرقام العربية تُطبَّع)
  List<ErpCustomer> get visible {
    final q = normalizeDigits(query.value.trim()).toLowerCase();
    if (q.isEmpty) return customers;
    return [
      for (final c in customers)
        if (c.name.toLowerCase().contains(q) ||
            c.id.toLowerCase().contains(q) ||
            c.phone.contains(q))
          c,
    ];
  }

  String? get errorMessage {
    final e = error.value;
    return e == null
        ? null
        : describeError(e, fallback: StatementStrings.loadFailed);
  }

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }
}
