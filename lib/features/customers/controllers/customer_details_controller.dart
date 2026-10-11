import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/operation.dart';
import '../../../data/repositories/operation_repository.dart';

/// حالة ومنطق شاشة تفاصيل عميل واحد: رصيده وعملياته وإضافة دين أو دفعة.
/// يُنشأ لكل عميل عند فتح الشاشة ويُتلف عند إغلاقها، فلا تختلط بيانات عميل بآخر.
/// لا يعرف شيئًا عن الواجهة ولا عن SQL، ووصوله للبيانات عبر [OperationRepository].
class CustomerDetailsController extends ChangeNotifier {
  CustomerDetailsController(
    this._repository, {
    required this.customer,
  }) : assert(customer.id != null, 'يجب أن يكون للعميل id');

  final Customer customer;
  final OperationRepository _repository;

  // ───────────────────────── الحالة ─────────────────────────

  final List<Operation> _operations = [];
  double _balance = 0;

  /// تبدأ true وتصبح false بعد انتهاء التحميل الأول
  bool _isLoading = true;

  /// رسالة الخطأ (null = لا يوجد خطأ)
  String? _error;

  bool _isSaving = false;
  int _requestId = 0; // لتجاهل نتائج الطلبات القديمة
  bool _disposed = false;

  int get _customerId => customer.id!;

  /// العمليات من الأحدث إلى الأقدم
  List<Operation> get operations => UnmodifiableListView(_operations);
  double get balance => _balance;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
      await _repository.addOperation(
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
    final operations = await _repository.getOperations(_customerId);
    final balance = await _repository.getBalance(_customerId);
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

/// ينشئ [CustomerDetailsController] لعميل معيّن ويحمل اعتماداته (الـ repository)،
/// فلا تحتاج الشاشات أن تعرف شيئًا عن طبقة البيانات.
class CustomerDetailsControllerFactory {
  CustomerDetailsControllerFactory(this._repository);

  final OperationRepository _repository;

  CustomerDetailsController create(Customer customer) {
    return CustomerDetailsController(_repository, customer: customer);
  }
}