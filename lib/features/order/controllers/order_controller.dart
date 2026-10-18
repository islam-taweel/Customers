import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/erp_customer.dart';
import '../../../data/models/order_models.dart';
import '../../../data/repositories/erp_customer_repository.dart';
import '../../../data/repositories/erp_order_repository.dart';
import '../../../data/repositories/invoice_repository.dart';

/// خطوات الطلبية. [done] بعد نجاح الإرسال.
enum OrderStep { customer, items, invoice, done }

/// ينشئ متحكمًا جديدًا لكل طلبية تُفتح (نفس نمط CustomerDetailsControllerFactory).
class OrderControllerFactory {
  OrderControllerFactory(this._orders, this._customers, this._invoices);

  final ErpOrderRepository _orders;
  final ErpCustomerRepository _customers;
  final InvoiceRepository _invoices;

  OrderController create() => OrderController(_orders, _customers, _invoices);
}

/// حالة شاشة «طلبية جديدة» كلها: العميل المختار، المجموعات والأصناف، السلة،
/// والإرسال. الواجهة تقرأ منه فقط وتستدعي دوالّه.
class OrderController extends ChangeNotifier {
  OrderController(this._orders, this._customerRepo, this._invoiceRepo) {
    loadCustomers();
  }

  final ErpOrderRepository _orders;
  final ErpCustomerRepository _customerRepo;
  final InvoiceRepository _invoiceRepo;

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
      final list = await _customerRepo.fetchCustomers();
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

  /// اختيار عميل واحد فقط: الضغط على عميل آخر يستبدل الأول.
  void selectCustomer(ErpCustomer customer) {
    _customer = customer;
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
      _cart[item.code] = CartLine(item: item, pricing: pricing, qty: qty);
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

  // ───────── التنقل بين الخطوات ─────────
  bool get canGoNext => switch (_step) {
        OrderStep.customer => _customer != null,
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
        );
        _invoiceSaved = saved != null;
      } catch (e) {
        debugPrint('OrderController.saveOrderInvoice: $e');
        _invoiceSaved = false;
      }
      _step = OrderStep.done;
    } catch (e) {
      debugPrint('OrderController.submit: $e');
      final base = describeError(e, fallback: AppStrings.orderCreateFailed);
      // رسالة ERPNext الفعلية (مثل حقل ناقص) تساعد على معرفة السبب
      final detail = e is ErpApiException && e.type == ErpErrorType.server
          ? e.detail
          : null;
      _submitError = detail == null || detail.isEmpty
          ? base
          : '${AppStrings.orderCreateFailed}\n$detail';
    } finally {
      _submitting = false;
      _notify();
    }
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
    _submitError = null;
    _group = null;
    _deliveryDate = _today();
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
