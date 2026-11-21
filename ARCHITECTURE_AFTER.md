# ARCHITECTURE_AFTER — الهيكلية بعد إعادة البناء (R1–R7)

> **كيف كُتب هذا الملف:** من الكود الموجود حاليًا في `lib/` (الفرع `refactor/getx-architecture`، فوق commit `ffeebd2`).
>
> **حالة شجرة العمل:** تحويل 7 شاشات إلى `StateMixin` (البند 9) موجود في الكود، لكنه **غير محفوظ في commit** عند كتابة الملف.
>
> **للمقارنة:** [ARCHITECTURE_BEFORE.md](ARCHITECTURE_BEFORE.md).

---

## 1. هيكل المجلدات داخل `lib`

```
lib/
├── main.dart                         إنشاء الكائنات مرة واحدة، InitialBinding، MultiProvider، GetMaterialApp
├── app/
│   ├── bindings/        auth_binding.dart، initial_binding.dart
│   ├── middleware/      auth_middleware.dart (AuthMiddleware، GuestMiddleware)، manager_middleware.dart
│   ├── routes/          app_routes.dart (Routes)، app_pages.dart (AppPages.pages)
│   ├── services/        session_service.dart (SessionService)
│   └── translations/    app_translations.dart، ar.dart، en.dart، language_scope.dart
├── core/
│   ├── constants/       app_strings.dart، ess_strings.dart، statement_strings.dart، van_strings.dart …
│   ├── localization/    language_controller.dart، rebuild_all.dart
│   ├── services/        sync_service.dart، whatsapp_launcher.dart، invoice_pdf_service.dart
│   ├── theme/ utils/    (palestine_time.dart، formatters.dart، error_messages.dart …)
│   └── widgets/         loading_view.dart، error_view.dart، empty_view.dart، app_drawer.dart …
├── data/
│   ├── api/             erp_api_client.dart، erp_auth_service.dart، session_store.dart، erp_config.dart
│   ├── database/ dev/ models/ repositories/     (مشتركة، وما تستخدمه features غير المرحّلة)
├── modules/                          ← البنية الجديدة (Feature-First)
│   ├── statement/       bindings controllers models repository views widgets
│   ├── invoices/        bindings controllers models repository views widgets
│   ├── collections/     bindings controllers models repository widgets
│   └── hr/
│       ├── shared/      hr_errors.dart، hr_repositories.dart، hr_approver_access.dart،
│       │                models/ (employee_models)، repository/ (hr_employee_identity)، widgets/ (month_year_picker)
│       ├── home/        bindings controllers views employee_service.dart
│       ├── profile/ punch/                       bindings controllers repository views
│       ├── attendance/ leaves/                   bindings controllers models repository views widgets
│       ├── overtime/                             bindings controllers repository views
│       └── advances/ expenses/ payslips/ team/   bindings controllers models repository views
└── features/                         ← لم تُرحَّل إلى modules (انظر §13)
    ├── auth/            controllers (login_controller، auth_controller) screens (login_screen، auth_gate)
    ├── customers/ order/ orders_section/ purchases/ sales_returns/
    ├── van_sales/ visits/ warehouses/ inventory/
    └── home/ settings/
```

**لا يوجد في الكود** `core/network` (ErpApiClient في `data/api`)، ولا `app/theme` (الثيم في `core/theme`)، ولا `modules/customers` أو `modules/orders` أو `modules/auth`.

---

## 2. Feature-First Architecture

- **في `lib/modules/<feature>/`** تحتوي كل ميزة طبقاتها كلها، وتُنشأ فقط المجلدات التي لها ملفات:

  | المجلد | المحتوى |
  |---|---|
  | `bindings/` | تسجيل المتحكمات (`Get.lazyPut`) |
  | `controllers/` | `GetxController` |
  | `views/` | الشاشات |
  | `widgets/` | أجزاء العرض |
  | `repository/` | الوصول للبيانات |
  | `models/` | النماذج الخاصة بالميزة |

- **مثال:** `modules/collections` بلا `views/`، لأن عرضها نافذة سفلية وتبويبات داخل شاشات أخرى (`widgets/payment_sheet.dart` و`widgets/payments_tabs.dart`).
- **`modules/hr/shared`:** ما تشترك فيه وحدات HR:
  - `HrEmployeeIdentity`: هوية الموظف الحالي، بلا حالة.
  - `hrErrorMessage` و`hrServerError`.
  - `HrRepositories`.
  - `HrApproverAccess`.
  - `MonthYearPicker`.
- **ما يُستخدم خارج ميزة واحدة يبقى في `data/` أو `core/`:** مثل `SalesInvoice`، `ErpCustomer`، `InvoiceRepository`، أصناف النصوص.

---

## 3. تدفق البيانات

```
 ┌──────────────┐  Obx / GetBuilder / controller.obx   ┌──────────────────┐
 │ View / Widget │ ───────────────────────────────────▶ │ Controller        │
 │ (views/،      │ ◀─────── حالة Rx / StateMixin ────── │ (GetxController)  │
 │  widgets/)    │      أوامر المستخدم (دوال المتحكم)     └────────┬─────────┘
 └──────┬───────┘                                                │ يستدعي
        │ Navigator / Get.toNamed / X.route()                     ▼
        │ حوارات وSnackBar (تحتاج context)              ┌──────────────────┐
        ▼                                                │ Repository        │  (repository/)
   شاشة أخرى                                             └────────┬─────────┘
                                                                  │ getList / getAll / getDoc /
                                                                  │ postDoc / putDoc / getMethod …
                                                                  ▼
                                                         ┌──────────────────┐
                                                         │ ErpApiClient      │  نسخة واحدة
                                                         │ (data/api)        │  main.dart:93
                                                         └────────┬─────────┘
                                                                  ▼
                                                               ERPNext
```

**التسجيل:**
- كل Repository يُنشأ مرة في `main()`، ويُسجَّل بنفس الكائن في `InitialBinding` (`Get.put(permanent)`).
- المتحكم يُنشأ من Binding المسار عبر `Get.lazyPut`، ويأخذ الـ Repository بـ `Get.find`.

---

## 4. دور كل طبقة

| الطبقة | المسموح | غير المسموح (في `modules/`) |
|---|---|---|
| **View / Widget** | العرض، `Obx` و`GetBuilder` و`controller.obx`، التنقل، الحوارات وSnackBar، حقول النص (`TextEditingController`)، منتقيات التاريخ والصور | طلبات API، الحسابات، إنشاء متحكم (`Get.put`) داخل `build()` |
| **Controller** | حالة Rx أو StateMixin أو `update()`، أوامر المستخدم، التحقق، رسائل الخطأ (`errorMessage`)، Workers | `BuildContext`، `http`، إنشاء `ErpApiClient` |
| **Repository** | بناء الطلبات وparsing الردود، النسخة المحلية حيث كانت | حالة واجهة |
| **Model** | تمثيل JSON بنفس أسماء الحقول، وحسابات نقية لا تحتاج شبكة (`CustomerStatement.fromGlRows` للرصيد الجاري، `CustomerLedger.totalDebit/difference`، `AttendanceSummary.of`) | — |
| **ErpApiClient** | الترويسات، المهلة، تحويل الأخطاء إلى `ErpApiException`، معالجة 401/403 | — |

---

## 5. GetMaterialApp وGetPage والمسارات المسماة

- **`main.dart`:** `GetMaterialApp` داخل `Consumer2<LanguageController, ThemeController>`، مع:
  - `navigatorKey`، `locale`، `translations: AppTranslations()`.
  - `fallbackLocale` و`supportedLocales`.
  - `builder` (`LanguageScope` + `Directionality`).
  - `initialRoute: Routes.gate` و`getPages: AppPages.pages`.
- **`app/routes/app_routes.dart` (`Routes`)** و**`app_pages.dart` (`AppPages.pages`)**: **15 `GetPage`**.

| المسار | الشاشة | Binding | Middleware |
|---|---|---|---|
| `/` (`gate`) | `AuthGate` | `AuthBinding` | — |
| `/login` | `LoginScreen` | `AuthBinding` | `GuestMiddleware` |
| `/home` | `MainShell` | — | `AuthMiddleware` |
| `/hr` | `EmployeeServicesScreen` | `HrHomeBinding` | `AuthMiddleware` |
| `/hr/profile` | `MyAccountScreen` | `ProfileBinding` | `AuthMiddleware` |
| `/hr/punch` | `CheckinScreen` | `PunchBinding` | `AuthMiddleware` |
| `/hr/attendance` | `AttendanceLogScreen` | `AttendanceBinding` | `AuthMiddleware` |
| `/hr/attendance/correction` | `AttendanceCorrectionScreen` | `CorrectionBinding` | `AuthMiddleware` |
| `/hr/leaves` | `LeavesScreen` | `LeavesBinding` | `AuthMiddleware` |
| `/hr/overtime` | `OvertimeScreen` | `OvertimeBinding` | `AuthMiddleware` |
| `/hr/advances` | `AdvancesScreen` | `AdvancesBinding` | `AuthMiddleware` |
| `/hr/expenses` | `ExpensesScreen` | `ExpensesBinding` | `AuthMiddleware` |
| `/hr/payslips` | `PayslipsScreen` | `PayslipsBinding` | `AuthMiddleware` |
| `/hr/payslips/detail` | `PayslipDetailScreen(name: Get.arguments)` | `PayslipDetailBinding` | `AuthMiddleware` |
| `/hr/team` | `TeamScreen` | `TeamBinding` | `AuthMiddleware`، `ManagerMiddleware` |

- **`Get.toNamed`** مستخدم فعليًا في:
  - مدخل HR: `Get.toNamed(service.routeName)` في `hr_home_view.dart`، والأسماء من `EmployeeService.routeName`.
  - قائمة الرواتب: `Get.toNamed(Routes.hrPayslipDetail, arguments: p.name)`.
- **`static route()` تعيد `GetPageRoute` مع Binding و`Transition.native`** (نفس التوقيع القديم، فبقيت نقاط الدخول القديمة تعمل):
  - `CustomerStatementListScreen.route()`، `CustomerStatementScreen.route()`، `VoucherDetailsScreen.route()`، `GlEntriesScreen.forInvoice/forOrder`.
  - `InvoiceDetailsScreen.route()`، `EmployeeServicesScreen.route()`، `OrdersScreen.route()`، `CustomerOperationsScreen.route()`.
- **بقية `features/`** تنتقل بـ `Navigator.push(X.route())` (MaterialPageRoute) كما كانت.

---

## 6. Bindings و`Get.lazyPut`

- **22 Binding لشاشات** (+ `InitialBinding`):

  | المكان | الـ Bindings |
  |---|---|
  | `app/bindings` | `AuthBinding` (`LoginController`، `fenix: true`) |
  | `statement` | `StatementCustomersBinding`، `CustomerStatementBinding`، `VoucherDetailsBinding`، `GlEntriesBinding` |
  | `invoices` | `SalesInvoicesBinding`، `InvoiceDetailsBinding` |
  | `collections` | `InvoiceCollectionsBinding`، `PaymentSheetBinding`، `CustomerCollectionsBinding` |
  | `hr` | `HrHomeBinding`، `ProfileBinding`، `PunchBinding`، `AttendanceBinding`، `CorrectionBinding`، `LeavesBinding`، `OvertimeBinding`، `AdvancesBinding`، `ExpensesBinding`، `PayslipsBinding`، `PayslipDetailBinding`، `TeamBinding` |

- **كل Binding شاشة يستخدم `Get.lazyPut`:** المتحكم لا يُنشأ عند التسجيل، بل عند أول `Get.find` في الشاشة، ويُحذف تلقائيًا عند إغلاق مساره (`GetPage` أو `GetPageRoute`).
- **وسم (tag) لكل مسار** حيث يمكن أن تُفتح الشاشة نفسها فوق بعضها:
  - `CustomerStatementBinding`، `VoucherDetailsBinding`، `GlEntriesBinding` (`nextStatementTag`).
  - `InvoiceDetailsBinding` (`nextInvoicesTag`).
  - `CustomerCollectionsBinding`، `PaymentSheetBinding` (`nextCollectionsTag`).
  - `PayslipDetailBinding` (tag = رقم الكشف).
- **`PaymentSheetBinding`** يُستدعى قبل فتح النافذة السفلية، والنافذة تحذف متحكمها في `dispose` (ليست GetPage).
- **`InitialBinding`** (`app/bindings/initial_binding.dart`):
  - يُستدعى **مرة واحدة يدويًا** في `main()` (`main.dart:266`)، ولا يُمرَّر لـ GetMaterialApp.
  - يسجّل بـ `_putOnce` (assert + `Get.put(permanent: true)`): `SessionService`، `ErpApiClient`، `ErpAuthService`، `ErpStatementRepository`، `ErpLedgerRepository`، `ErpSalesInvoicesRepository`، `ErpInvoiceCollectionsRepository`، `ErpPaymentRepository`، `InvoiceRepository`، `HrEmployeeIdentity`، و9 repositories HR (Profile، Punch، Attendance، Leaves، Overtime، Advances، Expenses، Payslips، Team).
  - **ينشئ داخله `HrApproverAccess(session)`.** هذا هو الكائن الوحيد الذي يُنشأ في InitialBinding لا في `main()`.

---

## 7. SessionService وGetxService

- **`SessionService extends GetxService`** (`app/services/session_service.dart`):
  - نسخة واحدة تُنشأ في `main.dart:90`، ويُنتظر `init()` قبل التشغيل (`main.dart:92`)، وتُسجَّل دائمة في InitialBinding.
  - **الحالة:** `isAuthenticated`، `fullName`، `sessionExpired`، و`employeeId` و`employeeName` (R7).
  - **الدوال:** `init()` (التحميل مرة واحدة)، `login()`، `logout()`، `handleSessionExpired()`، `rememberEmployee()`.
- **هوية الموظف:** `ProfileController` يستدعي `rememberEmployee` بعد تحميل «حسابي». تُمسح الهوية في `_syncFromStore` عند غياب الجلسة (خروج أو انتهاء)، و`rememberEmployee` لا يحفظ شيئًا بلا جلسة.
- **`sid`** في `SessionStore` (تخزين آمن). SessionService لا يحمل كلمة المرور ولا الـ sid.
- **`ErpApiClient.onSessionExpired = sessionService.handleSessionExpired`** (`main.dart:95`).
- **`AuthGate`** يعرض الدخول أو MainShell حسب `isAuthenticated` (Obx).
- **`AuthController` (ChangeNotifier)** باقٍ كمحوّل لـ Provider فوق SessionService (`everAll` على حالته) للشاشات القديمة.
- **`HrApproverAccess extends GetxService`:** خدمة دائمة ثانية تحفظ صلاحية المعتمِد، وتُمسح بـ `ever` على `isAuthenticated`.

---

## 8. AuthMiddleware وManagerMiddleware

- **`AuthMiddleware.redirect`:** بلا جلسة (`SessionService.isAuthenticated`) ← `RouteSettings(name: Routes.login)`.
- **`GuestMiddleware.redirect`:** مع جلسة ← `Routes.gate`.
- **`ManagerMiddleware.redirect`** (`app/middleware/manager_middleware.dart`):
  - `Get.find<HrApproverAccess>().canSeeTeam` غير صحيح ← `Routes.hr`.
  - موضوع على `/hr/team` بعد `AuthMiddleware`.
  - `redirect` متزامن، فيقرأ آخر صلاحية معروفة.
  - **من أين تأتي الصلاحية:**
    - من أدوار ERPNext (Leave Approver / Expense Approver) عبر `TeamRepository.fetchApproverAccess`.
    - تكتبها `HrAccessController` عند فتح `/hr`، و`TeamController` عند فتح الفريق.
    - غير معروفة = ممنوع.
  - **الحماية ليست بإخفاء الزر فقط:** `TeamController` يعيد الفحص، وطلبات الفريق مفلترة على الخادم بـ `leave_approver`/`expense_approver`.
- **كلها تعمل مع التنقل بالاسم فقط** (GetPage). الشاشات المفتوحة بـ `GetPageRoute` مباشرة لا تمر بـ redirect.

---

## 9. StateMixin و`controller.obx` وWorkers

**StateMixin (10 متحكمات):**

| المتحكم | النوع | ملاحظة |
|---|---|---|
| `ProfileController` | `EmployeeProfile` | |
| `AttendanceController` | `List<AttendanceRecord>` | empty يعرض الملخص (أصفار) + رسالة الفراغ |
| `OvertimeController` | `OvertimeMonth` | |
| `StatementCustomersController` | `List<ErpCustomer>` | البحث محلي داخل success |
| `CustomerStatementController` | `CustomerStatement` | empty يعرض الملخص + «لا حركات» |
| `GlEntriesController` | `CustomerLedger` | empty = مسودة فقط |
| `VoucherDetailsController` | `Map<String, dynamic>` | |
| `PayslipsController` | `List<PayslipSummary>` | الحالة من `everAll`، والقائمة تبقى ظاهرة أثناء إعادة التحميل |
| `AdvancesController` | `List<EmployeeAdvance>` | مثله |
| `ExpensesController` | `List<ExpenseClaimSummary>` | مثله |

- **الواجهات:** `controller.obx(onLoading: LoadingView, onError: ErrorView, onEmpty: …, (state) => …)`.
- **في المتحكمات السبعة التي حُوّلت في R7** بقيت الحقول القديمة (`isLoading`/`loading`، `error`، القيمة) لأن الاختبارات وأجزاء من الشاشات تقرؤها.

**آليات أخرى:**
- **`GetBuilder` + `update()`:** `CheckinController`، `CorrectionController`، `LeavesController`، المحوّلة من ChangeNotifier بنفس نقاط التحديث.
- **`Obx` مع Rx:** بقية متحكمات modules.

**Workers ومؤقتات موجودة فعليًا:**

| أين | ماذا | الإلغاء |
|---|---|---|
| `AuthController` | `everAll` على حالة SessionService | في `dispose` |
| `HrApproverAccess` | `ever` على `isAuthenticated` | خدمة دائمة |
| `Payslips` / `Advances` / `ExpensesController` | `everAll([loading, error, list])` لحساب الحالة | في `onClose` |
| `NewSaleController` (features/van_sales) | `ever` على العميل ← `loadCredit` | **لا إلغاء صريح في onClose** (لم يُفحص أثره) |
| `CheckinController` | `Timer.periodic` للساعة | في `onClose` |
| `CustomersController`، `new_purchase_order_screen` | تأخير البحث (debounce) بـ `Timer(AppConstants.searchDebounce)` | ليس Worker `debounce` من GetX |

بقية حقول البحث تصفية محلية بلا طلبات، فلا تأخير لها.

---

## 10. ErpApiClient و401/403

- **نسخة واحدة** (`main.dart:93`):
  - **Base URL:** `ErpConfig.baseUrl`.
  - **الترويسات:** `Cookie: sid=…`، `X-Frappe-Site-Name`، `Accept: application/json`.
  - **المهلة:** `ErpConfig.requestTimeout` (10 ثوانٍ، السطر 373).
  - **الأخطاء:** تُحوَّل إلى `ErpApiException(ErpErrorType…)`، ورسائلها العربية في `describeError`.
- **401** (`erp_api_client.dart:388`): `_expireSession` مركزيًا.
  - يحذف الجلسة ويستدعي `onSessionExpired` مرة واحدة حتى مع طلبات متوازية (`_expiringSid`).
  - لا يحذف جلسة أحدث إن سجّل المستخدم دخوله أثناء الطلب (`_session.sid == sid`).
  - يعيد `sessionExpired`، فيعرض AuthGate شاشة الدخول.
- **403** (السطر 392): `_denied` ← فحص واحد مشترك (`_sessionCheck`) لـ `frappe.auth.get_logged_user`.
  - Guest أو 401/403 من الفحص ← `_expireSession`.
  - **مستخدم حقيقي** ← `forbidden` («ليس لديك صلاحية لهذا الإجراء.»)، **بلا مسح للجلسة ولا خروج**.
  - **تعذّر الفحص** (مهلة، شبكة، رد غير مفهوم) ← `forbidden` أيضًا، لا خروج (تغيير R7).
- **مُختبر في `test/data/api/erp_api_client_session_test.dart`:** 401 متزامن، 403 Guest متزامن، 403 لمستخدم حقيقي، 403 مع تعذّر الفحص، 401 بعد دخول جديد.

---

## 11. الترجمات العربية والإنجليزية وRTL

- **`app/translations/`:**
  - `AppTranslations extends Translations`: `defaultLocale` و`fallback` = `ar`، `supported = [ar, en]`.
  - `ar.dart` (`arTranslations`) و`en.dart` (`enTranslations`).
  - `language_scope.dart` (`LanguageScope`): يعيد بناء كل الشاشات عند تغيّر اللغة عبر `rebuildAllChildren`.
- **التسجيل:** `Get.addTranslations` في `main.dart:72` قبل أول نص، و`translations: AppTranslations()` في GetMaterialApp.
- **أصناف النصوص** (`AppStrings`، `EssStrings`، `StatementStrings`، `PurchaseStrings`، `ReturnsStrings`، `VanStrings`، `VisitStrings`، `WarehouseStrings`، `InventoryStrings`) بقيت بنفس الأسماء. داخلها `'key'.tr` و`trParams`، فلم تتغير الشاشات.
- **`AppStrings.isArabic`** = لغة `Get.locale` (الافتراضي `ar`).
- **اللغة:** `LanguageController`:
  - الافتراضية `AppLanguage.arabic` إن لم يوجد اختيار محفوظ.
  - يحفظ في SharedPreferences.
  - يضبط `Get.locale`.
- **الاتجاه:** `Directionality(textDirection: language.direction)` في builder، حيث `arabic ← rtl` وغيرها `ltr`.
- **عدد المفاتيح:** `ar.dart` فيه مفتاح واحد زائد عن `en.dart`، هو `app.whatsappDebtMessage`: رسالة تذكير العميل بالعربية دائمًا كما كانت، تُقرأ من `arTranslations` مباشرة.
- **مُختبر:**
  - `test/translations/strings_equivalence_test.dart`: كل نص مطابق لما قبل الترجمة باللغتين (1,447 حالة).
  - `test/app/translations/language_switch_test.dart`: العربية وRTL افتراضيًا، التبديل إلى LTR أثناء التشغيل، الحفظ، اكتمال المفاتيح.
  - `test/flutter_test_config.dart` يحمّل الترجمات قبل كل اختبار، لأن `Get.reset()` يمسحها.

---

## 12. المشكلات الخمس في ARCHITECTURE_BEFORE.md §9

| # | المشكلة قبل | الآن (من الكود الحالي) | الحالة |
|---|---|---|---|
| 1 | خليط إدارة الحالة: 27 ChangeNotifier مقابل 12 GetxController، ومتحكمات GetX تأخذ تبعياتها من `context.read` | 28 GetxController مقابل 16 ChangeNotifier (كلها في `core/` و`features/`). متحكمات `modules/` تأخذ تبعياتها من Bindings | **جزئي** |
| 2 | `main.dart` ضخم، و`DebtsApp` بنحو 20 معاملًا، و9 Factories لتمرير التبعيات | repositories الوحدات المرحّلة في InitialBinding، وأُزيلت مزوّداتها وحقولها. لكن `main.dart` ما زال 430 سطرًا و17 Provider، و8 Factories باقية (Customers، Inventory، Order، Orders، Purchases، SalesReturns، Visits، Warehouses) | **جزئي** |
| 3 | `Get.put` بالنوع في initState: شاشة مكررة تحذف متحكم الأخرى | في `modules/`: Bindings مع tag لكل مسار، والحذف مع المسار. ما زال `Get.put` في 6 شاشات `features/van_sales` | **جزئي** |
| 4 | تكرار المنطق نفسه في أكثر من مكان | `_message` المكررة في شاشات HR ← `hrErrorMessage`/`hrServerError` و`errorMessage` في المتحكمات. FutureBuilder من 9 شاشات إلى 2 (`order_details_screen`، `purchase_details_screen`) | **جزئي** |
| 5 | حالة `static` قابلة للتغيير في `ErpConfig`، ومستودع فان مكتوب في الكود | لم يتغير: `ErpConfig` كما هو | **لم يُعالج** |

---

## 13. ما لم يكتمل أو بقي خارج الهيكلية الجديدة

- **`lib/features/` كلها خارج `modules/`:** auth، customers، home، inventory، order، orders_section، purchases، sales_returns، settings، van_sales، visits، warehouses.
  - **ChangeNotifier عبر Provider:**
    - `CustomersController`، `CustomerDetailsController`، `CustomerInvoicesController`، `DraftInvoiceController`.
    - `OrderController`، `OrdersController`، `PurchasesController`، `InventoryController`.
    - `VisitActions`، `VisitFormController`، و`_LoadingController` في sales_returns وwarehouses.
    - في `core`: `LanguageController`، `ThemeController`، `SyncService`، و`AuthController` (محوّل).
  - **`features/van_sales`:** 6 شاشات تنشئ متحكمات GetX بـ `Get.put` في initState، بلا Bindings ولا StateMixin.
  - **FutureBuilder** في `orders_section/screens/order_details_screen.dart` و`purchases/screens/purchase_details_screen.dart`.
  - **التنقل** بـ MaterialPageRoute، ولا GetPage لها، باستثناء `OrdersScreen.route()` و`CustomerOperationsScreen.route()`، وكلاهما GetPageRoute مع Bindings للأجزاء المرحّلة داخلهما.
- **متحكمات GetX في `modules/` بلا StateMixin:**
  - `SalesInvoicesController`: نسخة محفوظة مع تنبيه «غير متصل».
  - `InvoiceDetailsController`: مثله.
  - `TeamController`: تبويبان بصلاحيتين.
  - `CustomerCollectionsController`: تبويبات داخل شاشة أخرى.
  - `InvoiceCollectionsController`، `PaymentSheetController`، `HrAccessController`: ليست شاشات قوائم.
  - `CheckinController`، `CorrectionController`، `LeavesController`: GetBuilder.
- **المجلدات المطلوبة غير الموجودة:** `modules/auth`، `modules/customers`، `modules/orders`، `core/network`، `app/theme`.
- **`ErpConfig` static** ومستودع الفان المكتوب في الكود (المشكلة 5).
- **الاختبارات:** لم يُنفَّذ أي اختبار يدوي على جهاز أو محاكي، ولا تكامل مع ERPNext حقيقي. التفاصيل في [REGRESSION_CHECKLIST.md](REGRESSION_CHECKLIST.md).
