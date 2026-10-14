import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/dev/fake_customers.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/customer_with_balance.dart';
import '../../../data/repositories/customer_repository.dart';

/// حالة ومنطق شاشة العملاء. لا يعرف شيئًا عن الواجهة ولا عن SQL،
/// وكل وصوله للبيانات يمر عبر [CustomerRepository].
class CustomersController extends ChangeNotifier {
  CustomersController(this._repository);

  final CustomerRepository _repository;

  static const _loadError = AppStrings.loadCustomersError;
  static const _loadMoreError = AppStrings.loadMoreCustomersError;

  // ───────────────────────── الحالة ─────────────────────────

  /// 1) قائمة العملاء المحمّلة حتى الآن
  final List<CustomerWithBalance> _customers = [];

  /// 2) تبدأ true، وتصبح false بعد انتهاء التحميل الأول
  bool _isLoading = true;

  /// 3) true فقط أثناء جلب الدفعة التالية عند التمرير للأسفل
  bool _isMoreLoading = false;

  /// 4) هل توجد بيانات لم تُجلب بعد؟ تصبح false عند جلب كل العملاء
  bool _hasMore = true;

  /// 5) رسالة الخطأ (null = لا يوجد خطأ)
  String? _error;

  double _totalDebts = 0;
  String _query = '';

  bool _isSeeding = false;

  Timer? _debounce;
  int _requestId = 0; // لتجاهل نتائج الطلبات القديمة
  bool _disposed = false;

  List<CustomerWithBalance> get customers => UnmodifiableListView(_customers);
  bool get isLoading => _isLoading;
  bool get isMoreLoading => _isMoreLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  double get totalDebts => _totalDebts;
  String get query => _query;

  // ───────────────────────── 6) أول صفحة ─────────────────────────

  /// جلب أول 20 عميل فقط (مع تطبيق البحث الحالي) واستبدال القائمة بهم.
  Future<void> loadFirstPage() async {
    final requestId = ++_requestId;
    _isLoading = true;
    _isMoreLoading = false;
    _error = null;
    _notify();

    try {
      final data = await _fetch(limit: CustomerRepository.pageSize);
      if (_isStale(requestId)) return;

      _customers
        ..clear()
        ..addAll(data.page.items);
      _hasMore = data.page.hasMore;
      _totalDebts = data.total;
    } catch (e) {
      if (_isStale(requestId)) return;
      debugPrint('loadFirstPage failed: $e');
      _customers.clear();
      _hasMore = false;
      _error = _loadError;
    }

    _isLoading = false;
    _notify();
  }

  // ───────────────────────── 7) الصفحة التالية ─────────────────────────

  /// جلب 20 عميل إضافية عند التمرير للأسفل وإلحاقهم بالقائمة.
  /// لا تفعل شيئًا إذا: التحميل جارٍ، أو لا توجد بيانات متبقية ([hasMore] = false)،
  /// أو حدث خطأ سابق (حتى لا تتكرر المحاولة الفاشلة مع كل حركة تمرير).
  Future<void> loadNextPage() async {
    if (_isLoading || _isMoreLoading || !_hasMore || _error != null) return;

    final requestId = _requestId;
    _isMoreLoading = true;
    _notify();

    try {
      final page = await _repository.getCustomers(
        offset: _customers.length,
        query: _query,
      );
      if (_isStale(requestId)) return;

      // حماية من التكرار: لا نضيف أي عميل موجود في القائمة أصلًا
      // (قد يحدث إذا تغيّرت البيانات بين طلبين متتاليين)
      final knownIds = {for (final c in _customers) c.customer.id};
      final fresh = page.items
          .where((c) => !knownIds.contains(c.customer.id))
          .toList();

      _customers.addAll(fresh);
      // إن لم تأتِ أي بيانات جديدة نتوقف، حتى لا تتكرر المحاولة بلا نهاية
      _hasMore = page.hasMore && fresh.isNotEmpty;
    } catch (e) {
      if (_isStale(requestId)) return;
      debugPrint('loadNextPage failed: $e');
      _error = _loadMoreError;
    }

    _isMoreLoading = false;
    _notify();
  }

  // ───────────────────────── 8) إضافة عميل ─────────────────────────

  /// حفظ عميل جديد في قاعدة البيانات ثم تحديث القائمة والإجمالي.
  /// تُرجع true عند النجاح.
  Future<bool> addCustomer(Customer customer) async {
    final name = customer.name.trim();
    final phone = normalizeDigits(customer.phone.trim());

    // حماية ثانية بعد تحقق الواجهة: القواعد نفسها المستخدمة في التعديل
    if (Validators.name(name) != null || Validators.phone(phone) != null) {
      return false;
    }

    try {
      await _repository.addCustomer(customer.copyWith(name: name, phone: phone));
    } catch (e) {
      debugPrint('addCustomer failed: $e');
      return false;
    }

    await refresh();
    return true;
  }

  // ───────────────────────── إضافات لازمة للشاشة ─────────────────────────

  /// تحديث ما هو معروض (نفس عدد العملاء المحمّلين) والإجمالي، دون إظهار
  /// مؤشر تحميل ودون العودة لأعلى القائمة. تُستخدم بعد إضافة عميل أو
  /// بعد الرجوع من شاشة التفاصيل (لأن الأرصدة قد تغيّرت).
  Future<void> refresh() async {
    final requestId = ++_requestId;
    final limit = math.max(_customers.length, CustomerRepository.pageSize);

    try {
      final data = await _fetch(limit: limit);
      if (_isStale(requestId)) return;

      _customers
        ..clear()
        ..addAll(data.page.items);
      _hasMore = data.page.hasMore;
      _totalDebts = data.total;
      _error = null;
    } catch (e) {
      if (_isStale(requestId)) return;
      debugPrint('refresh failed: $e');
      _error = _loadError;
    }

    _isLoading = false;
    _isMoreLoading = false;
    _notify();
  }

  /// إعادة المحاولة بعد خطأ: تحميل أول صفحة إن كانت القائمة فارغة، وإلا تحديث.
  Future<void> retry() {
    _error = null;
    return _customers.isEmpty ? loadFirstPage() : refresh();
  }

  /// البحث بالاسم: يُنفَّذ بعد توقف الكتابة 300 مللي ثانية، ويبدأ من أول صفحة.
  void search(String query) {
    _query = query;
    _notify(); // لتحديث زر المسح في الواجهة
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, loadFirstPage);
  }

  void clearSearch() {
    _debounce?.cancel();
    _query = '';
    loadFirstPage();
  }

  // ───────────────────────── للتطوير فقط ─────────────────────────

  /// إدخال [count] عميل وهمي في قاعدة البيانات ثم العودة لأول صفحة،
  /// لاختبار التصفح اللانهائي. لا تفعل شيئًا خارج وضع التطوير (debug).
  Future<bool> addFakeCustomers({
    int count = AppConstants.fakeCustomersCount,
  }) async {
    if (!kDebugMode || _isSeeding) return false;
    _isSeeding = true;

    try {
      await _repository.addCustomers(generateFakeCustomers(count));
    } catch (e) {
      debugPrint('addFakeCustomers failed: $e');
      return false;
    } finally {
      _isSeeding = false;
    }

    await loadFirstPage();
    return true;
  }

  // ───────────────────────── داخلي ─────────────────────────

  Future<({CustomersPage page, double total})> _fetch({required int limit}) async {
    final page = await _repository.getCustomers(limit: limit, query: _query);
    final total = await _repository.getTotalDebts();
    return (page: page, total: total);
  }

  bool _isStale(int requestId) => _disposed || requestId != _requestId;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}