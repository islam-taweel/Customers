import '../../core/constants/app_strings.dart';
import '../api/erp_api_client.dart';
import '../api/erp_config.dart';

/// تسجيل دفعة العميل في ERPNext كمستند Payment Entry (نوع Receive) ثم اعتماده.
///
/// الحسابات تُحدَّد تلقائيًا:
///  • حساب العميل (المدين) من get_party_details،
///  • حساب طريقة الدفع من جدول Mode of Payment للشركة الحالية.
/// وإن اختلفت عملة الدفعة عن عملة الحسابات تُحوَّل المبالغ بسعر الصرف من ERPNext.
class ErpPaymentRepository {
  ErpPaymentRepository(this._api);

  final ErpApiClient _api;

  static const _doctype = 'Payment Entry';
  static const _partyDetailsMethod =
      'erpnext.accounts.doctype.payment_entry.payment_entry.get_party_details';
  static const _exchangeRateMethod = 'erpnext.setup.utils.get_exchange_rate';

  /// ينشئ Payment Entry ويعتمده، ويعيد رقمه. يرمي [ErpApiException] عند الفشل.
  /// إن فشل الاعتماد يُحذف المستند المسودة حتى لا يتراكم عند إعادة المحاولة.
  Future<String> createPaymentEntry({
    required String customerErpId,
    required double amount,
    required String currency,
    required String modeOfPayment,
    required DateTime date,
    String? note,
  }) async {
    final day = _date(date);
    final company = ErpConfig.company;

    final results = await Future.wait<Map<String, dynamic>>([
      _api.getMethod(_partyDetailsMethod, {
        'company': company,
        'party_type': 'Customer',
        'party': customerErpId,
        'date': day,
      }),
      _api.getDoc('Mode of Payment', modeOfPayment),
      _api.getDoc('Company', company),
    ]);

    // حساب العميل (paid_from) وعملته
    final party = results[0]['message'];
    final paidFrom = party is Map ? party['party_account']?.toString() ?? '' : '';
    final paidFromCurrency =
        party is Map ? party['party_account_currency']?.toString() ?? '' : '';
    if (paidFrom.isEmpty) {
      throw ErpApiException(
        ErpErrorType.server,
        detail: AppStrings.paymentCustomerAccountMissing,
      );
    }

    final modeType = results[1]['type']?.toString() ?? '';
    final companyCurrency = results[2]['default_currency']?.toString() ?? '';

    // حساب القبض (paid_to): يحدده اختيار العملة، فنأخذ حسابًا نقديًا أو بنكيًا
    // بنفس عملة الدفعة. نفضّل الحساب الافتراضي لطريقة الدفع إن طابقت عملته.
    final account = await _pickReceivingAccount(
      company: company,
      currency: currency,
      modeType: modeType,
      modeAccounts: results[1]['accounts'],
    );
    final paidTo = account.name;
    final paidToCurrency = currency;
    if (paidFromCurrency.isEmpty || companyCurrency.isEmpty) {
      throw const ErpApiException(ErpErrorType.badResponse);
    }

    // المبلغ مُدخل بعملة الدفعة، ويُحوَّل إلى عملة كل حساب
    final toFrom = await _rate(currency, paidFromCurrency, day);
    final toTo = await _rate(currency, paidToCurrency, day);
    final fromToCompany = await _rate(paidFromCurrency, companyCurrency, day);
    final toToCompany = await _rate(paidToCurrency, companyCurrency, day);

    final cleanNote = note?.trim() ?? '';
    final body = <String, dynamic>{
      'payment_type': 'Receive',
      'company': company,
      'posting_date': day,
      'party_type': 'Customer',
      'party': customerErpId,
      'mode_of_payment': modeOfPayment,
      'paid_from': paidFrom,
      'paid_from_account_currency': paidFromCurrency,
      'paid_to': paidTo,
      'paid_to_account_currency': paidToCurrency,
      'paid_amount': _round(amount * toFrom),
      'received_amount': _round(amount * toTo),
      'source_exchange_rate': fromToCompany,
      'target_exchange_rate': toToCompany,
      // مطلوبان في ERPNext إن كانت طريقة الدفع أو الحساب من نوع Bank
      if (modeType == 'Bank' || account.type == 'Bank') ...{
        'reference_no': 'APP-${date.millisecondsSinceEpoch}',
        'reference_date': day,
      },
      if (cleanNote.isNotEmpty) 'remarks': cleanNote,
    };

    final created = await _api.postDoc(_doctype, body);
    final name = created['name']?.toString() ?? '';
    if (name.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);

    try {
      final doc = await _api.getDoc(_doctype, name);
      await _api.postMethod('frappe.client.submit', {'doc': doc});
    } catch (_) {
      try {
        await _api.deleteDoc(_doctype, name);
      } catch (_) {
        // لا شيء: المسودة تبقى ويمكن حذفها من ERPNext
      }
      rethrow;
    }
    return name;
  }

  /// حساب Cash/Bank للشركة بعملة الدفعة (call 2d). يرمي خطأً واضحًا إن لم يوجد.
  Future<({String name, String type})> _pickReceivingAccount({
    required String company,
    required String currency,
    required String modeType,
    required Object? modeAccounts,
  }) async {
    final accounts = await _api.getAll(
      'Account',
      fields: ['name', 'account_currency', 'account_type'],
      filters: [
        ['company', '=', company],
        ['is_group', '=', 0],
        [
          'account_type',
          'in',
          ['Cash', 'Bank'],
        ],
      ],
    );

    // 1) الحساب الافتراضي لطريقة الدفع إن كانت عملته نفس عملة الدفعة
    if (modeAccounts is List) {
      for (final row in modeAccounts) {
        if (row is! Map || row['company']?.toString() != company) continue;
        final defaultName = row['default_account']?.toString() ?? '';
        for (final a in accounts) {
          if (a['name']?.toString() == defaultName &&
              a['account_currency']?.toString() == currency) {
            return (name: defaultName, type: a['account_type']?.toString() ?? '');
          }
        }
      }
    }

    // 2) وإلا أي حساب بعملة الدفعة، مع تفضيل نوع يوافق طريقة الدفع
    final wantedType = modeType == 'Bank' ? 'Bank' : 'Cash';
    Map<String, dynamic>? pick;
    for (final a in accounts) {
      if (a['account_currency']?.toString() != currency) continue;
      if (a['account_type']?.toString() == wantedType) {
        pick = a;
        break;
      }
      pick ??= a;
    }
    if (pick == null) {
      throw ErpApiException(
        ErpErrorType.server,
        detail: AppStrings.paymentNoAccountForCurrency(currency),
      );
    }
    return (
      name: pick['name'].toString(),
      type: pick['account_type']?.toString() ?? '',
    );
  }

  /// سعر التحويل من عملة إلى أخرى (1 إن تطابقتا).
  Future<double> _rate(String from, String to, String day) async {
    if (from == to) return 1;
    final res = await _api.getMethod(_exchangeRateMethod, {
      'from_currency': from,
      'to_currency': to,
      'transaction_date': day,
    });
    final raw = res['message'];
    final rate = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    if (rate <= 0) {
      throw ErpApiException(
        ErpErrorType.server,
        detail: AppStrings.exchangeRateMissing(from, to),
      );
    }
    return rate;
  }

  double _round(double v) => double.parse(v.toStringAsFixed(6));

  /// YYYY-MM-DD كما يطلبها ERPNext
  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}
