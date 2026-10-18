import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/app_strings.dart';
import 'core/localization/language_controller.dart';
import 'core/localization/rebuild_all.dart';
import 'core/services/whatsapp_launcher.dart';
import 'core/theme/app_theme.dart';
import 'data/api/erp_api_client.dart';
import 'data/database/database_helper.dart';
import 'data/repositories/customer_repository.dart';
import 'data/repositories/erp_customer_repository.dart';
import 'data/repositories/erp_cache_store.dart';
import 'data/repositories/erp_invoice_repository.dart';
import 'data/repositories/erp_order_repository.dart';
import 'data/repositories/invoice_repository.dart';
import 'data/repositories/operation_repository.dart';
import 'features/customers/controllers/customer_details_controller.dart';
import 'features/customers/controllers/customers_controller.dart';
import 'features/customers/screens/customer_screen.dart';
import 'features/order/controllers/order_controller.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // إبقاء الـ splash ظاهرًا إلى أن نطلب إزالته يدويًا
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // اللغة المحفوظة (العربية افتراضيًا) تُحمَّل أولًا حتى تظهر النصوص بلغتها من أول إطار
  final languageController = await LanguageController.load();

  // تجميع المكونات: DatabaseHelper ← repositories ← controllers
  final dbHelper = DatabaseHelper.instance;
  final customerRepository = CustomerRepository(dbHelper);
  final erpApi = ErpApiClient();
  final customersController = CustomersController(
    customerRepository,
    // أسماء العملاء وهواتفهم من ERPNext (الديون تبقى محلية)
    ErpCustomerRepository(erpApi),
  );
  final invoiceRepository = InvoiceRepository(dbHelper);
  final detailsFactory = CustomerDetailsControllerFactory(
    OperationRepository(dbHelper),
    customerRepository,
    const WhatsAppLauncher(),
    // فواتير ERPNext فقط، مع نسخة محلية في قاعدة البيانات للعمل دون إنترنت
    ErpInvoiceRepository(erpApi, ErpCacheStore(dbHelper)),
    // فواتير الطلبيات المحفوظة محليًا تظهر مع فواتير ERPNext
    invoiceRepository,
  );

  // طلبيات العملاء: العملاء والأصناف والأسعار والمخزون وإنشاء الطلبية من ERPNext
  final orderFactory = OrderControllerFactory(
    ErpOrderRepository(erpApi),
    ErpCustomerRepository(erpApi),
    invoiceRepository,
  );

  // جلب أول 20 عميل (وإجمالي الديون) قبل عرض أي شيء.
  // الـ timeout حماية فقط: إن تأخر التحميل تظهر الشاشة بمؤشر التحميل
  // بدل بقاء الـ splash إلى الأبد.
  await customersController.loadFirstPage().timeout(
    AppConstants.splashTimeout,
    onTimeout: () {},
  );

  // مزامنة العملاء من ERPNext في الخلفية: تظهر القائمة المحلية فورًا
  // ثم تتحدث عند وصول البيانات (ومؤشر التحميل إن لم يكن هناك شيء محفوظ بعد)
  unawaited(customersController.syncFromApi());

  runApp(
    DebtsApp(
      customersController: customersController,
      detailsFactory: detailsFactory,
      languageController: languageController,
      invoiceRepository: invoiceRepository,
      orderFactory: orderFactory,
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

  const DebtsApp({
    super.key,
    required this.customersController,
    required this.detailsFactory,
    required this.languageController,
    required this.invoiceRepository,
    required this.orderFactory,
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
        // اللغة الحالية (عربي/إنجليزي)
        ChangeNotifierProvider<LanguageController>.value(
          value: languageController,
        ),
      ],
      child: Consumer<LanguageController>(
        builder: (context, language, _) => MaterialApp(
          title: AppStrings.appName,
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
          home: const CustomersScreen(),
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
