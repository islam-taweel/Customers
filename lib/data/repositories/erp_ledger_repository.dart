import '../api/erp_api_client.dart';
import '../models/gl_entry.dart';
import '../models/sales_invoice.dart';

/// فاتورة مبيعات من فواتير طلبية، بمبالغها من ERPNext.
class OrderInvoice {
  final String name;

  /// 0 = مسودة بانتظار الاعتماد، 1 = معتمدة
  final int docstatus;
  final String currency;
  final InvoiceSettlement settlement;

  const OrderInvoice({
    required this.name,
    required this.docstatus,
    required this.currency,
    required this.settlement,
  });
}

/// حساب العميل لكل فاتورة من ERPNext، للقراءة فقط: لا يُعدَّل أي قيد مُرحَّل.
///
/// المصدر Payment Ledger Entry: كل سطر فيه مربوط بالفاتورة (against_voucher_no):
/// الفاتورة نفسها بقيمتها (مدين)، وكل ما سدّد منها بالسالب (دائن): دفعات، رصيد سابق
/// خُصص لها، إشعارات دائن، قيود يومية. مجموعها = المتبقي على الفاتورة في ERPNext.
/// عند تعذّره (إصدار قديم أو بلا صلاحية): سطور حساب العميل من GL Entry.
///
/// لا يُطلب أي قيد لمسودة: المسودات تُعاد في [CustomerLedger.drafts].
class ErpLedgerRepository {
  ErpLedgerRepository(this._api);

  final ErpApiClient _api;

  static const _invoice = 'Sales Invoice';

  /// حساب العميل لفاتورة واحدة.
  Future<CustomerLedger> forInvoice(String invoice) async {
    final rows = await _api.getList(
      _invoice,
      fields: ['name', 'docstatus'],
      filters: [
        ['name', '=', invoice],
      ],
      limitPageLength: 1,
    );
    final docstatus = rows.isEmpty ? 0 : _status(rows.first);
    if (docstatus != 1) {
      return CustomerLedger(
        lines: const [],
        drafts: [
          if (docstatus == 0) (doctype: _invoice, name: invoice),
        ],
      );
    }
    return CustomerLedger(lines: await _invoiceLines(invoice), drafts: const []);
  }

  /// حساب العميل لكل فواتير طلبية (لا شيء قبل فوترتها).
  Future<CustomerLedger> forOrder(String orderId) async {
    final rows = await _api.getAll(
      _invoice,
      fields: ['name', 'docstatus'],
      filters: [
        ['Sales Invoice Item', 'sales_order', '=', orderId],
        ['docstatus', '<', 2],
        ['is_return', '=', 0],
      ],
      // مؤهَّل باسم الجدول: فلتر الجدول الفرعي يضيف join فيصير «creation» ملتبسًا
      orderBy: '`tab$_invoice`.creation asc',
    );

    final lines = <CustomerLedgerLine>[];
    final drafts = <({String doctype, String name})>[];
    final seen = <String>{};
    for (final r in rows) {
      final name = r['name'].toString();
      if (!seen.add(name)) continue;
      if (_status(r) == 1) {
        lines.addAll(await _invoiceLines(name));
      } else {
        drafts.add((doctype: _invoice, name: name));
      }
    }
    return CustomerLedger(lines: lines, drafts: drafts);
  }

  /// فواتير الطلبية (مسودة ومعتمدة، غير المرتجعات) ومبالغها كما في ERPNext:
  /// قيمة الفاتورة، المسدد من رصيد سابق، المدفوع، المتبقي.
  Future<List<OrderInvoice>> orderInvoices(String orderId) async {
    final rows = await _api.getAll(
      _invoice,
      fields: ['name', 'docstatus', ...InvoiceSettlement.fields],
      filters: [
        ['Sales Invoice Item', 'sales_order', '=', orderId],
        ['docstatus', '<', 2],
        ['is_return', '=', 0],
      ],
      orderBy: '`tab$_invoice`.creation asc',
    );
    final byName = <String, OrderInvoice>{};
    for (final r in rows) {
      final name = r['name'].toString();
      byName[name] = OrderInvoice(
        name: name,
        docstatus: _status(r),
        currency: r['currency']?.toString() ?? '',
        settlement: InvoiceSettlement.fromJson(r),
      );
    }
    return byName.values.toList();
  }

  /// سطور حساب العميل المربوطة بفاتورة معتمدة: الفاتورة (مدين) وما سدّد منها (دائن).
  Future<List<CustomerLedgerLine>> _invoiceLines(String invoice) async {
    try {
      final rows = await _api.getAll(
        'Payment Ledger Entry',
        fields: [
          'posting_date',
          'voucher_type',
          'voucher_no',
          'amount_in_account_currency',
          'account_currency',
        ],
        filters: [
          ['against_voucher_type', '=', _invoice],
          ['against_voucher_no', '=', invoice],
          ['delinked', '=', 0],
        ],
        orderBy: 'creation asc',
      );
      return [
        for (final r in rows)
          if (((r['amount_in_account_currency'] as num?) ?? 0) != 0)
            CustomerLedgerLine.fromPaymentLedger(r),
      ];
    } on ErpApiException catch (e) {
      if (e.type == ErpErrorType.network ||
          e.type == ErpErrorType.sessionExpired) {
        rethrow;
      }
    }

    // احتياط: سطور حساب العميل في GL المربوطة بالفاتورة (ومنها سطر الفاتورة نفسها)
    final rows = await _api.getAll(
      'GL Entry',
      fields: [
        'posting_date',
        'voucher_type',
        'voucher_no',
        'debit_in_account_currency',
        'credit_in_account_currency',
        'account_currency',
      ],
      filters: [
        ['party_type', '=', 'Customer'],
        ['against_voucher_type', '=', _invoice],
        ['against_voucher', '=', invoice],
        ['is_cancelled', '=', 0],
      ],
      orderBy: 'creation asc',
    );
    return [for (final r in rows) CustomerLedgerLine.fromGl(r)];
  }

  static int _status(Map<String, dynamic> row) =>
      (row['docstatus'] as num?)?.toInt() ?? 0;
}
