import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../shared/hr_errors.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/utils/palestine_time.dart';
import '../../../../data/api/erp_api_client.dart';
import '../../expenses/models/expense_models.dart';
import '../repository/expenses_repository.dart';

/// رسالة الخطأ مع نص ERPNext نفسه عند رفض الخادم
String _withDetail(Object e, String fallback) {
  final detail = e is ErpApiException && e.type == ErpErrorType.server
      ? e.detail
      : null;
  final base = describeError(e, fallback: fallback);
  return (detail == null || detail.isEmpty) ? base : '$fallback\n$detail';
}

/// نتيجة الإرسال: [error] فشل الحفظ، و[warning] حُفظ المصروف وفشل رفع الإيصال
typedef ExpenseResult = ({String? error, String? warning});

/// مصاريفي (GetX): طلبات مصاريف الموظف الحالي فقط من ERPNext (تُحدَّث عند فتح
/// الشاشة)، أنواع المصاريف (مواصلات/وجبات) والسلف المفتوحة للربط، وإرسال
/// مصروف مسودة مع صورة الإيصال. لا موافقة ولا اعتماد ولا دفع من التطبيق.
class ExpensesController extends GetxController {
  ExpensesController(this._repository);

  final ExpensesRepository _repository;

  final claims = <ExpenseClaimSummary>[].obs;
  final openAdvances = <OpenAdvance>[].obs;

  /// اسم نوع المصروف في ERPNext لكل نوع في التطبيق (غائب = غير معرّف)
  final types = <ExpenseKind, String>{}.obs;
  final loading = false.obs;
  final sending = false.obs;
  final error = Rxn<Object>();

  /// رسالة الخطأ للعرض (R6: كانت دالة في الواجهة)
  String? get errorMessage {
    final e = error.value;
    return e == null
        ? null
        : hrErrorMessage(e, fallback: EssStrings.expensesLoadFailed);
  }

  @override
  void onInit() {
    super.onInit();
    // تحديث البيانات من ERPNext عند فتح الشاشة
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      claims.assignAll(await _repository.fetchExpenseClaims());
    } catch (e) {
      debugPrint('ExpensesController.load failed: $e');
      error.value = e;
    } finally {
      loading.value = false;
    }
    // الأنواع والسلف للنموذج: فشلها لا يمنع عرض المصاريف
    await Future.wait([_loadTypes(), _loadAdvances()]);
  }

  Future<void> _loadTypes() async {
    try {
      final names = await _repository.fetchExpenseTypes();
      types.assignAll({
        for (final kind in ExpenseKind.values)
          for (final n in names.where(kind.matches).take(1)) kind: n,
      });
    } catch (e) {
      debugPrint('ExpensesController.loadTypes failed: $e');
    }
  }

  Future<void> _loadAdvances() async {
    try {
      openAdvances.assignAll(await _repository.fetchOpenAdvances());
    } catch (e) {
      debugPrint('ExpensesController.loadAdvances failed: $e');
      openAdvances.clear();
    }
  }

  static String? validateAmount(double? amount) =>
      amount == null || amount <= 0 ? EssStrings.amountInvalid : null;

  static String? validateDate(DateTime? date) {
    if (date == null) return EssStrings.requiredField;
    return date.isAfter(PalestineTime.today()) ? EssStrings.futureDate : null;
  }

  Future<ExpenseResult> submit({
    required ExpenseKind kind,
    required double amount,
    required DateTime date,
    required String description,
    OpenAdvance? advance,
    Uint8List? receipt,
    String receiptName = 'receipt.jpg',
  }) async {
    final type = types[kind];
    final invalid =
        (type == null ? EssStrings.typeMissing : null) ??
        validateAmount(amount) ??
        validateDate(date);
    if (invalid != null) return (error: invalid, warning: null);
    if (sending.value) return (error: null, warning: null);

    sending.value = true;
    try {
      final result = await _repository.submitExpense(
        expenseType: type!,
        amount: amount,
        date: date,
        description: description,
        advance: advance,
        receipt: receipt,
        receiptName: receiptName,
      );
      await load();
      final failed = result.attachmentError;
      return (
        error: null,
        warning: failed == null
            ? null
            : EssStrings.expenseSentNoReceipt(
                describeError(failed, fallback: ''),
              ),
      );
    } catch (e) {
      debugPrint('ExpensesController.submit failed: $e');
      return (
        error: _withDetail(e, EssStrings.expenseSendFailed),
        warning: null,
      );
    } finally {
      sending.value = false;
    }
  }
}
