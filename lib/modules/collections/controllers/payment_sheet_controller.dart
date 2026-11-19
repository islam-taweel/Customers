import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/sales_invoice.dart';
import '../models/collection_models.dart';
import 'invoice_collections_controller.dart';

/// نوع طريقة الدفع بحسب اسمها في ERPNext: يحدد الحقول المطلوبة.
/// أي طريقة غير نقدية لا تُعرف تُعامل كتحويل عام: رقم مرجع وتاريخ مطلوبان.
enum PaymentModeKind { cash, cheque, card, transfer, other }

PaymentModeKind paymentModeKindOf(String? mode) {
  final m = (mode ?? '').toLowerCase().trim();
  if (m.isEmpty) return PaymentModeKind.cash;
  if (m.contains('cheque') || m.contains('check')) {
    return PaymentModeKind.cheque;
  }
  if (m.contains('card')) return PaymentModeKind.card;
  if (m.contains('transfer')) return PaymentModeKind.transfer;
  if (m == 'cash') return PaymentModeKind.cash;
  return PaymentModeKind.other;
}

/// نموذج «دفع فاتورة» (مسودة تحصيل): طرق الدفع، الحقول، التحقق، الحفظ.
/// نُقل منطقه كما هو من حالة النافذة القديمة؛ حقول النص (TextEditingController)
/// تبقى في الواجهة وتُرسل قيمها هنا مع كل تغيير.
class PaymentSheetController extends GetxController {
  PaymentSheetController(this.invoice, this._collections);

  final SalesInvoice invoice;
  final InvoiceCollectionsController _collections;

  final modes = <String>[].obs;
  final modesLoading = true.obs;
  final modesFailed = false.obs;
  final mode = RxnString();

  // قيم الحقول كما في الواجهة
  final amountText = ''.obs;
  final note = ''.obs;
  final referenceNo = ''.obs;
  final chequeBank = ''.obs;
  final drawerName = ''.obs;
  final cardLast4 = ''.obs;
  final cardBrand = ''.obs;
  final senderBank = ''.obs;
  final referenceDate = Rxn<DateTime>();

  final saving = false.obs;
  final saveError = RxnString();

  double get due => invoice.outstandingAmount;

  String get dueText => formatAmount(
    due,
    currency: displayCurrency(
      invoice.settlement?.displayIn(invoice.currency) ?? invoice.currency,
    ),
  );

  PaymentModeKind get kind => paymentModeKindOf(mode.value);

  @override
  void onInit() {
    super.onInit();
    loadModes();
  }

  Future<void> loadModes() async {
    modesLoading.value = true;
    modesFailed.value = false;
    try {
      final list = await _collections.modesOfPayment();
      if (isClosed) return;
      modes.assignAll(list);
      modesFailed.value = list.isEmpty;
      modesLoading.value = false;
      // طريقة واحدة فقط: نختارها تلقائيًا
      if (list.length == 1) mode.value = list.first;
    } catch (_) {
      if (isClosed) return;
      modesFailed.value = true;
      modesLoading.value = false;
    }
  }

  void selectMode(String? value) => mode.value = value;

  /// null = لم يُكتب شيء بعد (بلا تحذير)
  double? get amount => parseAmount(amountText.value);

  /// تحذير المبلغ: صفر أو سالب، أو أكثر من المستحق، أو نص غير صالح
  String? get amountWarning {
    if (amountText.value.trim().isEmpty) return null;
    final value = amount;
    if (value == null) return AppStrings.payAmountRequired;
    if (value <= 0) return AppStrings.payAmountPositive;
    if (value > due + 0.005) return AppStrings.payAmountExceeds(dueText);
    return null;
  }

  String get last4 => normalizeDigits(cardLast4.value.trim());

  bool get last4Valid => RegExp(r'^\d{4}$').hasMatch(last4);

  /// الحقول الخاصة بطريقة الدفع مكتملة؟
  bool get extrasValid {
    final k = kind;
    if (k == PaymentModeKind.cash) return true;
    if (referenceNo.value.trim().isEmpty || referenceDate.value == null) {
      return false;
    }
    if (k == PaymentModeKind.cheque) {
      return chequeBank.value.trim().isNotEmpty &&
          drawerName.value.trim().isNotEmpty;
    }
    if (k == PaymentModeKind.card) {
      return last4Valid && cardBrand.value.trim().isNotEmpty;
    }
    return true;
  }

  bool get canSave {
    final value = amount;
    return !saving.value &&
        value != null &&
        value > 0 &&
        value <= due + 0.005 &&
        mode.value != null &&
        extrasValid;
  }

  PaymentDetails details() {
    final k = kind;
    if (k == PaymentModeKind.cash) return const PaymentDetails();
    return PaymentDetails(
      referenceNo: referenceNo.value.trim(),
      referenceDate: referenceDate.value,
      extra: switch (k) {
        PaymentModeKind.cheque => {
          'custom_cheque_bank': chequeBank.value.trim(),
          'custom_drawer_name': drawerName.value.trim(),
        },
        // آخر 4 أرقام فقط: لا رقم بطاقة كاملًا ولا تاريخ انتهاء ولا CVV
        PaymentModeKind.card => {
          'custom_card_last4': last4,
          'custom_card_brand': cardBrand.value.trim(),
        },
        PaymentModeKind.transfer => {
          'custom_sender_bank': senderBank.value.trim(),
        },
        _ => const <String, String>{},
      },
    );
  }

  /// true = حُفظت (تُغلق النافذة). عند النجاح يبقى [saving] true حتى الإغلاق.
  Future<bool> save() async {
    final value = amount;
    if (!canSave || value == null) return false;
    saving.value = true;
    saveError.value = null;
    final cleanNote = note.value.trim();
    final error = await _collections.pay(
      invoice,
      amount: value,
      modeOfPayment: mode.value!,
      note: cleanNote.isEmpty ? null : cleanNote,
      details: details(),
    );
    if (isClosed) return false;
    if (error == null) return true;
    saving.value = false;
    saveError.value = error;
    return false;
  }
}
