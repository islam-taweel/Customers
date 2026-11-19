# بنية المشروع قبل إعادة الهيكلة إلى GetX

يوثّق هذا الملف حالة المشروع **كما هي الآن**، قبل أي نقل إلى بنية GetX، اعتمادًا على فحص الكود الفعلي. أرقام الأسطر تشير إلى الكود وقت الفحص، وقد تتغير قليلًا مع التعديلات.

باختصار: التطبيق يعمل بنظامين لإدارة الحالة معًا، Provider مع ChangeNotifier في 27 متحكمًا وGetX في 12 متحكمًا (في 10 ملفات). يستخدم `MaterialApp` عاديًا، والتنقل كله `Navigator.push`. نقطتا القوة الأساسيتان: كل طلبات الـ API تمر عبر طبقة `lib/data/api`، ومعالجة انتهاء الجلسة مركزية.

---

## 1. هيكل المجلدات الحالي

```
lib/
├── main.dart                 نقطة البدء: إنشاء الخدمات و MultiProvider و MaterialApp
├── core/
│   ├── constants/            النصوص لكل قسم (AppStrings و *Strings) وثوابت التطبيق
│   ├── localization/         LanguageController و rebuild_all
│   ├── services/             SyncService و InvoicePdfService و WhatsAppLauncher
│   ├── theme/                app_colors و app_theme و ThemeController
│   ├── utils/                error_messages و formatters و palestine_time و phone_utils و validators
│   └── widgets/              AppDrawer و LoadingView و ErrorView و EmptyView و StateMessage
├── data/
│   ├── api/                  ErpApiClient و ErpAuthService و ErpConfig و SessionStore
│   ├── database/             DatabaseHelper (sqflite)
│   ├── dev/                  fake_customers (بيانات تطوير)
│   ├── models/               نماذج البيانات (28 ملفًا)
│   └── repositories/         24 ملفًا: مستودعات ERPNext والتخزين المحلي
└── features/                 قسم لكل ميزة، غالبًا: controllers/ و screens/ و widgets/
    ├── auth/                 الدخول و AuthGate
    ├── customers/            العملاء وتفاصيلهم وفواتيرهم ومسوداتهم
    ├── employee_services/    خدمات الموظف (HR)
    ├── home/                 MainShell (الشريط السفلي) والرئيسية
    ├── inventory/            الجرد بالباركود
    ├── order/                إنشاء طلبية
    ├── orders_section/       الطلبات والتسليم والفواتير
    ├── purchases/            المشتريات
    ├── sales_returns/        مردود المبيعات
    ├── settings/             الإعدادات والمزامنة
    ├── statement/            كشف حساب العملاء
    ├── van_sales/            مبيعات الفان
    ├── visits/               مواعيد الزيارات
    └── warehouses/           المستودعات والنقل بينها
```

## 2. الهيكلية الحالية للمشروع

التطبيق مقسّم إلى ثلاث طبقات:

| الطبقة | المكان | الدور |
| --- | --- | --- |
| الواجهة | `lib/features/*/screens` و `widgets` | الشاشات والعناصر |
| المتحكمات | `lib/features/*/controllers` | حالة الشاشة ومنطقها (ChangeNotifier أو GetxController) |
| البيانات | `lib/data` | Repositories فوق `ErpApiClient` والتخزين المحلي |

**تسلسل بدء التطبيق** (`main()` في `lib/main.dart`):

1. إبقاء شاشة البداية: `FlutterNativeSplash.preserve` في `main.dart:62`.
2. تحميل اللغة والثيم: `LanguageController.load()` و `ThemeController.load()`.
3. الخادم والتوقيت: `ErpConfig.loadSite()` في `main.dart:70`، ثم `PalestineTime.init()` في `main.dart:73`.
4. الجلسة: `session.load()` في `main.dart:80`، ثم ربط `erpApi.onSessionExpired = authController.handleSessionExpired` في `main.dart:85`.
5. إنشاء كل الـ repositories والـ factories يدويًا (الأسطر ~76–210 تقريبًا).
6. تحميل أول صفحة عملاء: `customersController.loadFirstPage()` مع مهلة في `main.dart:213`.
7. مستمع الدخول `onAuthChanged` (`main.dart:222-242`): يشغّل المزامنة عند الدخول، ويغلق كل الشاشات عند الخروج. بعده `syncService.init()` في `main.dart:245`.
8. `runApp(DebtsApp(...))` في `main.dart:247`، و `DebtsApp` يأخذ نحو 20 معاملًا في المُنشئ.

**MaterialApp:** التطبيق يستخدم `MaterialApp` داخل `Consumer2<LanguageController, ThemeController>` في `main.dart:380`، ولا يوجد `GetMaterialApp` في المشروع.

**الشاشة الأولى:** `home: const AuthGate()` في `main.dart:400`. تختار `auth_gate.dart:15-23` بـ `AnimatedSwitcher` حسب `isAuthenticated`:

- مسجّل الدخول: `MainShell`، وهو `IndexedStack` فيه لوحة التحكم والرئيسية والإعدادات (`main_shell.dart:53`).
- غير مسجّل: `LoginScreen`.

## 3. إدارة الحالة

يعمل في المشروع نظامان في الوقت نفسه:

| النمط | العدد | العرض في الواجهة | أمثلة |
| --- | --- | --- | --- |
| Provider + ChangeNotifier | 27 فئة | `context.watch` و `context.select` | `AuthController` (`auth_controller.dart:8`)، `CustomersController` (`customers_controller.dart:53`)، `LeavesController` (`leaves_controller.dart:35`)، `SyncService` (`sync_service.dart:30`)، `VisitActions` (`visits_controller.dart:35`) |
| GetxController | 12 فئة في 10 ملفات | `Obx` (32 موضعًا) مع قيم `.obs` و `Rxn` | القائمة الكاملة في الجدول التالي |

**فئات `GetxController` الـ 12:** ملفان فيهما فئتان لكل منهما، `team_controller.dart` و `payslips_controller.dart`، لذلك عدد الملفات 10.

| # | الفئة | المسار |
| --- | --- | --- |
| 1 | `AdvancesController` | `lib/features/employee_services/controllers/advances_controller.dart:13` |
| 2 | `ExpensesController` | `lib/features/employee_services/controllers/expenses_controller.dart:26` |
| 3 | `PayslipsController` | `lib/features/employee_services/controllers/payslips_controller.dart:9` |
| 4 | `PayslipDetailController` | `lib/features/employee_services/controllers/payslips_controller.dart:39` |
| 5 | `HrAccessController` | `lib/features/employee_services/controllers/team_controller.dart:10` |
| 6 | `TeamController` | `lib/features/employee_services/controllers/team_controller.dart:41` |
| 7 | `NewSaleController` | `lib/features/van_sales/controllers/new_sale_controller.dart:19` |
| 8 | `VanReturnController` | `lib/features/van_sales/controllers/van_return_controller.dart:15` |
| 9 | `EndOfDayController` | `lib/features/van_sales/controllers/end_of_day_controller.dart:17` |
| 10 | `ReplenishmentController` | `lib/features/van_sales/controllers/replenishment_controller.dart:17` |
| 11 | `CustomerCreditController` | `lib/features/van_sales/controllers/customer_credit_controller.dart:11` |
| 12 | `VanStockController` | `lib/features/van_sales/controllers/van_stock_controller.dart:11` |

- **غير مستخدم:** `GetBuilder` و `GetX<>` و `StateMixin`. الظهور الوحيد لكلمة StateMixin هو `SingleTickerProviderStateMixin` من Flutter في `payments_tabs.dart:23`.
- **حالة محلية:** `setState` و `FutureBuilder` في عدد من الشاشات (القسم 8).
- **فئات أساس محلية مكررة:** `_LoadingController` نسختان، في `sales_returns_controller.dart:37` و `warehouses_controller.dart:37`.

## 4. نظام التنقل

- **الطريقة:** `Navigator.of(context).push(MaterialPageRoute(...))` فقط، في أكثر من 46 موضعًا.
- **ما ليس موجودًا:** لا يوجد `Get.to`، ولا `pushNamed`، ولا `routes:`، ولا `onGenerateRoute`، ولا `GetPage`.
- **«تعريف المسار»:** كل شاشة تعرّف `static Route<void> route(...)` خاصًا بها (في 39 ملفًا). لا يوجد ملف مسارات مركزي.
- **إغلاق الشاشات عند الخروج:** عبر `navigatorKey` عام يُستخدم لـ `popUntil` في `main.dart:222` و `main.dart:236`.
- **تبويبات الشريط السفلي:** تُبدَّل من القائمة الجانبية عبر `context.findAncestorStateOfType<_MainShellState>()` في `main_shell.dart:21` و `app_drawer.dart:38`.
- **القائمة الجانبية:** فيها نحو 12 دالة `_openX` متطابقة الشكل (إغلاق القائمة ثم push) في `app_drawer.dart:36-101`.

## 5. إدارة الاعتماديات (Dependency Injection)

**الأساس هو Provider.** الكائنات تُنشأ يدويًا في `main()` وتُمرَّر عبر `MultiProvider` في `main.dart:328-378`، وفيه نحو 23 مزوّدًا:

- **مزوّدات `.value` للـ repositories والخدمات:** مثل `ErpEmployeeRepository` و `ErpVanSalesRepository` و `ErpWarehouseRepository` و `ErpStatementRepository` و `ErpLedgerRepository` و `InvoiceRepository`.
- **تسع فئات Factory** تنشئ المتحكمات عند فتح الشاشة:

  | الملف | السطر |
  | --- | --- |
  | `customer_details_controller.dart` | 615 |
  | `inventory_controller.dart` | 12 |
  | `order_controller.dart` | 24 |
  | `orders_controller.dart` | 30 |
  | `sales_invoices_controller.dart` | 15 |
  | `purchases_controller.dart` | 17 |
  | `sales_returns_controller.dart` | 19 |
  | `visits_controller.dart` | 20 |
  | `warehouses_controller.dart` | 19 |

- **متحكمات ChangeNotifier داخل `build()`:** تُنشأ عبر `ChangeNotifierProvider(create: …)` داخل `build()` لشاشات StatelessWidget. `create` يُنفَّذ مرة واحدة لكل عنصر، لكنه يربط المتحكم بالـ widget. المواضع:
  - `checkin_screen.dart:28`
  - `leaves_screen.dart:26`
  - `attendance_correction_screen.dart:25`
  - `inventory_screen.dart:19`
  - `purchases_screen.dart:27`
  - `orders_screen.dart:30-35`
  - `sales_returns_screen.dart:22`

**GetX:** يُستخدم `Get.put` و `Get.delete` فقط.

- **ما ليس موجودًا:** لا `Get.find`، ولا `Get.lazyPut`، ولا Bindings.
- **المواضع:** 12 موضعًا في `employee_services` و `van_sales`، كلها `Get.put` في `initState` و `Get.delete` في `dispose`.
- **النمط:** `Get.put(XController(context.read<Repo>()))`، أي أن متحكم GetX يأخذ تبعيته من Provider. مثال: `advances_screen.dart:36` و `new_sale_screen.dart:42`.
- **`tag`:** مستخدم في موضع واحد فقط، `payslip_detail_screen.dart:45`.

## 6. المصادقة وإدارة الجلسة

| الموضوع | الآلية | الموضع |
| --- | --- | --- |
| حفظ `sid` | `SessionStore` عبر `FlutterSecureStorage` (Keychain/Keystore) مع نسخة في الذاكرة | `session_store.dart:24` (load)، `:36` (save)، `:53` (clear) |
| حفظ عنوان الخادم | حقول `static` قابلة للتغيير في `ErpConfig` (`_server` و `_site`)، محفوظة في `SharedPreferences` بالمفتاحين `erp_server_url_v2` و `erp_site_name_v2`. اسم الموقع يُرسل في كل طلب كترويسة `X-Frappe-Site-Name` | `erp_config.dart:25-26`، `:45` (loadSite)، `:89` (setTarget) |
| Login | `login_screen.dart:48` يستدعي `ErpConfig.setTarget` ثم `auth.login`. `AuthController.login` يمرّر إلى `ErpAuthService.login`، الذي يرسل `POST /api/method/login` ويستخرج `sid` من `set-cookie` ويحفظه. بعدها يعرض `AuthGate` شاشة `MainShell` | `erp_auth_service.dart:49` |
| Logout | `AuthController.logout` يستدعي `ErpAuthService.logout`، الذي يحاول `/api/method/logout` ثم يحذف الجلسة دائمًا في `finally`. بعدها يغلق `onAuthChanged` كل الشاشات بـ `popUntil` | `erp_auth_service.dart:89` |

**آلية انتهاء الجلسة (مركزية):**

1. أي رد 401 أو 403 في `_execute` (`erp_api_client.dart:384`) يذهب إلى `_denied` (`erp_api_client.dart:407`).
2. `_denied` يسأل الخادم عن المستخدم الحالي `frappe.auth.get_logged_user` عبر `_isSessionExpired` (`erp_api_client.dart:422`). الطلبات المرفوضة في الوقت نفسه تنتظر نفس الفحص عبر `_sessionCheck`.
3. النتيجة:
   - **Guest أو فشل الفحص:** حذف الجلسة، واستدعاء `onSessionExpired`، ثم رمي خطأ `sessionExpired`. `AuthController.handleSessionExpired` يغيّر الحالة، فيعرض `AuthGate` شاشة الدخول.
   - **اسم مستخدم حقيقي:** المشكلة صلاحية لا جلسة، فيُرمى خطأ `forbidden`.

`ErpAuthService` يعالج 401 أثناء الدخول نفسه بشكل مستقل (`erp_auth_service.dart:75`)، وهذا متوقع.

## 7. طبقة API

**`ErpApiClient` (`lib/data/api/erp_api_client.dart`)** هو المدخل الوحيد لطلبات ERPNext بعد الدخول. دواله العامة:

| النوع | الدوال |
| --- | --- |
| القراءة | `getList` و `getAll` (كل الصفحات، مع `filters` و `orFilters` و `orderBy` و `parent` للجداول الفرعية)، و `getDoc` |
| الكتابة | `postDoc` و `putDoc` و `deleteDoc` |
| استدعاء دوال الخادم | `getMethod` و `postMethod` |
| الملفات | `downloadPdf` و `downloadFile` و `uploadFile` (multipart) |
| الاتصال | `ping` |

**آلية الطلب:**

- **مسار التنفيذ:** كل طلب يمر عبر `_send` ثم `_execute`.
- **الترويسات:** `_execute` يضيف كوكي الجلسة `sid` وترويسة `X-Frappe-Site-Name`.
- **المهلة:** `ErpConfig.requestTimeout`.

**الأخطاء:** تتحول إلى `ErpApiException` بنوع من `ErpErrorType`:

| النوع | متى |
| --- | --- |
| `network` | انتهاء المهلة، أو `SocketException`، أو `http.ClientException` |
| `sessionExpired` و `forbidden` | رد 401 أو 403 (الآلية في القسم 6) |
| `notFound` | رد 404 |
| `server` | أخطاء الخادم، مع نص الخطأ في `detail`، مستخرجًا من `_server_messages` أو `exception` عبر `_friendlyDetail` |
| `badResponse` | رد غير متوقع |

**الرسائل للمستخدم:** `describeError` في `lib/core/utils/error_messages.dart` يحوّل نوع الخطأ إلى رسالة عربية. في وضع debug يضيف رقم الحالة ونص ERPNext.

**هل كل الطلبات تمر من هنا؟** نعم:

- الدخول والخروج فقط في `erp_auth_service.dart` بعميل `http` خاص، وهذا مقصود.
- البحث عن `package:http` و `http.Client()` و `http.get/post` و `HttpClient(` خارج `lib/data/api/` لم يجد أي طلب HTTP مباشر في Controller أو Screen.
- `ErpApiClient` يظهر خارج طبقة البيانات في موضعين فقط: `main.dart` للإنشاء، و `sync_service.dart` لاستدعاء `ping()` (`sync_service.dart:157` و `:231`).

## 8. الشاشات والـ Controllers

**النمط الغالب:** كل شاشة لها متحكم خاص بها، يُنشأ عند فتحها:

- إما `ChangeNotifierProvider` مع Factory أو مُنشئ مباشر.
- أو `Get.put` في الأقسام الجديدة (`employee_services` و `van_sales`).

لا توجد شاشة تستدعي الـ API مباشرة.

| القسم | الشاشات | المتحكمات | النمط |
| --- | --- | --- | --- |
| auth | `auth_gate`، `login_screen` | AuthController | Provider |
| customers | `customer_screen`، `customer_details_screen`، `customer_operations_screen`، `edit_customer_screen`، `customer_invoices_screen`، `draft_invoice_screen`، `edit_draft_screen`، `invoice_details_screen`، `invoice_pdf_screen`، `gl_entries_screen` | CustomersController، CustomerDetailsController، CustomerInvoicesController، DraftInvoiceController، InvoiceDetailsController | Provider |
| order | `new_order_screen` | OrderController | Provider |
| orders_section | `orders_screen`، `order_details_screen` | OrdersController، SalesInvoicesController | Provider |
| purchases | `purchases_screen`، `purchase_details_screen`، `new_purchase_order_screen`، `edit_purchase_items_screen` | PurchasesController | Provider |
| inventory | `inventory_screen`، `barcode_scanner_screen` | InventoryController | Provider |
| sales_returns | `sales_returns_screen`، `return_invoices_screen`، `return_items_screen`، `pending_returns_screen` | SalesReturnsController، ReturnInvoicesController، ReturnItemsController، PendingReturnsController | Provider |
| warehouses | `warehouses_screen`، `warehouse_stock_screen`، `transfer_screen`، `pending_transfers_screen` | WarehousesController، WarehouseStockController، TransferController، PendingTransfersController | Provider |
| statement | `customer_statement_list_screen`، `customer_statement_screen`، `voucher_details_screen` | — | Repository مباشرة |
| home | `main_shell`، `home_screen` | TodayVisitsController | Provider |
| visits | `visits_screen`، `visit_form_screen` | VisitsController، VisitFormController | Provider |
| settings | `settings_screen` | SyncService، ThemeController | Provider |
| employee_services | `checkin_screen`، `attendance_correction_screen`، `leaves_screen` | CheckinController، CorrectionController، LeavesController | Provider |
| employee_services | `employee_services_screen`، `advances_screen`، `expenses_screen`، `payslips_screen`، `payslip_detail_screen`، `team_screen` | HrAccessController، AdvancesController، ExpensesController، PayslipsController، PayslipDetailController، TeamController | GetX |
| employee_services | `my_account_screen`، `attendance_log_screen`، `overtime_screen` | — | Repository مباشرة |
| van_sales | `van_stock_screen`، `new_sale_screen`، `van_return_screen`، `customer_credit_screen`، `end_of_day_screen`، `replenishment_screen` | VanStockController، NewSaleController، VanReturnController، CustomerCreditController، EndOfDayController، ReplenishmentController | GetX |
| van_sales | `van_sales_screen` | — | تنقل فقط |

**شاشات تتعامل مع Repository مباشرة** عبر `FutureBuilder` بلا متحكم:

| الشاشة | الـ Repository |
| --- | --- |
| `employee_services/screens/my_account_screen.dart` | `ErpEmployeeRepository` |
| `employee_services/screens/attendance_log_screen.dart` | `ErpEmployeeRepository` |
| `employee_services/screens/overtime_screen.dart` | `ErpEmployeeRepository` |
| `customers/screens/gl_entries_screen.dart` | `ErpLedgerRepository` |
| `statement/screens/customer_statement_list_screen.dart` | `ErpStatementRepository` |
| `statement/screens/customer_statement_screen.dart` | `ErpStatementRepository` |
| `statement/screens/voucher_details_screen.dart` (السطر 53) | `ErpStatementRepository` |
| `orders_section/screens/order_details_screen.dart` | `ErpLedgerRepository`، إلى جانب `OrdersController` |

## 9. المشكلات المعمارية الحالية

**1. نظاما إدارة حالة متداخلان**

- **الموضع:** `advances_screen.dart:36`، `Get.put(AdvancesController(context.read<ErpEmployeeRepository>()))`.
- **المشكلة:** 27 متحكم ChangeNotifier مقابل 12 متحكم GetxController، ومتحكمات GetX تأخذ تبعياتها من Provider.
- **السبب:** نمطان مختلفان للاشتراك والتخلص والاختبار. الحاجة إلى `BuildContext` لإنشاء متحكم GetX تُلغي فائدة GetX في حقن التبعيات.

**2. حقن تبعيات يدوي ومركزي**

- **الموضع:** `main.dart`، الأسطر ~76–210 و 247–378.
- **المشكلة:** `main.dart` فيه 432 سطرًا، و `DebtsApp` يأخذ نحو 20 معاملًا، وتسع فئات Factory موجودة فقط لتمرير التبعيات.
- **السبب:** أي ميزة جديدة تتطلب تعديل `main.dart` في أربعة أماكن: الإنشاء، والمعامل، والحقل، والمزوّد. كل الكائنات تُنشأ عند الإقلاع حتى إن لم تُستخدم.

**3. `Get.put` بلا `tag` مع `Get.delete` في `dispose`**

- **الموضع:** 11 شاشة، مثل `van_stock_screen.dart:37` و `:43`.
- **المشكلة:** المتحكم مسجّل في GetX بنوعه فقط.
- **السبب:** إن فُتحت نفس الشاشة مرتين في المكدس، يأخذ `Get.put` الثاني مكان الأول، ثم يحذف `dispose` الشاشة الثانية متحكمًا ما زالت الأولى تستخدمه.

**4. تكرار منطق مشترك**

- **المواضع:**
  - **`_withDetail`** (رسالة الخطأ مع نص ERPNext)، أربع نسخ: `expenses_controller.dart:12` و `sales_returns_controller.dart:11` و `visits_controller.dart:12` و `warehouses_controller.dart:11`، ونفس المنطق مكتوب داخل دوال متحكمات أخرى.
  - **`_LoadingController`** نسختان: `sales_returns_controller.dart:37` و `warehouses_controller.dart:37`.
  - **منتقي العملاء** نسختان: `visit_form_screen.dart:346` و `customer_picker_sheet.dart:12`.
- **السبب:** إصلاح خطأ في نسخة لا يصل إلى الأخرى، فيتصرف نفس السلوك بشكل مختلف بين الشاشات.

**5. إعدادات عامة قابلة للتغيير، وقيم عمل مكتوبة في الكود**

- **المواضع:** `erp_config.dart:25-26` (`_server` و `_site`)، و `:146` (الشركة)، و `:165` (مستودع الفان `Van - Ahmad - RTC`)، و `:171` (المستودع الرئيسي).
- **المشكلة:** حالة `static` قابلة للتغيير تقرأها كل الطبقات مباشرة، بما فيها `ErpApiClient` و `ErpAuthService`.
- **السبب:** حالة عامة يصعب اختبارها أو تبديلها. ومستودع فان مندوب واحد مكتوب في الكود يعني أن التطبيق لا يعمل لمندوب ثانٍ دون إصدار جديد.

**ملاحظتان إضافيتان أقل حدة:**

- `erp_employee_repository.dart` فيه 799 سطرًا و 33 دالة غير متزامنة، ويخدم كل خدمات الموظف معًا.
- نحو ثماني شاشات تبقي منطق التحميل داخل `FutureBuilder` (القسم 8).

## 10. المكونات والخدمات المشتركة الموجودة

| الفئة | المكوّن | المكان |
| --- | --- | --- |
| طبقة الـ API | `ErpApiClient` بدواله، و `ErpApiException`، ومعالجة 401/403 المركزية | `lib/data/api/erp_api_client.dart` |
| الجلسة والإعدادات | `SessionStore` و `ErpAuthService` و `ErpConfig` | `lib/data/api/` |
| أدوات | `describeError`، `formatAmount` و `displayCurrency` و `parseAmount` و `normalizeDigits`، `PalestineTime`، `phone_utils`، `validators` | `lib/core/utils/` |
| Widgets عامة | `LoadingView` و `ErrorView` و `EmptyView` و `StateMessage` و `AppDrawer` | `lib/core/widgets/` |
| Widgets قابلة للتعميم | `ConfirmDialog` و `OfflineBanner` | `lib/features/customers/widgets/` |
| | `BarcodeScannerScreen` | `lib/features/inventory/screens/` |
| | `CustomerPickerSheet` و `CreditSummary` | `lib/features/van_sales/widgets/` |
| | `StockTile` | `lib/features/warehouses/widgets/` |
| | `MonthYearPicker` | `lib/features/employee_services/widgets/` |
| | `MonthCalendar` و `VisitCard` | `lib/features/visits/widgets/` |
| خدمات | `SyncService` (المزامنة التلقائية)، `InvoicePdfService`، `WhatsAppLauncher` | `lib/core/services/` |
| اللغة والثيم | `LanguageController` و `rebuildAllChildren`، `ThemeController` | `lib/core/localization/`، `lib/core/theme/` |
| النصوص | `AppStrings` و `*Strings` لكل قسم بنمط `_t(ar, en)` | `lib/core/constants/` |
| Repositories مشتركة | `ErpWarehouseRepository` (`fetchStock` و `itemCodeForBarcode`) و `ErpSalesReturnsRepository` (المرتجعات)، وكلاهما مستخدم من أكثر من قسم | `lib/data/repositories/` |
| التخزين المحلي | `DatabaseHelper` (sqflite) | `lib/data/database/` |

## 11. ملخص الهيكلية الحالية

| الجانب | الوضع الحالي |
| --- | --- |
| بدء التطبيق | `MaterialApp`، وكل الخدمات تُنشأ يدويًا في `main()`، والشاشة الأولى `AuthGate` |
| إدارة الحالة | نظامان: 27 ChangeNotifier عبر Provider، و 12 GetxController (في 10 ملفات) مع `Obx` |
| التنقل | `Navigator.push` و `static route()` في كل شاشة، بلا مسارات مركزية |
| حقن التبعيات | `MultiProvider` (نحو 23 مزوّدًا) وتسع Factories، و `Get.put` في 12 موضعًا يعتمد على Provider |
| المصادقة | `sid` في التخزين الآمن، ومعالجة مركزية لـ 401/403 وانتهاء الجلسة |
| طبقة API | كل الطلبات عبر `ErpApiClient`، ولا طلبات HTTP مباشرة في الشاشات أو المتحكمات |
| الشاشات | معظمها بمتحكم خاص بها، وثمانٍ تستدعي الـ Repository مباشرة |

**نقاط القوة** التي يُبنى عليها في إعادة الهيكلة:

- طبقة API واحدة ومعالجة جلسة مركزية.
- Repositories منفصلة عن الواجهة.
- مكونات مشتركة جاهزة.

**ما يحتاج معالجة:**

- توحيد إدارة الحالة وحقن التبعيات.
- مسارات مركزية.
- إزالة التكرار.
- نقل إعدادات العمل المكتوبة في الكود إلى مكان قابل للتهيئة.
