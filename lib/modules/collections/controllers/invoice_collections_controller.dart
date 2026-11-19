import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/sales_invoice.dart';
import '../models/collection_models.dart';
import '../repository/invoice_collections_repository.dart';

/// تحصيلات فواتير المبيعات: الدفعات المحفوظة مسودة (بانتظار اعتمادها في ERPNext)
/// وحفظ دفعة جديدة على فاتورة. يعيش مع قسم «الطلبات» (نفس عمر قائمة الفواتير).
///
/// (R3) نُقل منطقه كما هو من SalesInvoicesController القديم.
class InvoiceCollectionsController extends GetxController {
  InvoiceCollectionsController(this._repository);

  final ErpInvoiceCollectionsRepository _repository;

  /// الدفعات المحفوظة مسودة على الفواتير
  final pending = <PendingPayment>[].obs;

  /// مجموع الدفعات المحفوظة مسودة (بانتظار الاعتماد) على فاتورة
  double pendingAmount(String invoiceName) => pending
      .where((p) => p.invoice == invoiceName)
      .fold<double>(0, (sum, p) => sum + p.amount);

  /// المحفوظ على الهاتف (عند فتح القسم)
  Future<void> loadPending() async {
    final list = await _repository.readPending();
    if (isClosed) return;
    pending.assignAll(list);
  }

  /// بعد جلب الفواتير: يُبقي فقط ما زال مسودة في ERPNext. الفشل لا يغيّر شيئًا.
  Future<void> reconcile() async {
    try {
      final kept = await _repository.reconcilePending();
      if (isClosed) return;
      pending.assignAll(kept);
    } catch (e) {
      debugPrint('SalesInvoicesController.reconcilePending failed: $e');
    }
  }

  /// طرق الدفع من ERPNext لنافذة الدفع
  Future<List<String>> modesOfPayment() => _repository.fetchModesOfPayment();

  /// يحفظ دفعة على فاتورة. يعيد null عند النجاح، وإلا نص الخطأ للعرض.
  Future<String?> pay(
    SalesInvoice invoice, {
    required double amount,
    required String modeOfPayment,
    String? note,
    PaymentDetails details = const PaymentDetails(),
  }) async {
    try {
      final payment = await _repository.savePayment(
        invoice: invoice,
        amount: amount,
        modeOfPayment: modeOfPayment,
        note: note,
        details: details,
      );
      pending.add(payment);
      return null;
    } on ErpApiException catch (e) {
      debugPrint('SalesInvoicesController.pay: $e');
      if (e.type == ErpErrorType.network) {
        return AppStrings.draftNeedsConnection;
      }
      final detail = e.type == ErpErrorType.server ? e.detail : null;
      final base = describeError(e, fallback: AppStrings.paymentSaveFailed);
      return (detail == null || detail.isEmpty)
          ? base
          : '${AppStrings.paymentSaveFailed}\n$detail';
    } catch (e) {
      debugPrint('SalesInvoicesController.pay: $e');
      return AppStrings.paymentSaveFailed;
    }
  }
}
