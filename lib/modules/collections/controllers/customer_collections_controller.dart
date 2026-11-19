import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/api/erp_api_client.dart';
import '../models/payment_entry.dart';
import '../repository/erp_payment_repository.dart';

/// ما يحتاجه متحكم تحصيلات العميل من شاشة العميل (CustomerDetailsController)،
/// دون أن يعرف قاعدة البيانات المحلية أو سجل العمليات.
abstract interface class CustomerCollectionsHost {
  /// رقم العميل في ERPNext (null = عميل محلي غير مرتبط)
  Future<String?> erpId();

  /// بعد اعتماد دفعة: تسجيلها في السجل المحلي (مرة واحدة) ثم تحديث الرصيد
  Future<void> recordApprovedPayment(Map<String, dynamic> doc);

  /// يُستدعى بعد حفظ دفعة جديدة مسودة في ERPNext (من «إضافة دفعة»)
  void addDraftSavedListener(VoidCallback listener);
  void removeDraftSavedListener(VoidCallback listener);
}

/// تحصيلات عميل واحد في ERPNext (تبويبا «مسودة» و«معتمدة» تحت زر «إضافة دفعة»):
/// التحميل، اعتماد مسودة، إلغاء (حذف) مسودة.
///
/// (R3) نُقل منطقه كما هو من CustomerDetailsController: نفس الطلبات والرسائل.
class CustomerCollectionsController extends GetxController {
  CustomerCollectionsController(this._repository, this._host);

  final ErpPaymentRepository _repository;
  final CustomerCollectionsHost _host;

  final payments = <PaymentEntrySummary>[].obs;
  final loading = false.obs;
  final error = RxnString();
  final busy = <String>{}.obs;

  /// عميل مرتبط بـ ERPNext: دفعاته في تبويبين بدل السجل المحلي
  final isErpCustomer = false.obs;

  List<PaymentEntrySummary> get drafts => [
    for (final p in payments)
      if (p.isDraft) p,
  ];
  List<PaymentEntrySummary> get approved => [
    for (final p in payments)
      if (!p.isDraft) p,
  ];

  bool isBusy(PaymentEntrySummary p) => busy.contains(p.name);

  void _onDraftSaved() => load();

  @override
  void onInit() {
    super.onInit();
    _host.addDraftSavedListener(_onDraftSaved);
    load();
  }

  @override
  void onClose() {
    _host.removeDraftSavedListener(_onDraftSaved);
    super.onClose();
  }

  /// دفعات العميل في ERPNext (مسودة ومعتمدة، بما فيها المسجلة من الفواتير)
  Future<void> load() async {
    final erpId = await _host.erpId();
    if (isClosed) return;
    isErpCustomer.value = erpId != null;
    if (erpId == null) return;
    loading.value = true;
    error.value = null;
    try {
      final list = await _repository.fetchCustomerPayments(erpId);
      if (isClosed) return;
      payments.assignAll(list);
    } catch (e) {
      debugPrint('CustomerDetailsController.loadPayments failed: $e');
      if (isClosed) return;
      error.value = describeError(e, fallback: AppStrings.paymentsLoadFailed);
    } finally {
      if (!isClosed) loading.value = false;
    }
  }

  /// يعتمد دفعة مسودة في ERPNext، ثم يسجّلها في السجل المحلي فتُخصم من الرصيد.
  /// يعيد null عند النجاح، وإلا رسالة الخطأ (مثل رفض ERPNext).
  Future<String?> approve(PaymentEntrySummary payment) =>
      _action(payment, () async {
        final doc = await _repository.submitPaymentEntry(payment.name);
        await _host.recordApprovedPayment(doc);
      }, AppStrings.paymentApproveFailed);

  /// يلغي دفعة مسودة (يحذفها من ERPNext). يعيد null أو رسالة الخطأ.
  Future<String?> cancel(PaymentEntrySummary payment) => _action(
    payment,
    () => _repository.deletePaymentEntry(payment.name),
    AppStrings.paymentCancelFailed,
  );

  Future<String?> _action(
    PaymentEntrySummary payment,
    Future<void> Function() task,
    String fallback,
  ) async {
    if (!busy.add(payment.name)) return null;
    busy.refresh();
    try {
      await task();
      await load();
      return null;
    } catch (e) {
      debugPrint('CustomerDetailsController payment action failed: $e');
      // نص ERPNext نفسه إن رفض (مثل: المبلغ أكبر من المستحق)، وإلا رسالة عامة
      if (e is ErpApiException &&
          e.type == ErpErrorType.server &&
          (e.detail ?? '').isNotEmpty) {
        return '$fallback\n${e.detail}';
      }
      return describeError(e, fallback: fallback);
    } finally {
      busy.remove(payment.name);
    }
  }
}
