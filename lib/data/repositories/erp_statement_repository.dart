import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/erp_customer.dart';
import '../models/statement_models.dart';
import 'erp_customer_repository.dart';

/// كشف حساب العملاء من ERPNext (GL Entry على حساب العميل)، وفتح أي مستند فيه.
/// يحتاج المستخدم صلاحية قراءة GL Entry (دور محاسبة). للقراءة فقط.
class ErpStatementRepository {
  ErpStatementRepository(this._api, this._customers);

  final ErpApiClient _api;
  final ErpCustomerRepository _customers;

  static const _balanceMethod = 'erpnext.accounts.utils.get_balance_on';

  /// كل العملاء (من ERPNext، أو المحفوظون على الجهاز دون اتصال)، مرتبون بالاسم.
  Future<List<ErpCustomer>> fetchCustomers() async {
    final list = await _customers.fetchCustomersOrLocal();
    return [...list]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// حركات العميل بالترتيب (posting_date ثم creation) مع الرصيد الجاري:
  /// الرصيد = الافتتاحي + مجموع (مدين − دائن) سطرًا بسطر. دون فترة: الافتتاحي 0.
  /// كل الصفحات تُجلب (100 صف في كل طلب) حتى تأتي صفحة ناقصة.
  Future<CustomerStatement> fetchStatement(
    String customerId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final rows = await _api.getAll(
      'GL Entry',
      fields: StatementLine.fields,
      filters: [
        ['party_type', '=', 'Customer'],
        ['party', '=', customerId],
        ['company', '=', ErpConfig.company],
        ['is_cancelled', '=', 0],
        if (from != null) ['posting_date', '>=', _date(from)],
        if (to != null) ['posting_date', '<=', _date(to)],
      ],
      orderBy: 'posting_date asc, creation asc',
    );

    var opening = 0.0;
    if (from != null) {
      final res = await _api.getMethod(_balanceMethod, {
        'party_type': 'Customer',
        'party': customerId,
        'company': ErpConfig.company,
        'date': _date(from.subtract(const Duration(days: 1))),
      });
      opening = _num(res['message']);
    }

    var balance = opening;
    final lines = <StatementLine>[];
    for (final r in rows) {
      balance += _num(r['debit']) - _num(r['credit']);
      lines.add(StatementLine.fromJson(r, balance));
    }
    return CustomerStatement(
      opening: opening,
      lines: lines,
      from: from,
      to: to,
    );
  }

  /// المستند كاملًا (فاتورة، دفعة، قيد يومية...) لعرض تفاصيله.
  Future<Map<String, dynamic>> fetchVoucher(String doctype, String name) =>
      _api.getDoc(doctype, name);

  static double _num(Object? v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  /// YYYY-MM-DD كما يطلبها ERPNext
  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}
