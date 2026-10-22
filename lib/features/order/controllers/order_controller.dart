import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/api/erp_config.dart';
import '../../../data/models/erp_customer.dart';
import '../../../data/models/invoice.dart' as local;
import '../../../data/models/order_models.dart';
import '../../../data/models/pending_order.dart';
import '../../../data/repositories/erp_customer_repository.dart';
import '../../../data/repositories/erp_order_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/pending_order_repository.dart';

/// خطوات الطلبية. [done] بعد نجاح الإرسال.
enum OrderStep { customer, items, invoice, done }

/// ينشئ متحكمًا جديدًا لكل طلبية تُفتح (نفس نمط CustomerDetailsControllerFactory).
class OrderControllerFactory {
  OrderControllerFactory(
    this._orders,
    this._customers,
    this._invoices,
    this._pending,
    this._sync,
  );

  final ErpOrderRepository _orders;
  final ErpCustomerRepository _customers;
  final InvoiceRepository _invoices;
  final PendingOrderRepository _pending;
  final SyncService _sync;

  OrderController create() =>
      OrderController(_orders, _customers, _invoices, _pending, _sync);
}

/// حالة شاشة «طلبية جديدة» كلها: العميل المختار، المجموعات والأصناف، السلة،
/// والإرسال. الواجهة تقرأ منه فقط وتستدعي دوالّه.
class OrderController extends ChangeNotifier {
  OrderController(
    this._orders,
    this._customerRepo,
    this._invoiceRepo,
    this._pendingRepo,
    this._sync,
  ) {
    loadCustomers();
  }

  final ErpOrderRepository _orders;
  final ErpCustomerRepository _customerRepo;
  final InvoiceRepository _invoiceRepo;
  final PendingOrderRepository _pendingRepo;
  final SyncService _sync;

  bool _disposed = false;

  // ───────── الخطوة الحالية ─────────
  OrderStep _step = OrderStep.customer;
  OrderStep get step => _step;

  // ───────── 1) العملاء ─────────
  final List<ErpCustomer> _customers = [];
  bool _customersLoading = true;
  String? _customersError;
  String _query = '';
  ErpCustomer? _customer;

  bool get customersLoading => _customersLoading;
  String? get customersError => _customersError;
  ErpCustomer? get customer => _customer;
  String get query => _query;

  /// العملاء بعد تطبيق البحث (بالاسم أو الهاتف أو الرقم)
  List<ErpCustomer> get customers {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return UnmodifiableListView(_customers);
    return _customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.phone.contains(q) ||
              c.id.toLowerCase().contains(q),
        )
        .toList();
  }

  bool get hasAnyCustomer => _customers.isNotEmpty;

  Future<void> loadCustomers() async {
    _customersLoading = true;
    _customersError = null;
    _notify();
    try {
      // من ERPNext، وعند انقطاع الاتصال من العملاء المحفوظين على الجهاز
      final list = await _customerRepo.fetchCustomersOrLocal();
      list.sort((a, b) => a.name.compareTo(b.name));
      _customers
        ..clear()
        ..addAll(list);
    } catch (e) {
      debugPrint('OrderController.loadCustomers: $e');
      _customersError = describeError(
        e,
        fallback: AppStrings.loadCustomersError,
      );
    } finally {
      _customersLoading = false;
      _notify();
    }
  }

  void setQuery(String value) {
    _query = value;
    _notify();
  }

  /// اختيار عميل واحد فقط: الضغط على عميل آخر يستبدل الأول. تُحدَّد عملة الطلبية
  /// من عملة حسابه، ويُجلب سعر صرفها من ERPNext (لا يُخمَّن) قبل المتابعة.
  void selectCustomer(ErpCustomer customer) {
    _customer = customer;
    _notify();
    unawaited(_loadRate());
  }

  // ───────── عملة الطلبية وسعر الصرف ─────────

  /// سعر تحويل عملة الطلبية إلى الشيكل (1 للشيكل)، يُرسل غير مقرّب
  double _conversionRate = 1;
  double _priceFactor = 1;
  bool _rateLoading = false;
  String? _rateError;
  int _rateRequest = 0;

  /// رمز عملة الطلبية: عملة حساب العميل، وفارغة = الشيكل
  String get _currencyCode {
    final c = _customer?.currency ?? '';
    return c.isEmpty ? ErpConfig.priceListCurrency : c;
  }

  /// عملة الطلبية للعرض (null = الشيكل، فيظهر رمزه ₪)
  String? get orderCurrency {
    final c = _currencyCode;
    return c == ErpConfig.priceListCurrency ? null : c;
  }

  double get conversionRate => _conversionRate;

  /// معامل تحويل أسعار قائمة الأسعار (ILS) إلى عملة الطلبية
  double get priceFactor => _priceFactor;
  bool get rateLoading => _rateLoading;
  String? get rateError => _rateError;

  void retryRate() => unawaited(_loadRate());

  Future<void> _loadRate() async {
    final request = ++_rateRequest;
    final code = _currencyCode;
    _rateError = null;

    if (code == ErpConfig.priceListCurrency) {
      _rateLoading = false;
      _applyRate(1);
      return;
    }

    _rateLoading = true;
    _notify();
    try {
      final rate = await _orders.conversionRate(code);
      if (request != _rateRequest) return;
      _applyRate(rate);
    } catch (e) {
      if (request != _rateRequest) return;
      debugPrint('OrderController._loadRate($code): $e');
      _rateError = e is ErpApiException && e.type == ErpErrorType.network
          ? AppStrings.orderRateNeedsConnection
          : _serverDetail(e) ??
              describeError(e, fallback: AppStrings.orderRateFailed);
    } finally {
      if (request == _rateRequest) {
        _rateLoading = false;
        _notify();
      }
    }
  }

  /// رسالة ERPNext الفعلية لخطأ الخادم (مثل غياب سعر الصرف)
  static String? _serverDetail(Object e) {
    if (e is ErpApiException && e.type == ErpErrorType.server) {
      final d = e.detail ?? '';
      return d.isEmpty ? null : d;
    }
    return null;
  }

  /// يطبّق السعر على السلة (الأصناف المختارة قبل تغيير العميل تتحول معه)
  void _applyRate(double rate) {
    _conversionRate = rate;
    _priceFactor = 1 / rate;
    for (final key in _cart.keys.toList()) {
      _cart[key] = _cart[key]!.withPriceFactor(_priceFactor);
    }
    _notify();
  }

  // ───────── 2) المجموعات والأصناف ─────────
  final List<String> _groups = [];
  bool _groupsLoading = false;
  String? _groupsError;
  String? _group;

  final Map<String, List<ErpItem>> _itemsByGroup = {};
  bool _itemsLoading = false;
  String? _itemsError;

  List<String> get groups => UnmodifiableListView(_groups);
  bool get groupsLoading => _groupsLoading;
  String? get groupsError => _groupsError;
  String? get group => _group;

  bool get itemsLoading => _itemsLoading;
  String? get itemsError => _itemsError;
  List<ErpItem> get items => _itemsByGroup[_group] ?? const [];

  Future<void> loadGroups() async {
    _groupsLoading = true;
    _groupsError = null;
    _notify();
    try {
      final list = await _orders.fetchItemGroups();
      list.sort();
      _groups
        ..clear()
        ..addAll(list);
    } catch (e) {
      debugPrint('OrderController.loadGroups: $e');
      _groupsError = describeError(e, fallback: AppStrings.loadGroupsError);
    } finally {
      _groupsLoading = false;
      _notify();
    }
  }

  Future<void> selectGroup(String name) async {
    if (_group == name && _itemsError == null) return;
    _group = name;
    _itemsError = null;

    // أصناف المجموعة محفوظة في الذاكرة بعد أول تحميل
    if (_itemsByGroup.containsKey(name)) {
      _itemsLoading = false;
      _notify();
      return;
    }

    _itemsLoading = true;
    _notify();
    try {
      _itemsByGroup[name] = await _orders.fetchItems(name);
    } catch (e) {
      debugPrint('OrderController.selectGroup($name): $e');
      if (_group == name) {
        _itemsError = describeError(e, fallback: AppStrings.loadItemsError);
      }
    } finally {
      // إن بدّل المستخدم المجموعة أثناء التحميل فلا نلمس حالة المجموعة الجديدة
      if (_group == name) _itemsLoading = false;
      _notify();
    }
  }

  void retryItems() {
    final current = _group;
    if (current == null) return;
    _group = null;
    selectGroup(current);
  }

  // ───────── السعر والمخزون (عند الضغط على صنف) ─────────
  final Map<String, ItemPricing> _pricing = {};
  final Set<String> _pricingLoading = {};
  final Map<String, String> _pricingErrors = {};

  ItemPricing? pricingOf(String code) => _pricing[code];
  bool isPricingLoading(String code) => _pricingLoading.contains(code);
  String? pricingError(String code) => _pricingErrors[code];

  /// يجلب السعر والمخزون مرة واحدة لكل صنف (ثم يُستخدم المحفوظ).
  Future<void> loadPricing(ErpItem item) async {
    final code = item.code;
    if (_pricing.containsKey(code) || _pricingLoading.contains(code)) return;

    _pricingLoading.add(code);
    _pricingErrors.remove(code);
    _notify();
    try {
      _pricing[code] = await _orders.fetchPricing(code);
    } catch (e) {
      debugPrint('OrderController.loadPricing($code): $e');
      _pricingErrors[code] = describeError(
        e,
        fallback: AppStrings.loadPricingError,
      );
    } finally {
      _pricingLoading.remove(code);
      _notify();
    }
  }

  // ───────── السلة ─────────
  final LinkedHashMap<String, CartLine> _cart = LinkedHashMap();

  List<CartLine> get lines => UnmodifiableListView(_cart.values.toList());
  bool get hasLines => _cart.isNotEmpty;
  int get lineCount => _cart.length;

  /// الإجمالي الحي = مجموع (الكمية × price_list_rate). بلا أي طلب للشبكة.
  double get total => _cart.values.fold(0.0, (sum, l) => sum + l.total);

  double qtyOf(String code) => _cart[code]?.qty ?? 0;

  /// يضبط كمية صنف (يحدّها بالمتاح). 0 أو أقل يحذفه من السلة.
  /// يعيد true إن اضطررنا لتقليل الكمية المطلوبة إلى المتاح.
  bool setQty(ErpItem item, double qty) {
    final pricing = _pricing[item.code];
    if (pricing == null || !pricing.orderable) return false;

    var clamped = false;
    if (qty > pricing.available) {
      qty = pricing.available;
      clamped = true;
    }

    if (qty <= 0) {
      _cart.remove(item.code);
    } else {
      _cart[item.code] = CartLine(
        item: item,
        pricing: pricing,
        qty: qty,
        priceFactor: _priceFactor,
      );
    }
    _notify();
    return clamped;
  }

  bool increment(ErpItem item) => setQty(item, qtyOf(item.code) + 1);

  void decrement(ErpItem item) {
    final current = qtyOf(item.code);
    // كمية كسرية (مثل 0.5) تنزل إلى الصفر بدل أن تصبح سالبة
    setQty(item, current - 1 < 0 ? 0 : current - 1);
  }

  void remove(String code) {
    if (_cart.remove(code) != null) _notify();
  }

  // ───────── 3) الفاتورة والتسليم ─────────
  late DateTime _deliveryDate = _today();
  DateTime get deliveryDate => _deliveryDate;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get today => _today();

  void setDeliveryDate(DateTime date) {
    _deliveryDate = date;
    _notify();
  }

  /// ملاحظات الطلبية (اختيارية) تُكتب قبل الإرسال
  String _notes = '';
  String get notes => _notes;

  /// لا نُشعر المستمعين عند كل حرف: الحقل يحتفظ بنصه بنفسه.
  void setNotes(String value) => _notes = value;

  // ───────── التنقل بين الخطوات ─────────
  bool get canGoNext => switch (_step) {
        // لا متابعة قبل معرفة سعر صرف عملة العميل (إن لم تكن الشيكل)
        OrderStep.customer =>
          _customer != null && !_rateLoading && _rateError == null,
        OrderStep.items => _cart.isNotEmpty,
        OrderStep.invoice => false,
        OrderStep.done => false,
      };

  void next() {
    if (!canGoNext) return;
    switch (_step) {
      case OrderStep.customer:
        _step = OrderStep.items;
        if (_groups.isEmpty && !_groupsLoading) loadGroups();
      case OrderStep.items:
        _step = OrderStep.invoice;
      case OrderStep.invoice:
      case OrderStep.done:
        return;
    }
    _notify();
  }

  void back() {
    switch (_step) {
      case OrderStep.items:
        _step = OrderStep.customer;
      case OrderStep.invoice:
        _step = OrderStep.items;
      case OrderStep.customer:
      case OrderStep.done:
        return;
    }
    _notify();
  }

  /// هل في الطلبية شيء سيضيع عند الخروج؟
  bool get hasUnsavedWork => _step != OrderStep.done && _cart.isNotEmpty;

  // ───────── الإرسال ─────────
  bool _submitting = false;
  String? _submitError;
  CreatedOrder? _created;

  bool get submitting => _submitting;
  String? get submitError => _submitError;
  CreatedOrder? get created => _created;

  /// false إن نجحت الطلبية في ERPNext لكن تعذّر حفظ الفاتورة محليًا
  bool _invoiceSaved = true;
  bool get invoiceSaved => _invoiceSaved;

  /// true = لا اتصال بالخادم: حُفظت الطلبية على الجهاز وستُرفع تلقائيًا لاحقًا
  bool _savedOffline = false;
  bool get savedOffline => _savedOffline;

  Future<void> submit() async {
    final customer = _customer;
    if (_submitting || customer == null || _cart.isEmpty) return;

    _submitting = true;
    _submitError = null;
    _notify();
    try {
      final lines = _cart.values.toList();
      final order = await _orders.createOrder(
        customerId: customer.id,
        deliveryDate: _deliveryDate,
        lines: lines,
        currency: _currencyCode,
        conversionRate: _conversionRate,
        notes: _notes,
      );
      _created = order;

      // الطلبية نجحت في ERPNext: نخزّن فاتورتها محليًا للعميل.
      // فشل التخزين لا يلغي الطلبية، لكن نسجّله ونُظهره في شاشة النجاح.
      try {
        final saved = await _invoiceRepo.saveOrderInvoice(
          customer: customer,
          order: order,
          lines: lines,
          deliveryDate: _deliveryDate,
          notes: _notes,
        );
        _invoiceSaved = saved != null;
      } catch (e) {
        debugPrint('OrderController.saveOrderInvoice: $e');
        _invoiceSaved = false;
      }
      _step = OrderStep.done;
    } catch (e) {
      if (e is ErpApiException && e.type == ErpErrorType.network) {
        // لا اتصال بالخادم: نحفظ الطلبية محليًا لترفع تلقائيًا عند عودة الاتصال
        debugPrint('OrderController.submit offline: $e');
        await _saveOffline(customer);
      } else {
        debugPrint('OrderController.submit: $e');
        final base = describeError(e, fallback: AppStrings.orderCreateFailed);
        // رسالة ERPNext الفعلية (مثل حقل ناقص) تساعد على معرفة السبب
        final detail = e is ErpApiException && e.type == ErpErrorType.server
            ? e.detail
            : null;
        _submitError = detail == null || detail.isEmpty
            ? base
            : '${AppStrings.orderCreateFailed}\n$detail';
      }
    } finally {
      _submitting = false;
      _notify();
    }
  }

  /// يحفظ الطلبية وفاتورتها على الجهاز (بحالة «بانتظار الرفع») ثم يطلب من خدمة
  /// المزامنة رفعها حين يتوفر الخادم. فشل الحفظ المحلي يظهر كخطأ عادي.
  Future<void> _saveOffline(ErpCustomer customer) async {
    // طلبية بعملة غير الشيكل تحتاج سعر صرف من الخادم وقت الإرسال، فلا تُحفظ دون اتصال
    if (_currencyCode != ErpConfig.priceListCurrency) {
      _submitError = AppStrings.orderOfflineNeedsConnection;
      return;
    }
    final lines = _cart.values.toList();
    final total = lines.fold<double>(0, (sum, l) => sum + l.total);
    try {
      local.Invoice? invoice;
      try {
        invoice = await _invoiceRepo.saveOrderInvoice(
          customer: customer,
          order: CreatedOrder(id: '', total: total, itemCount: lines.length),
          lines: lines,
          deliveryDate: _deliveryDate,
          notes: _notes,
        );
        _invoiceSaved = invoice != null;
      } catch (e) {
        debugPrint('OrderController.saveOfflineInvoice: $e');
        _invoiceSaved = false;
      }

      await _pendingRepo.add(
        PendingOrder(
          customerErpId: customer.id,
          customerName: customer.name,
          transactionDate: _isoDate(DateTime.now()),
          deliveryDate: _isoDate(_deliveryDate),
          lines: [
            for (final l in lines)
              PendingOrderLine(
                code: l.item.code,
                name: l.item.name,
                qty: l.qty,
                rate: l.rate,
              ),
          ],
          total: total,
          createdAt: DateTime.now(),
          invoiceId: invoice?.id,
          notes: _notes.trim().isEmpty ? null : _notes.trim(),
        ),
      );

      _created = CreatedOrder(id: '', total: total, itemCount: lines.length);
      _savedOffline = true;
      _step = OrderStep.done;
      unawaited(_sync.onPendingChanged());
    } catch (e) {
      debugPrint('OrderController._saveOffline: $e');
      _submitError = AppStrings.orderOfflineSaveFailed;
    }
  }

  static String _isoDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  void clearSubmitError() {
    if (_submitError == null) return;
    _submitError = null;
    _notify();
  }

  /// بعد النجاح: طلبية جديدة من الصفر مع إبقاء قائمة العملاء المحمّلة.
  void startNewOrder() {
    _step = OrderStep.customer;
    _customer = null;
    _query = '';
    _cart.clear();
    _created = null;
    _invoiceSaved = true;
    _savedOffline = false;
    _submitError = null;
    _rateRequest++;
    _rateLoading = false;
    _rateError = null;
    _conversionRate = 1;
    _priceFactor = 1;
    _group = null;
    _deliveryDate = _today();
    _notes = '';
    // السعر والمخزون تغيّرا على الأرجح بعد الطلبية، فنعيد جلبهما
    _pricing.clear();
    _pricingErrors.clear();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
