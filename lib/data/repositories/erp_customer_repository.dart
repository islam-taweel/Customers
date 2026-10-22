import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../api/erp_api_client.dart';
import '../api/erp_config.dart';
import '../models/erp_customer.dart';
import 'customer_repository.dart';

/// يجلب **أسماء العملاء وأرقام هواتفهم** من ERPNext فقط. لا يعرف شيئًا عن الديون
/// (ليست موجودة في الـ API) ولا عن قاعدة البيانات المحلية.
///
/// الاسم من جدول Customer، والهاتف من جدول Contact المرتبط بالعميل
/// (mobile_no أولًا ثم phone)، وهي الطريقة نفسها التي يعتمد عليها مستودع الفواتير.
class ErpCustomerRepository {
  ErpCustomerRepository(this._api, [this._local]);

  final ErpApiClient _api;

  /// القاعدة المحلية: مصدر العملاء عند انقطاع الاتصال (اختياري)
  final CustomerRepository? _local;

  /// للطلبيات: من ERPNext إن أمكن، وإلا العملاء المحفوظون محليًا (دون إنترنت).
  /// أخطاء غير الاتصال (مفاتيح مرفوضة...) تُرمى كما هي.
  Future<List<ErpCustomer>> fetchCustomersOrLocal() async {
    final local = _local;
    if (local != null && _api.recentlyUnreachable) {
      final saved = await local.getErpCustomers();
      if (saved.isNotEmpty) return saved;
    }
    try {
      return await fetchCustomers();
    } on ErpApiException catch (e) {
      if (e.type == ErpErrorType.network && local != null) {
        final saved = await local.getErpCustomers();
        if (saved.isNotEmpty) return saved;
      }
      rethrow;
    }
  }

  /// يرمي [ErpApiException] عند فشل الاتصال أو رفض المفاتيح.
  Future<List<ErpCustomer>> fetchCustomers() async {
    final results = await Future.wait<List<Map<String, dynamic>>>([
      _api.getAll(
        'Customer',
        fields: ['name', 'customer_name', 'default_currency'],
      ),
      _fetchContactRows(),
    ]);
    final customerRows = results[0];
    final contactRows = results[1];

    // رقم العميل في ERPNext ← أول هاتف صالح وجدناه له
    final phoneById = <String, String>{};
    for (final row in contactRows) {
      final id = row['link_name']?.toString() ?? '';
      if (id.isEmpty || phoneById.containsKey(id)) continue;

      for (final raw in [row['mobile_no'], row['phone']]) {
        final phone = _normalizePhone(raw?.toString() ?? '');
        if (phone.isNotEmpty) {
          phoneById[id] = phone;
          break;
        }
      }
    }

    final customers = <ErpCustomer>[];
    for (final row in customerRows) {
      final id = row['name']?.toString() ?? '';
      final name = (row['customer_name']?.toString() ?? '').trim();
      if (id.isEmpty || name.isEmpty) continue;
      customers.add(
        ErpCustomer(
          id: id,
          name: name,
          phone: phoneById[id] ?? '',
          // فارغة = عملة الشركة (ILS)
          currency: (row['default_currency']?.toString() ?? '').trim(),
        ),
      );
    }
    return customers;
  }

  /// ينشئ عميلًا في ERPNext ويعيد رقمه (data.name). [type] هو Company أو Individual.
  /// default_currency تُرسل فقط إن اختلفت عن عملة الشركة (ILS)، كما يشترط ERPNext.
  /// الاسم المكرر يرجع خطأ من الخادم برسالته (في [ErpApiException.detail]).
  Future<String> createCustomer({
    required String name,
    required String type,
    required String group,
    required String territory,
    required String currency,
  }) async {
    final doc = await _api.postDoc('Customer', {
      'customer_name': name,
      'customer_type': type,
      'customer_group': group,
      'territory': territory,
      if (currency.isNotEmpty && currency != ErpConfig.priceListCurrency)
        'default_currency': currency,
    });
    final id = doc['name']?.toString() ?? '';
    if (id.isEmpty) throw const ErpApiException(ErpErrorType.badResponse);
    return id;
  }

  /// يضيف هاتف العميل كجهة اتصال (Contact) مرتبطة به. يُستدعى بعد [createCustomer].
  Future<void> addPhone({
    required String customerId,
    required String name,
    required String phone,
  }) async {
    await _api.postDoc('Contact', {
      'first_name': name,
      'phone_nos': [
        {'phone': phone, 'is_primary_phone': 1},
      ],
      'links': [
        {'link_doctype': 'Customer', 'link_name': customerId},
      ],
    });
  }

  /// فشل جلب الهواتف بسبب خطأ من الخادم لا يمنع عرض الأسماء، فنكمل بلا هواتف.
  /// أخطاء المفاتيح والاتصال تُرمى كما هي.
  Future<List<Map<String, dynamic>>> _fetchContactRows() async {
    try {
      return await _api.getAll(
        'Contact',
        fields: [
          'name',
          'first_name',
          'phone',
          'mobile_no',
          ErpConfig.contactLinkField,
        ],
        filters: [
          ['Dynamic Link', 'link_doctype', '=', 'Customer'],
        ],
      );
    } on ErpApiException catch (e) {
      if (e.type == ErpErrorType.server || e.type == ErpErrorType.badResponse) {
        debugPrint('تعذّر جلب أرقام الهواتف، سنكمل بالأسماء فقط: $e');
        return const [];
      }
      rethrow;
    }
  }

  /// يوحّد صيغة الهاتف إلى الصيغة المحلية 05XXXXXXXX التي يفهمها التطبيق
  /// (التحقق وواتساب)، فتتحول +970599123456 و 599123456 إلى 0599123456.
  /// ما لا يطابق هذه الصيغ يبقى أرقامه كما هي.
  String _normalizePhone(String raw) {
    var digits = normalizeDigits(raw).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);

    const cc = AppConstants.phoneCountryCode;
    if (digits.startsWith(cc) && digits.length == cc.length + 9) {
      return '0${digits.substring(cc.length)}';
    }
    if (digits.length == 9 && digits.startsWith('5')) return '0$digits';
    return digits;
  }
}
