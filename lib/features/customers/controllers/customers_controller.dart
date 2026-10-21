import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/dev/fake_customers.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/customer_sort_option.dart';
import '../../../data/models/customer_with_balance.dart';
import '../../../data/models/deleted_customer.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/erp_customer_repository.dart';
import '../../../data/repositories/outstanding_repository.dart';

/// حالة ومنطق شاشة العملاء. لا يعرف شيئًا عن الواجهة ولا عن SQL،
/// وكل وصوله للبيانات يمر عبر [CustomerRepository].
class CustomersController extends ChangeNotifier {
  CustomersController(
    this._repository,
    this._erpCustomers,
    this._outstandingRepository,
  );

  /// إجمالي المستحق على العملاء من ERPNext (بطاقة أعلى شاشة العملاء)
  final OutstandingRepository _outstandingRepository;

  final CustomerRepository _repository;

  /// مصدر أسماء العملاء وهواتفهم (ERPNext). الديون تبقى كلها في [_repository].
  final ErpCustomerRepository _erpCustomers;

  static String get _loadError => AppStrings.loadCustomersError;
  static String get _loadMoreError => AppStrings.loadMoreCustomersError;

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

  /// خيار الفرز الحالي. يبقى محفوظًا هنا، فيُطبَّق تلقائيًا على كل تحميل:
  /// الصفحة الأولى، الصفحات التالية، التحديث بعد الحذف أو الإضافة، والبحث.
  CustomerSortOption _sort = CustomerSortOption.name;

  bool _isSeeding = false;
  bool _isSyncing = false;

  Timer? _debounce;
  int _requestId = 0; // لتجاهل نتائج الطلبات القديمة
  bool _disposed = false;

  List<CustomerWithBalance> get customers => UnmodifiableListView(_customers);
  bool get isLoading => _isLoading;
  bool get isMoreLoading => _isMoreLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  double get totalDebts => _totalDebts;

  /// إجمالي المستحق من ERPNext لكل عملة (null = لم يُجلب بعد أو تعذّر)
  List<CurrencyAmount>? get totalOutstanding => _totalOutstanding;

  List<CurrencyAmount>? _totalOutstanding;

  /// مستحق كل عميل من ERPNext (المفتاح رقم العميل في ERPNext)
  Map<String, List<CurrencyAmount>>? _outstandingByCustomer;

  /// مستحق عميل واحد لكل عملة. null = لم يُجلب بعد، أو عميل محلي غير مرتبط بـ ERPNext.
  /// قائمة فارغة = لا مستحق عليه.
  List<CurrencyAmount>? outstandingFor(String? erpId) {
    final all = _outstandingByCustomer;
    if (all == null || erpId == null) return null;
    return all[erpId] ?? const [];
  }

  /// يجلب إجمالي المستحق ومستحق كل عميل من ERPNext. فشله يُبقي آخر قيمة معروفة.
  Future<void> loadTotalOutstanding() async {
    final results = await Future.wait<Object?>([
      _outstandingRepository.fetchTotal(),
      _outstandingRepository.fetchByCustomer(),
    ]);
    if (_disposed) return;
    final total = results[0] as List<CurrencyAmount>?;
    final byCustomer = results[1] as Map<String, List<CurrencyAmount>>?;
    if (total == null && byCustomer == null) return;
    if (total != null) _totalOutstanding = total;
    if (byCustomer != null) _outstandingByCustomer = byCustomer;
    _notify();
  }
  String get query => _query;
  CustomerSortOption get sort => _sort;

  // ───────────────────────── جلب العملاء من ERPNext ─────────────────────────

  /// يجلب أسماء العملاء وهواتفهم من ERPNext ويدمجها في القاعدة المحلية، ثم يحدّث
  /// القائمة. الباقي (البحث، الفرز، التصفح، الديون) يعمل على القاعدة المحلية كما كان،
  /// فتبقى القائمة تعمل دون إنترنت بآخر ما حُفظ.
  ///
  /// عند فشل الجلب تبقى القائمة المحلية كما هي، ولا يظهر خطأ إلا إن كانت فارغة.
  Future<void> syncFromApi() async {
    if (_isSyncing) return;
    _isSyncing = true;

    // قائمة فارغة (أول تشغيل): نُبقي مؤشر التحميل بدل رسالة «لا يوجد عملاء»
    if (_customers.isEmpty && !_isLoading) {
      _isLoading = true;
      _error = null;
      _notify();
    }

    String? syncError;
    try {
      final remote = await _erpCustomers.fetchCustomers();
      await _repository.syncFromErp(remote);
    } catch (e) {
      debugPrint('syncFromApi failed: $e');
      syncError = describeError(e, fallback: _loadError);
    } finally {
      _isSyncing = false;
    }
    if (_disposed) return;

    await refresh();

    if (syncError != null && _customers.isEmpty) {
      _error = syncError;
      _notify();
    }
  }

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
        sort: _sort,
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
  Future<void> refresh({int extraItems = 0}) async {
    final requestId = ++_requestId;
    final limit = math.max(
      _customers.length + extraItems,
      CustomerRepository.pageSize,
    );

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
    unawaited(loadTotalOutstanding());
  }

  /// إعادة المحاولة بعد خطأ: جلب العملاء من ERPNext إن كانت القائمة فارغة، وإلا تحديث.
  Future<void> retry() {
    _error = null;
    return _customers.isEmpty ? syncFromApi() : refresh();
  }

  /// تغيير الفرز: يحفظ الخيار الجديد ثم يعيد التحميل من الصفحة الأولى (offset = 0).
  /// لا يكفي ترتيب الصفحات المحمّلة محليًا، فالقائمة مقسّمة على صفحات والترتيب
  /// الصحيح لا يعرفه إلا SQL على كل العملاء. وإعادة التحميل من الأول تتجنب
  /// خلط صفحات بترتيبين مختلفين.
  Future<void> setSort(CustomerSortOption option) {
    if (option == _sort) return Future.value();
    _sort = option;
    _debounce?.cancel(); // لا نُبقي بحثًا مؤجلًا يُعيد التحميل مرة ثانية
    _notify(); // لتحديث علامة الخيار المحدد في القائمة فورًا
    return loadFirstPage();
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

  // ───────────────────────── حذف العميل ─────────────────────────

  /// حذف عميل وكل عملياته. يُزال من القائمة **فورًا** (يتطلبه Dismissible: يجب ألا
  /// يبقى العنصر في الشجرة بعد السحب)، ثم يُحذف من القاعدة داخل معاملة واحدة.
  ///
  /// تُرجع نسخة المحذوف لاستعادتها عند التراجع، أو null عند الفشل
  /// (وفي حال خطأ في القاعدة يعود العميل إلى مكانه في القائمة).
  Future<DeletedCustomer?> deleteCustomer(CustomerWithBalance item) async {
    final id = item.customer.id;
    if (id == null) return null;

    // 1) إزالة فورية من القائمة المعروضة
    final index = _customers.indexWhere((c) => c.customer.id == id);
    if (index != -1) {
      _customers.removeAt(index);
      _notify();
    }

    // 2) الحذف الفعلي (العميل + عملياته) في معاملة واحدة
    final DeletedCustomer? deleted;
    try {
      deleted = await _repository.deleteCustomer(id);
    } catch (e) {
      debugPrint('deleteCustomer failed: $e');
      if (index != -1) {
        _customers.insert(math.min(index, _customers.length), item);
        _notify();
      }
      return null;
    }

    // 3) مزامنة القائمة والإجمالي مع القاعدة (صامتة، دون مؤشر تحميل). وهي تلغي
    //    أي جلب صفحة تالية كان جاريًا، فلا تتكرر عناصر ولا يضيع عنصر بسبب الإزاحة.
    await refresh();
    return deleted;
  }

  /// التراجع عن الحذف: إعادة العميل وكل عملياته بنفس الـ id في معاملة واحدة،
  /// ثم تحديث القائمة. تُرجع true عند النجاح.
  Future<bool> restoreCustomer(DeletedCustomer deleted) async {
    try {
      await _repository.restoreCustomer(deleted);
    } catch (e) {
      debugPrint('restoreCustomer failed: $e');
      return false;
    }

    await refresh(extraItems: 1);
    return true;
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
    final page = await _repository.getCustomers(
      limit: limit,
      query: _query,
      sort: _sort,
    );
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