import 'package:get/get.dart';

import '../../data/api/erp_auth_service.dart';
import '../../data/api/session_store.dart';

/// حالة الجلسة للتطبيق كله (GetX، دائمة): داخل أم لا، الاسم، وهل انتهت الجلسة.
///
/// غلاف حول [SessionStore] و[ErpAuthService] الموجودين، لا بديل عنهما:
/// - `sid` لا يُحفظ هنا أبدًا: [SessionStore] هو المصدر الوحيد له.
/// - القيم التفاعلية مرآة للـ store، يكتبها [_syncFromStore] وحده بعد كل تغيّر
///   (التحميل، الدخول، الخروج، انتهاء الجلسة).
/// - [init] هي الموضع الوحيد الذي يستدعي `SessionStore.load()`، مرة واحدة.
class SessionService extends GetxService {
  SessionService(this._store, this._auth);

  final SessionStore _store;
  final ErpAuthService _auth;

  final isAuthenticated = false.obs;
  final fullName = RxnString();

  /// انتهت الجلسة من الخادم (تعرض شاشة الدخول تنبيهًا بذلك)
  final sessionExpired = false.obs;

  Future<void>? _initFuture;

  /// نفس الـ store الذي يأخذه ErpApiClient و ErpAuthService
  SessionStore get store => _store;

  /// يحمّل الجلسة المحفوظة مرة واحدة؛ أي استدعاء لاحق يعيد نفس العملية.
  Future<void> init() => _initFuture ??= _load();

  Future<void> _load() async {
    await _store.load();
    _syncFromStore();
  }

  /// يرمي [AuthException] عند الفشل كما يفعل [ErpAuthService.login] نفسه.
  Future<void> login({required String email, required String password}) async {
    sessionExpired.value = false;
    try {
      await _auth.login(email: email, password: password);
    } finally {
      _syncFromStore();
    }
  }

  /// يخرج من الخادم إن أمكن، ويحذف الجلسة دائمًا (داخل ErpAuthService).
  Future<void> logout() async {
    if (!isAuthenticated.value) return;
    await _auth.logout();
    sessionExpired.value = false;
    _syncFromStore();
  }

  /// يستدعيه ErpApiClient بعد أن يحذف الجلسة المنتهية. مرة واحدة فقط: الطلبات
  /// المرفوضة معًا لا تكرر الخروج ولا التنبيه.
  void handleSessionExpired() {
    if (!isAuthenticated.value) return;
    // التنبيه أولًا، فتظهر شاشة الدخول ومعها رسالة انتهاء الجلسة من أول إطار
    sessionExpired.value = true;
    _syncFromStore();
  }

  void _syncFromStore() {
    isAuthenticated.value = _store.hasSession;
    fullName.value = _store.fullName;
  }
}
