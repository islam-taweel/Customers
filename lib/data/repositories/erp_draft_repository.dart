import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/pending_order.dart';

/// عمليات المسودة (طلبية Sales Order بحالة Draft) في ERPNext: تعديل، حذف، اعتماد.
class ErpDraftRepository {
  ErpDraftRepository(this._api);

  final ErpApiClient _api;

  static const _doctype = 'Sales Order';

  /// يستبدل أصناف الطلبية وتاريخ التسليم. الأصناف تُرسل كاملة فتحل محل القديمة.
  Future<void> updateOrder(
    String orderId, {
    required String deliveryDate,
    required List<PendingOrderLine> lines,
  }) async {
    await _api.putDoc(_doctype, orderId, {
      'delivery_date': deliveryDate,
      'items': [
        for (final l in lines)
          {
            'item_code': l.code,
            'qty': l.qty,
            'rate': l.rate,
            'warehouse': ErpConfig.warehouse,
          },
      ],
    });
  }

  /// يحذف المسودة. إن كانت محذوفة أصلًا من ERPNext (404) نعدّ الحذف ناجحًا،
  /// فيُزال أثرها المحلي أيضًا.
  Future<void> deleteOrder(String orderId) async {
    try {
      await _api.deleteDoc(_doctype, orderId);
    } on ErpApiException catch (e) {
      if (e.type != ErpErrorType.notFound) rethrow;
    }
  }

  /// يعتمد الطلبية (docstatus 0 → 1) عبر frappe.client.submit، وتحتاج المستند
  /// كاملًا بآخر `modified` لديه، فنجلبه ثم نرسله.
  Future<void> submitOrder(String orderId) async {
    final doc = await _api.getDoc(_doctype, orderId);
    await _api.postMethod('frappe.client.submit', {'doc': doc});
  }
}
