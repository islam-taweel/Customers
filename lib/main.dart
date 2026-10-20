import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/app_strings.dart';
import 'core/localization/language_controller.dart';
import 'core/localization/rebuild_all.dart';
import 'core/services/sync_service.dart';
import 'core/services/whatsapp_launcher.dart';
import 'core/theme/app_theme.dart';
import 'data/api/erp_api_client.dart';
import 'data/api/erp_auth_service.dart';
import 'data/api/erp_config.dart';
import 'data/api/session_store.dart';
import 'data/database/database_helper.dart';
import 'data/repositories/catalog_store.dart';
import 'data/repositories/customer_repository.dart';
import 'data/repositories/erp_customer_repository.dart';
import 'data/repositories/erp_cache_store.dart';
import 'data/repositories/erp_invoice_repository.dart';
import 'data/repositories/erp_order_repository.dart';
import 'data/repositories/invoice_repository.dart';
import 'data/repositories/operation_repository.dart';
import 'data/repositories/pending_order_repository.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/screens/auth_gate.dart';
import 'features/customers/controllers/customer_details_controller.dart';
import 'features/customers/controllers/customers_controller.dart';
import 'features/order/controllers/order_controller.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // إبقاء الـ splash ظاهرًا إلى أن نطلب إزالته يدويًا
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // اللغة المحفوظة (العربية افتراضيًا) تُحمَّل أولًا حتى تظهر النصوص بلغتها من أول إطار
  final languageController = await LanguageController.load();

  // اسم موقع المستخدم المحفوظ (ترويسة Host): قبل أي طلب إلى الخادم
  await ErpConfig.loadSite();

  // تجميع المكونات: DatabaseHelper ← repositories ← controllers
  final dbHelper = DatabaseHelper.instance;
  final customerRepository = CustomerRepository(dbHelper);
  // جلسة الدخول (كوكي sid) محفوظة بأمان على الجهاز، وتُحمَّل قبل أول طلب
  final session = SessionStore();
  await session.load();
  final authController = AuthController(ErpAuthService(session), session);
  final erpApi = ErpApiClient(session: session);
  // رفض الخادم الجلسة (انتهت): نعود إلى شاشة الدخول
  erpApi.onSessionExpired = authController.handleSessionExpired;
  // العملاء المحفوظون محليًا يُستخدمون عند انقطاع الاتصال (الطلبيات)
  final erpCustomers = ErpCustomerRepository(erpApi, customerRepository);
  final customersController = CustomersController(
    customerRepository,
    // أسماء العملاء وهواتفهم من ERPNext (الديون تبقى محلية)
    erpCustomers,
  );
  final invoiceRepository = InvoiceRepository(dbHelper);
  final cacheStore = ErpCacheStore(dbHelper);
  final erpInvoices = ErpInvoiceRepository(erpApi, cacheStore);
  // كتالوج محلي (أصناف/أسعار/مخزون) وطلبيات تنتظر الرفع
  final erpOrders = ErpOrderRepository(erpApi, CatalogStore(dbHelper));
  final pendingRepository = PendingOrderRepository(dbHelper);
  final detailsFactory = CustomerDetailsControllerFactory(
    OperationRepository(dbHelper),
    customerRepository,
    const WhatsAppLauncher(),
    // فواتير ERPNext فقط، مع نسخة محلية في قاعدة البيانات للعمل دون إنترنت
    erpInvoices,
    // فواتير الطلبيات المحفوظة محليًا تظهر مع فواتير ERPNext
    invoiceRepository,
  );

  // طلبيات العملاء: العملاء والأصناف والأسعار والمخزون وإنشاء الطلبية من ERPNext
  // ينسّق المزامنة اليدوية (الإعدادات) والرفع التلقائي للطلبيات عند عودة الاتصال
  final syncService = SyncService(
    api: erpApi,
    customersController: customersController,
    customerRepository: customerRepository,
    erpCustomers: erpCustomers,
    erpOrders: erpOrders,
    erpInvoices: erpInvoices,
    invoiceRepository: invoiceRepository,
    pendingRepository: pendingRepository,
    cache: cacheStore,
  );

  final orderFactory = OrderControllerFactory(
    erpOrders,
    erpCustomers,
    invoiceRepository,
    pendingRepository,
    syncService,
  );

  // جلب أول 20 عميل (وإجمالي الديون) قبل عرض أي شيء.
  // الـ timeout حماية فقط: إن تأخر التحميل تظهر الشاشة بمؤشر التحميل
  // بدل بقاء الـ splash إلى الأبد.
  await customersController.loadFirstPage().timeout(
    AppConstants.splashTimeout,
    onTimeout: () {},
  );

  // عند كل دخول (ومن بدء التطبيق إن كانت الجلسة محفوظة): مزامنة العملاء من ERPNext
  // في الخلفية، فتظهر القائمة المحلية فورًا ثم تتحدث، ورفع الطلبيات المنتظرة.
  // عند الخروج أو انتهاء الجلسة: نغلق كل الشاشات المفتوحة فوق البوابة.
  final navigatorKey = GlobalKey<NavigatorState>();
  var wasAuthenticated = false;
  void onAuthChanged() {
    final isAuthenticated = authController.isAuthenticated;
    if (isAuthenticated && !wasAuthenticated) {
      unawaited(customersController.syncFromApi());
      unawaited(syncService.pushPending());
    }
    if (!isAuthenticated) {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
    wasAuthenticated = isAuthenticated;
  }

  authController.addListener(onAuthChanged);
  onAuthChanged();

  // آخر أوقات المزامنة + مؤقّت الرفع التلقائي للطلبيات المعلّقة
  unawaited(syncService.init());

  runApp(
    DebtsApp(
      customersController: customersController,
      detailsFactory: detailsFactory,
      languageController: languageController,
      invoiceRepository: invoiceRepository,
      orderFactory: orderFactory,
      syncService: syncService,
      authController: authController,
      navigatorKey: navigatorKey,
    ),
  );

  // إخفاء الـ splash بعد رسم أول إطار، فتظهر شاشة العملاء مباشرة ببياناتها
  binding.addPostFrameCallback((_) => FlutterNativeSplash.remove());
}

class DebtsApp extends StatelessWidget {
  final CustomersController customersController;
  final CustomerDetailsControllerFactory detailsFactory;
  final LanguageController languageController;
  final InvoiceRepository invoiceRepository;
  final OrderControllerFactory orderFactory;
  final SyncService syncService;
  final AuthController authController;
  final GlobalKey<NavigatorState> navigatorKey;

  const DebtsApp({
    super.key,
    required this.customersController,
    required this.detailsFactory,
    required this.languageController,
    required this.invoiceRepository,
    required this.orderFactory,
    required this.syncService,
    required this.authController,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    // فوق MaterialApp ليراها كل الشاشات
    return MultiProvider(
      providers: [
        // يعيش طوال عمر التطبيق
        ChangeNotifierProvider<CustomersController>.value(
          value: customersController,
        ),
        // ينشئ متحكمًا جديدًا لكل عميل يُفتح
        Provider<CustomerDetailsControllerFactory>.value(value: detailsFactory),
        // مستودع الفواتير: تأخذه شاشة التفاصيل لإنشاء متحكم فواتير لكل عميل
        Provider<InvoiceRepository>.value(value: invoiceRepository),
        // ينشئ متحكم طلبية جديدة كلما فُتحت شاشة «طلبيات العملاء»
        Provider<OrderControllerFactory>.value(value: orderFactory),
        // المزامنة: شاشة الإعدادات تقرأ حالتها وتشغّلها
        ChangeNotifierProvider<SyncService>.value(value: syncService),
        // حالة تسجيل الدخول: البوابة وشاشة الدخول والقائمة الجانبية
        ChangeNotifierProvider<AuthController>.value(value: authController),
        // اللغة الحالية (عربي/إنجليزي)
        ChangeNotifierProvider<LanguageController>.value(
          value: languageController,
        ),
      ],
      child: Consumer<LanguageController>(
        builder: (context, language, _) => MaterialApp(
          title: AppStrings.appName,
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: language.locale,
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // الاتجاه يتبع اللغة: عربي = من اليمين لليسار، إنجليزي = العكس
          builder: (context, child) => _LanguageScope(
            language: language.language,
            child: Directionality(
              textDirection: language.direction,
              child: child!,
            ),
          ),
          home: const AuthGate(),
        ),
      ),
    );
  }
}

/// عند تغيّر اللغة نعيد بناء كل الشاشات المفتوحة،
/// لأن النصوص تُقرأ من AppStrings (وليس من InheritedWidget).
class _LanguageScope extends StatefulWidget {
  final AppLanguage language;
  final Widget child;

  const _LanguageScope({required this.language, required this.child});

  @override
  State<_LanguageScope> createState() => _LanguageScopeState();
}

class _LanguageScopeState extends State<_LanguageScope> {
  @override
  void didUpdateWidget(covariant _LanguageScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) rebuildAllChildren(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
