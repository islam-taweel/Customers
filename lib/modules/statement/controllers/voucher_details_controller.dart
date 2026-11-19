import 'package:get/get.dart';

import '../../../core/constants/statement_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../repository/erp_statement_repository.dart';

/// مستند واحد من ERPNext كما هو (فاتورة، دفعة، قيد يومية). قد تُفتح عدة شاشات
/// منه فوق بعضها، فيُسجَّل كل متحكم بوسم (tag) خاص بمساره.
class VoucherDetailsController extends GetxController {
  VoucherDetailsController(
    this._repo, {
    required this.doctype,
    required this.name,
  });

  final ErpStatementRepository _repo;
  final String doctype;
  final String name;

  final doc = Rxn<Map<String, dynamic>>();
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
    try {
      final result = await _repo.fetchVoucher(doctype, name);
      if (request != _request) return;
      doc.value = result;
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
        : describeError(e, fallback: StatementStrings.loadFailed);
  }
}
