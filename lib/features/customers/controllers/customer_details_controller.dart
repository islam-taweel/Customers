import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/operation.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/operation_repository.dart';

/// حالة ومنطق عميل واحد: بياناته ورصيده وعملياته، وتعديل بياناته، وإضافة دين أو دفعة.
/// يُنشأ لكل عميل عند فتح شاشة التفاصيل ويُتلف عند إغلاقها، فلا تختلط بيانات عميل بآخر.
/// لا يعرف شيئًا عن الواجهة ولا عن SQL، ووصوله للبيانات عبر الـ repositories.
class CustomerDetailsController extends ChangeNotifier {
  CustomerDetailsController(
    this._operationRepository,
    this._customerRepository,
    this._customer,
  ) : assert(_customer.id != null, 'يجب أن يكون للعميل id');

  final OperationRepository _operationRepository;
  final CustomerRepository _customerRepository;

  // ───────────────────────── الحالة ─────────────────────────

  /// بيانات العميل (تتغير بعد التعديل، فتتحدث الشاشات التي تعرضها تلقائيًا)
  Customer _customer;

  final List<Operation> _operations = [];
  double _balance = 0;

  /// تبدأ true وتصبح false بعد انتهاء التحميل الأول
  bool _isLoading = true;

  /// رسالة الخطأ (null = لا يوجد خطأ)
  String? _error;

  bool _isSaving = false; // حفظ دين/دفعة
  bool _isSavingCustomer = false; // حفظ تعديل بيانات العميل
  int _requestId = 0; // لتجاهل نتائج الطلبات القديمة
  bool _disposed = false;

  int get _customerId => _customer.id!;

  Customer get customer => _customer;

  /// العمليات من الأحدث إلى الأقدم
  List<Operation> get operations => UnmodifiableListView(_operations);
  double get balance => _balance;
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

  // ───────────────────────── إضافة عملية ─────────────────────────

  /// حفظ دين أو دفعة جديدة ثم تحديث الرصيد والسجل. تُرجع true عند النجاح.
  /// التاريخ يُسجَّل هنا بوقت الجهاز الحالي، فالواجهة لا تحدده.
  Future<bool> addOperation({
    required OperationType type,
    required double amount,
    String? note,
  }) async {
    if (!amount.isFinite || amount <= 0 || _isSaving) return false;
    _isSaving = true;

    final trimmedNote = note?.trim();

    try {
      await _operationRepository.addOperation(
        Operation(
          customerId: _customerId,
          amount: amount,
          type: type,
          note: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
          date: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('CustomerDetailsController.addOperation failed: $e');
      return false;
    } finally {
      _isSaving = false;
    }

    await refresh();
    return true;
  }

  // ───────────────────────── داخلي ─────────────────────────

  Future<({List<Operation> operations, double balance})> _fetch() async {
    final operations = await _operationRepository.getOperations(_customerId);
    final balance = await _operationRepository.getBalance(_customerId);
    return (operations: operations, balance: balance);
  }

  void _apply(({List<Operation> operations, double balance}) data) {
    _operations
      ..clear()
      ..addAll(data.operations);
    _balance = data.balance;
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
  );

  final OperationRepository _operationRepository;
  final CustomerRepository _customerRepository;

  CustomerDetailsController create(Customer customer) {
    return CustomerDetailsController(
      _operationRepository,
      _customerRepository,
      customer,
    );
  }
}