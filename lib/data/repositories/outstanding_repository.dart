import 'package:flutter/foundation.dart';

import '../api/erp_api_client.dart';
import '../api/erp_config.dart';

/// مبلغ بعملة معيّنة (مستحق الفواتير يُفصل بحسب العملة ولا تُجمع العملات معًا).
class CurrencyAmount {
  final String currency;
  final double amount;

  const CurrencyAmount(this.currency, this.amount);
}

/// ما يرجع به ERPNext عن عميل واحد:
///  • [invoiceOutstanding]: مستحق الفواتير المعتمدة لكل عملة (المرتجعات بالسالب داخله)،
///  • [accountBalance]: رصيد حساب العميل بعملة الشركة، ويشمل الدفعات غير المربوطة
///    بفواتير، لذلك يختلف عن مجموع الفواتير عند وجود مثل هذه الدفعات.
class CustomerOutstanding {
  final List<CurrencyAmount> invoiceOutstanding;
  final double? accountBalance;

  const CustomerOutstanding({
    required this.invoiceOutstanding,
    required this.accountBalance,
  });
}

class OutstandingRepository {
  OutstandingRepository(this._api);

  final ErpApiClient _api;

  static const _balanceMethod = 'erpnext.accounts.utils.get_balance_on';

  /// يجلب الرقمين معًا. فشل أحدهما لا يلغي الآخر (يُترك فارغًا/null)،
  /// وفشلهما معًا يُرجع null فتبقى الواجهة على الرصيد المحلي.
  Future<CustomerOutstanding?> fetch(String customerErpId) async {
    List<CurrencyAmount>? invoices;
    double? balance;

    try {
      invoices = await _fetchInvoiceOutstanding(customerErpId);
    } on ErpApiException catch (e) {
      debugPrint('OutstandingRepository invoices failed: $e');
    }
    try {
      balance = await _fetchAccountBalance(customerErpId);
    } on ErpApiException catch (e) {
      debugPrint('OutstandingRepository balance failed: $e');
    }

    if (invoices == null && balance == null) return null;
    return CustomerOutstanding(
      invoiceOutstanding: invoices ?? const [],
      accountBalance: balance,
    );
  }

  /// 1c: إجمالي المستحق على كل العملاء، صف لكل عملة (الفواتير المعتمدة فقط).
  /// null = تعذّر الجلب (لا اتصال أو لا جلسة).
  Future<List<CurrencyAmount>?> fetchTotal() async {
    try {
      final rows = await _api.getList(
        'Sales Invoice',
        fields: ['currency', 'sum(outstanding_amount) as outstanding'],
        filters: [
          ['docstatus', '=', 1],
        ],
        groupBy: 'currency',
      );
      return [
        for (final row in rows)
          if ((row['currency']?.toString() ?? '').isNotEmpty)
            CurrencyAmount(row['currency'].toString(), _num(row['outstanding'])),
      ];
    } on ErpApiException catch (e) {
      debugPrint('OutstandingRepository.fetchTotal failed: $e');
      return null;
    }
  }

  /// 1a لكل العملاء: مستحق كل عميل بكل عملة (صف لكل عميل وعملة). المفتاح رقم العميل في ERPNext.
  /// null = تعذّر الجلب. عميل غير موجود في الناتج = لا مستحق عليه.
  Future<Map<String, List<CurrencyAmount>>?> fetchByCustomer() async {
    try {
      final rows = await _api.getAll(
        'Sales Invoice',
        fields: ['customer', 'currency', 'sum(outstanding_amount) as outstanding'],
        filters: [
          ['docstatus', '=', 1],
        ],
        groupBy: 'customer,currency',
      );
      final result = <String, List<CurrencyAmount>>{};
      for (final row in rows) {
        final customer = row['customer']?.toString() ?? '';
        final currency = row['currency']?.toString() ?? '';
        if (customer.isEmpty || currency.isEmpty) continue;
        result
            .putIfAbsent(customer, () => [])
            .add(CurrencyAmount(currency, _num(row['outstanding'])));
      }
      return result;
    } on ErpApiException catch (e) {
      debugPrint('OutstandingRepository.fetchByCustomer failed: $e');
      return null;
    }
  }

  /// 1a: صف لكل عملة للعميل، من الفواتير المعتمدة (docstatus = 1).
  Future<List<CurrencyAmount>> _fetchInvoiceOutstanding(String customer) async {
    final rows = await _api.getList(
      'Sales Invoice',
      fields: ['currency', 'sum(outstanding_amount) as outstanding'],
      filters: [
        ['docstatus', '=', 1],
        ['customer', '=', customer],
      ],
      groupBy: 'currency',
    );
    return [
      for (final row in rows)
        if ((row['currency']?.toString() ?? '').isNotEmpty)
          CurrencyAmount(row['currency'].toString(), _num(row['outstanding'])),
    ];
  }

  /// 1b: رصيد حساب العميل بعملة الشركة (ILS).
  Future<double> _fetchAccountBalance(String customer) async {
    final res = await _api.getMethod(_balanceMethod, {
      'party_type': 'Customer',
      'party': customer,
      'company': ErpConfig.company,
      'date': _date(DateTime.now()),
    });
    return _num(res['message']);
  }

  static double _num(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}
