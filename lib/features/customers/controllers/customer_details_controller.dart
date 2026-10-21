import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/whatsapp_launcher.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/api/erp_config.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/operation.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/models/invoice.dart';
import '../../../data/repositories/erp_draft_repository.dart';
import '../../../data/repositories/erp_lookup_repository.dart';
import '../../../data/repositories/erp_payment_repository.dart';
import '../../../data/repositories/erp_invoice_repository.dart';
import '../../../data/repositories/pending_order_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/models/sales_invoice.dart';
import '../../../data/repositories/operation_repository.dart';
import '../../../data/repositories/outstanding_repository.dart';
import 'customer_invoices_controller.dart';
import 'draft_invoice_controller.dart';
import 'invoice_details_controller.dart';

/// حالة ومنطق عميل واحد: بياناته ورصيده وعملياته، وتعديل بياناته، وإضافة دين أو دفعة.
/// يُنشأ لكل عميل عند فتح شاشة التفاصيل ويُتلف عند إغلاقها، فلا تختلط بيانات عميل بآخر.
/// لا يعرف شيئًا عن الواجهة ولا عن SQL، ووصوله للبيانات عبر الـ repositories.
class CustomerDetailsController extends ChangeNotifier {
  CustomerDetailsController(
    this._operationRepository,
    this._customerRepository,
    this._whatsAppLauncher,
    this._erpInvoiceRepository,
    this._invoiceRepository,
    this._draftRepository,
    this._pendingRepository,
    this._lookupRepository,
    this._paymentRepository,
    this._customer,
  ) : assert(_customer.id != null, 'يجب أن يكون للعميل id');

  final OperationRepository _operationRepository;
  final CustomerRepository _customerRepository;
  final WhatsAppLauncher _whatsAppLauncher;

  /// فواتير ERPNext فقط (العملاء والديون تبقى في قاعدة البيانات المحلية)
  final ErpInvoiceRepository _erpInvoiceRepository;

  /// فواتير الطلبيات المحفوظة على الهاتف
  final InvoiceRepository _invoiceRepository;

  /// تعديل المسودات وحذفها واعتمادها في ERPNext
  final ErpDraftRepository _draftRepository;

  /// الطلبيات المنتظرة للرفع (مسودات أُنشئت دون اتصال)
  final PendingOrderRepository _pendingRepository;

  /// العملات وطرق الدفع من ERPNext
  final ErpLookupRepository _lookupRepository;

  /// تسجيل الدفعة كـ Payment Entry في ERPNext
  final ErpPaymentRepository _paymentRepository;

  // ───────────────────────── الحالة ─────────────────────────

  /// بيانات العميل (تتغير بعد التعديل، فتتحدث الشاشات التي تعرضها تلقائيًا)
  Customer _customer;

  final List<Operation> _operations = [];

  /// رصيد العميل المحلي لكل عملة (لا تُجمع العملات ولا تُحوَّل)
  List<CurrencyAmount> _balances = const [];

  /// تبدأ true وتصبح false بعد انتهاء التحميل الأول
  bool _isLoading = true;

  /// رسالة الخطأ (null = لا يوجد خطأ)
  String? _error;

  /// العملات وطرق الدفع المحمّلة من ERPNext (تُحمَّل عند فتح نافذة الدين/الدفعة)
  List<String> _currencies = const [];
  List<String> _modesOfPayment = const [];

  /// سبب فشل آخر عملية حفظ (null = لا يوجد)، لتعرضه الواجهة
  String? _saveError;

  bool _isSaving = false; // حفظ دين/دفعة
  bool _isSavingCustomer = false; // حفظ تعديل بيانات العميل
  int _requestId = 0; // لتجاهل نتائج الطلبات القديمة
  bool _disposed = false;

  int get _customerId => _customer.id!;

  Customer get customer => _customer;

  /// العمليات من الأحدث إلى الأقدم
  List<Operation> get operations => UnmodifiableListView(_operations);

  /// رصيد كل عملة على حدة، والفارغة = الحساب مسدد
  List<CurrencyAmount> get balances => UnmodifiableListView(_balances);

  /// هل على العميل مبلغ مستحق بأي عملة؟
  bool get hasDebt => _balances.any((b) => b.amount > 0);


  /// العملات المتاحة (عند تعذّر التحميل: عملة الشركة الافتراضية فقط)
  List<String> get currencies => UnmodifiableListView(
        _currencies.isEmpty ? [ErpConfig.priceListCurrency] : _currencies,
      );

  List<String> get modesOfPayment => UnmodifiableListView(_modesOfPayment);

  /// سبب فشل آخر حفظ، أو null
  String? get saveError => _saveError;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// true أثناء حفظ تعديل بيانات العميل (لتعطيل زر الحفظ)
  bool get isSavingCustomer => _isSavingCustomer;

  // ───────────────────────── التحميل ─────────────────────────

  /// التحميل الأول (ويُستخدم أيضًا لإعادة المحاولة بعد خطأ).
  Future<void> load() async {
    final requestId = ++_requestId;
    _isLoading = true;
    _error = null;
    _notify();

    try {
      final data = await _fetch();
      if (_isStale(requestId)) return;
      _apply(data);
    } catch (e) {
      if (_isStale(requestId)) return;
      debugPrint('CustomerDetailsController.load failed: $e');
      _error = AppStrings.loadOperationsError;
    }

    _isLoading = false;
    _notify();
  }

  /// تحديث الرصيد والعمليات دون إظهار مؤشر تحميل (بعد إضافة عملية مثلًا).
  Future<void> refresh() async {
    final requestId = ++_requestId;

    try {
      final data = await _fetch();
      if (_isStale(requestId)) return;
      _apply(data);
      _error = null;
    } catch (e) {
      if (_isStale(requestId)) return;
      debugPrint('CustomerDetailsController.refresh failed: $e');
      _error = AppStrings.loadOperationsError;
    }

    _isLoading = false;
    _notify();
  }

  /// تحميل العملات وطرق الدفع قبل فتح نافذة الدين/الدفعة.
  /// فشل أحدهما لا يمنع الآخر، ولا يمنع فتح النافذة.
  Future<void> loadLookups() async {
    if (_currencies.isNotEmpty && _modesOfPayment.isNotEmpty) return;
    final results = await Future.wait([
      _safeList(_lookupRepository.fetchCurrencies),
      _safeList(_lookupRepository.fetchModesOfPayment),
    ]);
    if (results[0].isNotEmpty) _currencies = results[0];
    if (results[1].isNotEmpty) _modesOfPayment = results[1];
  }

  Future<List<String>> _safeList(Future<List<String>> Function() load) async {
    try {
      return await load();
    } catch (e) {
      debugPrint('CustomerDetailsController.loadLookups failed: $e');
      return const [];
    }
  }

  // ───────────────────────── تعديل بيانات العميل ─────────────────────────

  /// حفظ الاسم والهاتف الجديدين عبر الـ repository، ثم تحديث [customer] فتتحدث
  /// الشاشات التي تعرضه فورًا دون إعادة تحميل.
  ///
  /// تُرجع [Customer] المحدَّث عند النجاح، أو null عند الفشل
  /// (مدخلات غير صالحة، أو العميل غير موجود، أو خطأ في القاعدة).
  Future<Customer?> updateCustomer({
    required String name,
    required String phone,
  }) async {
    if (_isSavingCustomer) return null;

    final cleanName = name.trim();
    final cleanPhone = normalizeDigits(phone.trim());

    // حماية ثانية بعد تحقق الواجهة: القواعد نفسها في مكان واحد
    if (Validators.name(cleanName) != null ||
        Validators.phone(cleanPhone) != null) {
      return null;
    }

    _isSavingCustomer = true;
    _notify();

    try {
      final updated = _customer.copyWith(name: cleanName, phone: cleanPhone);
      final rows = await _customerRepository.updateCustomer(updated);
      if (rows == 0) return null; // العميل غير موجود

      _customer = updated;
      return updated;
    } catch (e) {
      debugPrint('CustomerDetailsController.updateCustomer failed: $e');
      return null;
    } finally {
      _isSavingCustomer = false;
      _notify();
    }
  }

  // ───────────────────────── فواتير ERPNext ─────────────────────────

  /// متحكم قائمة فواتير هذا العميل (تبويب الفاتورة)، فلا تحتاج الواجهة أن تعرف الـ repository.
  CustomerInvoicesController createInvoicesController() {
    return CustomerInvoicesController(
      _erpInvoiceRepository,
      _invoiceRepository,
      _customer,
    );
  }

  /// متحكم شاشة فاتورة معتمدة محفوظة محليًا (طلبية Sales Order): التفاصيل جاهزة
  /// دون شبكة، وملف PDF يُطلب من ERPNext.
  InvoiceDetailsController openLocalInvoice(SalesInvoiceDetail detail) {
    return InvoiceDetailsController.local(
      _erpInvoiceRepository,
      detail,
      customerPhone: _customer.phone,
    );
  }

  /// متحكم مسودة واحدة (عرض/تعديل/حذف/اعتماد).
  DraftInvoiceController openDraft(Invoice invoice) {
    return DraftInvoiceController(
      _invoiceRepository,
      _pendingRepository,
      _draftRepository,
      invoice,
    );
  }

  /// متحكم شاشة تفاصيل فاتورة معيّنة.
  InvoiceDetailsController openInvoice(String invoiceName) {
    return InvoiceDetailsController(
      _erpInvoiceRepository,
      invoiceName,
      customerPhone: _customer.phone,
    );
  }

  // ───────────────────────── واتساب ─────────────────────────

  /// يفتح واتساب على محادثة العميل برسالة عربية جاهزة فيها اسمه والمبلغ المستحق عليه.
  /// لا ترمي استثناءات: النتيجة [WhatsAppResult] تُترجم في الواجهة إلى رسالة للمستخدم.
  Future<WhatsAppResult> sendWhatsAppReminder() async {
    // لا معنى للتذكير إن لم يكن على العميل دين (والزر مخفي أصلًا في هذه الحالة)
    if (!hasDebt) return WhatsAppResult.noDebt;

    final message = AppStrings.whatsappDebtMessage(
      _customer.name,
      // مبلغ لكل عملة عليه فيها دين: «100 ₪ و 30 USD»
      [
        for (final b in _balances)
          if (b.amount > 0) formatAmount(b.amount, currency: b.currency),
      ].join(AppStrings.isArabic ? ' و ' : ' and '),
    );
    return _whatsAppLauncher.send(localPhone: _customer.phone, message: message);
  }

  // ───────────────────────── إضافة عملية ─────────────────────────

  /// حفظ دين أو دفعة جديدة ثم تحديث الرصيد والسجل. تُرجع true عند النجاح.
  /// التاريخ يُسجَّل هنا بوقت الجهاز الحالي، فالواجهة لا تحدده.
  ///
  /// الدفعة لعميل مرتبط بـ ERPNext تُسجَّل أولًا كـ Payment Entry (بالعملة وطريقة
  /// الدفع المختارتين)، ولا تُحفظ محليًا إلا إن نجح ذلك، فلا يختلف الرصيد المحلي
  /// عن ERPNext. وعند الفشل يُوضَّح السبب في [saveError].
  Future<bool> addOperation({
    required OperationType type,
    required double amount,
    required String currency,
    String? modeOfPayment,
    String? note,
  }) async {
    if (!amount.isFinite || amount <= 0 || _isSaving) return false;
    _isSaving = true;
    _saveError = null;

    final trimmedNote = note?.trim();
    final cleanNote =
        (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote;
    final isPayment = type == OperationType.payment;
    final mode = isPayment ? modeOfPayment : null;
    final now = DateTime.now();

    try {
      String? paymentEntry;
      if (isPayment) {
        final erpId = await _customerRepository.getErpId(_customerId);
        if (erpId != null) {
          if (mode == null || mode.isEmpty) {
            _saveError = AppStrings.modeOfPaymentRequired;
            return false;
          }
          paymentEntry = await _paymentRepository.createPaymentEntry(
            customerErpId: erpId,
            amount: amount,
            currency: currency,
            modeOfPayment: mode,
            date: now,
            note: cleanNote,
          );
        }
      }

      await _operationRepository.addOperation(
        Operation(
          customerId: _customerId,
          amount: amount,
          type: type,
          note: cleanNote,
          date: now,
          currency: currency,
          modeOfPayment: mode,
          paymentEntry: paymentEntry,
        ),
      );
    } catch (e) {
      debugPrint('CustomerDetailsController.addOperation failed: $e');
      _saveError = _describeSaveError(e);
      return false;
    } finally {
      _isSaving = false;
    }

    await refresh();
    return true;
  }

  // ───────────────────────── داخلي ─────────────────────────

  /// رسالة سبب الفشل: تفاصيل ERPNext (حقل ناقص مثلًا) إن وُجدت، وإلا الرسالة العامة.
  String _describeSaveError(Object e) {
    if (e is ErpApiException &&
        e.type == ErpErrorType.server &&
        (e.detail ?? '').isNotEmpty) {
      return e.detail!;
    }
    return describeError(e, fallback: AppStrings.operationSaveFailed);
  }

  Future<({List<Operation> operations, List<CurrencyAmount> balances})>
      _fetch() async {
    final operations = await _operationRepository.getOperations(_customerId);
    final balances = await _operationRepository.getBalances(_customerId);
    return (operations: operations, balances: balances);
  }

  void _apply(
    ({List<Operation> operations, List<CurrencyAmount> balances}) data,
  ) {
    _operations
      ..clear()
      ..addAll(data.operations);
    _balances = data.balances;
  }

  bool _isStale(int requestId) => _disposed || requestId != _requestId;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// ينشئ [CustomerDetailsController] لعميل معيّن ويحمل اعتماداته (الـ repositories)،
/// فلا تحتاج الشاشات أن تعرف شيئًا عن طبقة البيانات.
class CustomerDetailsControllerFactory {
  CustomerDetailsControllerFactory(
    this._operationRepository,
    this._customerRepository,
    this._whatsAppLauncher,
    this._erpInvoiceRepository,
    this._invoiceRepository,
    this._draftRepository,
    this._pendingRepository,
    this._lookupRepository,
    this._paymentRepository,
  );

  final OperationRepository _operationRepository;
  final CustomerRepository _customerRepository;
  final WhatsAppLauncher _whatsAppLauncher;
  final ErpInvoiceRepository _erpInvoiceRepository;
  final InvoiceRepository _invoiceRepository;
  final ErpDraftRepository _draftRepository;
  final PendingOrderRepository _pendingRepository;
  final ErpLookupRepository _lookupRepository;
  final ErpPaymentRepository _paymentRepository;

  CustomerDetailsController create(Customer customer) {
    return CustomerDetailsController(
      _operationRepository,
      _customerRepository,
      _whatsAppLauncher,
      _erpInvoiceRepository,
      _invoiceRepository,
      _draftRepository,
      _pendingRepository,
      _lookupRepository,
      _paymentRepository,
      customer,
    );
  }
}