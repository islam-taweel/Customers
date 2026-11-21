import 'package:flutter/material.dart' show DateTimeRange;
import 'package:get/get.dart';

import '../../../core/constants/statement_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/erp_customer.dart';
import '../models/statement_models.dart';
import '../repository/erp_statement_repository.dart';

/// كشف حساب عميل واحد: الفترة (كل الفترات افتراضيًا) والتحميل. اختيار الفترة
/// (منتقي التاريخ) في الواجهة، والمتحكم يستلم النتيجة فقط.
class CustomerStatementController extends GetxController
    with StateMixin<CustomerStatement> {
  CustomerStatementController(this._repo, this.customer);

  final ErpStatementRepository _repo;
  final ErpCustomer customer;

  final range = Rxn<DateTimeRange>();
  final statement = Rxn<CustomerStatement>();
  final isLoading = true.obs;
  final error = Rxn<Object>();

  int _request = 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final request = ++_request;
    isLoading.value = true;
    error.value = null;
    // (R7) StateMixin: نفس نقاط الحالة (تحميل ← بيانات/فارغ ← خطأ)
    change(state, status: RxStatus.loading());
    try {
      final result = await _repo.fetchStatement(
        customer.id,
        from: range.value?.start,
        to: range.value?.end,
      );
      if (request != _request) return;
      statement.value = result;
      change(
        result,
        status: result.lines.isEmpty ? RxStatus.empty() : RxStatus.success(),
      );
    } catch (e) {
      if (request != _request) return;
      error.value = e;
      change(null, status: RxStatus.error(errorMessage));
    } finally {
      if (request == _request) isLoading.value = false;
    }
  }

  Future<void> setRange(DateTimeRange picked) {
    range.value = picked;
    return load();
  }

  Future<void> clearRange() {
    range.value = null;
    return load();
  }

  /// بلا صلاحية GL Entry ← رسالة «يحتاج دور محاسبة»
  String? get errorMessage {
    final e = error.value;
    if (e == null) return null;
    return e is ErpApiException && e.type == ErpErrorType.forbidden
        ? StatementStrings.needsAccountsRole
        : describeError(e, fallback: StatementStrings.loadFailed);
  }
}
