import '../../core/constants/app_strings.dart';
import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/sales_invoice.dart';
import '../models/pending_order.dart';

/// نتيجة إرجاع طلبية للتعديل: رقم المسودة الجديدة، والمبلغ الذي كان مدفوعًا على
/// فواتيرها وبقي رصيدًا في حساب العميل (0 = لم يُدفع شيء).
class ReopenResult {
  /// الطلبية الأصلية التي أُرجعت
  final String sourceOrderId;

  /// المسودة الجديدة (أو الأصلية إن كانت مسودة أصلًا)
  final String orderId;
  final double keptAmount;
  final String currency;

  const ReopenResult({
    required this.sourceOrderId,
    required this.orderId,
    required this.keptAmount,
    required this.currency,
  });
}

/// عمليات المسودة (طلبية Sales Order بحالة Draft) في ERPNext: تعديل، حذف، اعتماد،
/// وإرجاع الطلبية المعتمدة إلى مسودة (إلغاء ثم Amend).
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

  /// حقول لا تُنسخ إلى النسخة المعدّلة: هوية المستند وحالته وما يحسبه ERPNext
  static const _skipKeys = {
    'name',
    'owner',
    'creation',
    'modified',
    'modified_by',
    'docstatus',
    'parent',
    'status',
    'per_delivered',
    'per_billed',
    'per_picked',
    'delivery_status',
    'billing_status',
    'delivered_qty',
    'billed_amt',
    'returned_qty',
    'picked_qty',
    'ordered_qty',
    'produced_qty',
    'work_order_qty',
    'planned_qty',
  };

  /// يعيد طلبية معتمدة إلى مسودة في أي مرحلة (معتمدة، مُسلَّمة، مُفوترة غير مدفوعة
  /// أو مدفوعة جزئيًا أو كليًا). يتراجع بالترتيب الذي يفرضه ERPNext:
  /// حذف المسودات المرتبطة ← إلغاء الفواتير ← إلغاء سندات التسليم (تعود البضاعة
  /// للمخزون) ← إلغاء الطلبية ← نسخة معدّلة مسودة (amended_from) برقم مثل SO-0001-1.
  ///
  /// المدفوع على الفاتورة لا يُرد: عند إلغائها يفكّ ERPNext ربط الدفعة فتبقى رصيدًا
  /// غير مخصص في حساب العميل (يتطلب «Unlink Payment on Cancellation of Invoice»
  /// في Accounts Settings). يرفض إن كانت على الفاتورة دفعة مسودة لم تُعتمد.
  ///
  /// آمن للإعادة: كل خطوة تُقرأ من جديد، فالمحاولة الثانية تكمل من حيث توقفت الأولى.
  Future<ReopenResult> reopenOrder(String orderId) async {
    var doc = await _api.getDoc(_doctype, orderId);
    final docstatus = (doc['docstatus'] as num?)?.toInt() ?? 0;
    var kept = 0.0;
    var currency = doc['currency']?.toString() ?? '';

    if (docstatus == 0) {
      // ما زالت مسودة أصلًا
      return ReopenResult(
        sourceOrderId: orderId,
        orderId: orderId,
        keptAmount: 0,
        currency: currency,
      );
    }

    if (docstatus == 1) {
      final invoices = await _linked(
        'Sales Invoice',
        ['Sales Invoice Item', 'sales_order', '=', orderId],
        extraFields: InvoiceSettlement.fields,
      );
      final notes = await _linked('Delivery Note', [
        'Delivery Note Item',
        'against_sales_order',
        '=',
        orderId,
      ]);
      final submittedInvoices = [
        for (final i in invoices)
          if (_status(i) == 1) i,
      ];

      // دفعات مسودة على الفاتورة: تُعتمد أو تُحذف أولًا حتى لا يضيع المبلغ
      if (submittedInvoices.isNotEmpty) {
        final draftPayments = await _api.getAll(
          'Payment Entry',
          fields: ['name'],
          filters: [
            [
              'Payment Entry Reference',
              'reference_name',
              'in',
              [for (final i in submittedInvoices) i['name'].toString()],
            ],
            ['docstatus', '=', 0],
          ],
        );
        if (draftPayments.isNotEmpty) {
          throw ErpApiException(
            ErpErrorType.server,
            detail: AppStrings.reopenHasDraftPayments(
              {for (final p in draftPayments) p['name'].toString()}.join('، '),
            ),
          );
        }
      }

      // المبلغ المدفوع على الفواتير المعتمدة: يبقى في حساب العميل
      // نفس معادلة ERPNext: المسدد = قيمة الفاتورة − المتبقي (يشمل الرصيد السابق
      // المخصص لها، فهو أيضًا يعود رصيدًا عند الإلغاء)، بعملة حساب العميل
      for (final i in submittedInvoices) {
        final s = InvoiceSettlement.fromJson(i);
        final settled = s.total - s.outstanding;
        if (settled > 0.005) kept += settled;
        final c = s.displayIn(i['currency']?.toString() ?? '');
        if (c.isNotEmpty) currency = c;
      }
      if (kept > 0) await _ensurePaymentUnlinkEnabled();

      // 1) المسودات: الفواتير ثم سندات التسليم (الفاتورة قد تُشير إلى السند)
      for (final i in invoices) {
        if (_status(i) == 0) await _delete('Sales Invoice', i);
      }
      for (final n in notes) {
        if (_status(n) == 0) await _delete('Delivery Note', n);
      }
      // 2) المعتمدة: الفواتير ثم سندات التسليم (تعود البضاعة للمخزون)
      for (final i in submittedInvoices) {
        await _cancel('Sales Invoice', i);
      }
      for (final n in notes) {
        if (_status(n) == 1) await _cancel('Delivery Note', n);
      }

      await _api.postMethod('frappe.client.cancel', {
        'doctype': _doctype,
        'name': orderId,
      });
      doc = await _api.getDoc(_doctype, orderId);
    } else {
      // أُلغيت في محاولة سابقة: ربما أُنشئت نسختها المسودة أيضًا
      final existing = await _api.getList(
        _doctype,
        fields: ['name'],
        filters: [
          ['amended_from', '=', orderId],
          ['docstatus', '=', 0],
        ],
        limitPageLength: 1,
      );
      if (existing.isNotEmpty) {
        return ReopenResult(
          sourceOrderId: orderId,
          orderId: existing.first['name'].toString(),
          keptAmount: 0,
          currency: currency,
        );
      }
    }

    final amended = _amendCopy(doc)..['amended_from'] = orderId;
    final created = await _api.postDoc(_doctype, amended);
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    return ReopenResult(
      sourceOrderId: orderId,
      orderId: name,
      keptAmount: kept,
      currency: currency,
    );
  }

  /// رقم الطلبية (Sales Order) التي فُوتِرت منها فاتورة المبيعات.
  Future<String> orderOfInvoice(String invoiceName) async {
    final doc = await _api.getDoc('Sales Invoice', invoiceName);
    final items = doc['items'];
    if (items is List) {
      for (final row in items) {
        final so = row is Map ? row['sales_order']?.toString() ?? '' : '';
        if (so.isNotEmpty) return so;
      }
    }
    throw ErpApiException(
      ErpErrorType.server,
      detail: AppStrings.reopenNoOrder(invoiceName),
    );
  }

  /// مستندات غير ملغاة وغير مرتجعة مرتبطة بالطلبية عبر جدول أصنافها (بلا تكرار)
  Future<List<Map<String, dynamic>>> _linked(
    String doctype,
    List<Object> childFilter, {
    List<String> extraFields = const [],
  }) async {
    final rows = await _api.getAll(
      doctype,
      fields: ['name', 'docstatus', ...extraFields],
      filters: [
        childFilter,
        ['docstatus', '<', 2],
        ['is_return', '=', 0],
      ],
    );
    final byName = <String, Map<String, dynamic>>{
      for (final r in rows) r['name'].toString(): r,
    };
    return byName.values.toList();
  }

  /// بدون هذا الإعداد يرفض ERPNext إلغاء فاتورة عليها دفعة معتمدة. إن لم تكن
  /// للمستخدم صلاحية قراءته نكمل، ورسالة ERPNext نفسها تظهر إن رُفض الإلغاء.
  Future<void> _ensurePaymentUnlinkEnabled() async {
    try {
      final settings = await _api.getDoc(
        'Accounts Settings',
        'Accounts Settings',
      );
      final enabled =
          (settings['unlink_payment_on_cancellation_of_invoice'] as num?)
              ?.toInt() ==
          1;
      if (!enabled) {
        throw ErpApiException(
          ErpErrorType.server,
          detail: AppStrings.reopenNeedsUnlinkSetting,
        );
      }
    } on ErpApiException catch (e) {
      if (e.type != ErpErrorType.forbidden) rethrow;
    }
  }

  Future<void> _delete(String doctype, Map<String, dynamic> row) async {
    try {
      await _api.deleteDoc(doctype, row['name'].toString());
    } on ErpApiException catch (e) {
      if (e.type != ErpErrorType.notFound) rethrow;
    }
  }

  Future<void> _cancel(String doctype, Map<String, dynamic> row) =>
      _api.postMethod('frappe.client.cancel', {
        'doctype': doctype,
        'name': row['name'].toString(),
      });

  static int _status(Map<String, dynamic> row) =>
      (row['docstatus'] as num?)?.toInt() ?? 0;

  /// نسخة من المستند بلا هويته وحالته (وكذلك صفوف جداوله) ولا مفاتيح __
  static Map<String, dynamic> _amendCopy(Map<String, dynamic> doc) {
    Map<String, dynamic> strip(Map source) => {
      for (final e in source.entries)
        if (!_skipKeys.contains(e.key) && !e.key.toString().startsWith('__'))
          e.key.toString(): e.value is List
              ? [
                  for (final row in e.value as List)
                    row is Map ? strip(row) : row,
                ]
              : e.value,
    };
    return strip(doc);
  }
}
