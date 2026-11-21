# ARCHITECTURE_AFTER — الهيكلية بعد إعادة البناء (R1–R7)

> المرجع السابق: [ARCHITECTURE_BEFORE.md](ARCHITECTURE_BEFORE.md).
> **السجلات:**
> - [PROMPTS.md](PROMPTS.md): الطلبات ونتائج كل مرحلة.
> - [REGRESSION_CHECKLIST.md](REGRESSION_CHECKLIST.md): جدول الاختبارات.
> - تقارير المراحل: [R5_REPORT.md](R5_REPORT.md)، [R6_REPORT.md](R6_REPORT.md)، [R7_REPORT.md](R7_REPORT.md).
> - الملخص الكامل: [FINAL_REFACTOR_REPORT.md](FINAL_REFACTOR_REPORT.md).

## حالة الترحيل

| المرحلة | المحتوى | Commit |
|---|---|---|
| R1 | GetMaterialApp، SessionService، LoginController، InitialBinding، AuthMiddleware | `c92ca8c` |
| R2 | `modules/statement` (العملاء، الكشف، المستند) | `fb9bf00` |
| R3 | `modules/invoices` و`modules/collections` | `12c99df` |
| R4 | `modules/statement`: الرصيد الجاري، GL Entries | `7dacbef` |
| R5 | `modules/hr`: profile، punch، attendance، leaves (+ home، shared) | `6dad1fc` |
| R6 | `modules/hr`: advances، expenses، payslips، team، overtime، وManagerMiddleware | `4af3586` |
| R7 | الترجمات (GetX Translations)، 401/403 المركزي، SessionService، التنظيف | `refactor: complete GetX architecture and cleanup` |

## الهيكل النهائي (الفعلي)

```
lib/
  main.dart                     إنشاء الكائنات مرة واحدة ← InitialBinding ← GetMaterialApp
  app/
    bindings/initial_binding.dart        كل الخدمات والـ repositories الدائمة (Get.put permanent، _putOnce)
    middleware/auth_middleware.dart      AuthMiddleware، GuestMiddleware
    middleware/manager_middleware.dart   ManagerMiddleware (معتمِدو الإجازات/المصاريف)
    routes/app_routes.dart · app_pages.dart   15 GetPage (البوابة، الدخول، الرئيسية، 12 لـ HR)
    services/session_service.dart        SessionService (GetxService دائم)
    translations/                        app_translations.dart، ar.dart، en.dart، language_scope.dart
  core/
    constants/   أصناف النصوص (AppStrings، EssStrings…): واجهة ثابتة، والنص من translations
    widgets/     loading_view، error_view، empty_view، app_drawer…
    utils/ services/ theme/ localization/
  data/          api/ (ErpApiClient، ErpAuthService، SessionStore، ErpConfig)، repositories/ models/ مشتركة
  modules/       ← البنية الجديدة (feature-first)
    statement/ invoices/ collections/
    hr/ home/ shared/ profile/ punch/ attendance/ leaves/ overtime/ advances/ expenses/ payslips/ team/
  features/      ← لم تُرحَّل بعد (انظر «ما لم يُرحَّل»)
    auth/ customers/ home/ order/ orders_section/ purchases/ sales_returns/ settings/ van_sales/ visits/ warehouses/ inventory/
```

**الفرق عن الهيكل المطلوب:**
- لم تُنقل `customers` و`orders` و`auth` إلى `lib/modules`.
- لم يُنشأ `core/network` (ErpApiClient باقٍ في `data/api`).
- لم يُنشأ `app/theme` (الثيم في `core/theme`).

نقل هذه الأجزاء يحتاج مراحل ترحيل كاملة مثل R2–R6، ولم يُنقل أي شيء شكليًا دون ترحيل فعلي. لم تُنشأ مجلدات فارغة لمطابقة الشكل.

## الطبقات

```
View / Widget  ──Obx / GetBuilder / controller.obx──▶  Controller (GetxController)
     │ Get.find(tag)                                        │ يستدعي
     │ Get.toNamed / X.route()                              ▼
     ▼                                                 Repository  ──▶  ErpApiClient (واحد)  ──▶  ERPNext
 Navigator + حوارات (تحتاج context)                      ▲ Get.put(permanent) في InitialBinding
```

| الطبقة | المسؤولية | ممنوع فيها |
|---|---|---|
| View (`views/`) وWidget (`widgets/`) | العرض، التنقل، الحوارات، حقول النص (`TextEditingController`) | طلبات API، حسابات، إنشاء متحكم (`Get.put`) |
| Controller | حالة Rx أو StateMixin أو `update()`، الأوامر، رسائل الخطأ | BuildContext، http |
| Repository | الطلبات والـ parsing، كما كانت حرفيًا | حالة واجهة |
| Model | تمثيل JSON (نفس أسماء الحقول) والحسابات النقية (مثل `CustomerStatement.fromGlRows` و`CustomerLedger`) | — |

**اختيار آلية الحالة:**
- **Obx:** حالة تفاعلية بسيطة.
- **GetBuilder + `update()`:** للمتحكمات المحوّلة من ChangeNotifier (Checkin، Correction، Leaves)، فتبقى نقاط التحديث كما كانت.
- **StateMixin + `controller.obx`:** شاشات البيانات (حسابي، حضوري، العمل الإضافي)، بحالات loading وerror وempty وsuccess.

## Bindings
- **23 Binding**، كلها `Get.lazyPut`: المتحكم يُنشأ عند أول `Get.find` في شاشته ويُحذف عند إغلاق مساره (`GetPage` أو `GetPageRoute`).
- **tag لكل مسار** حيث يمكن أن تتكدّس الشاشة: المستند، كشف الحساب، القيود، الفاتورة، تحصيلات العميل، نافذة الدفع، كشف الراتب.
- **`InitialBinding`** يسجّل نفس كائنات `main()` مرة واحدة (`_putOnce` يمنع التكرار). لا Binding يُنشئ repository أو ApiClient ثانيًا.

## SessionService (R1، وR7)
- **`GetxService` دائم، نسخة واحدة:** يُنشأ في `main.dart:90`، ويُسجَّل في InitialBinding.
- **الحالة:** `isAuthenticated` و`fullName` و`sessionExpired`.
- **(R7) هوية الموظف:** `employeeId` و`employeeName` يحفظها ProfileController بعد التحميل، وتُمسح مع الخروج أو انتهاء الجلسة فلا تنتقل بين مستخدمين.
- **لا كلمات مرور ولا أسرار:** `sid` في التخزين الآمن (SessionStore) فقط.

## ErpApiClient (R7)
- **واحد** (`main.dart:93`): Base URL من ErpConfig، والترويسات `Cookie: sid` و`X-Frappe-Site-Name` و`Accept`، ومهلة 10 ثوانٍ.
- **401:** إنهاء مركزي للجلسة: حذف `sid` ثم `onSessionExpired` مرة واحدة حتى مع طلبات متوازية (`_expiringSid` وفحص `sid == sid`)، فيعيد AuthGate المستخدم إلى الدخول كما في R1.
- **403:**
  - فحص واحد مشترك (`get_logged_user`).
  - **Guest** ← إنهاء الجلسة.
  - **مستخدم حقيقي أو تعذّر الفحص** ← `forbidden` («ليس لديك صلاحية لهذا الإجراء.»)، **دون مسح الجلسة ودون خروج**.
- **الشبكة:** `network` برسالة عربية، والنسخة المحلية حيث كانت.

## Middleware
- **`AuthMiddleware`:** بلا جلسة ← `/login`.
- **`GuestMiddleware`:** مع جلسة ← `/`.
- **`ManagerMiddleware` (R6):** على `/hr/team`.
  - يقرأ `HrApproverAccess`: آخر صلاحية من أدوار ERPNext (Leave Approver / Expense Approver)، تُكتب بعد فحص الخادم وتُمسح عند الخروج.
  - غير معروفة أو غير معتمِد ← `/hr`.
  - الحماية ليست بإخفاء الزر وحده، و`TeamController` يعيد الفحص من الخادم.

## Translations (R7)
- **`lib/app/translations/ar.dart` و`en.dart`:** أكثر من 1,300 مفتاح.
  - `AppTranslations` مسجّلة في GetMaterialApp وفي `main()` قبل أول نص.
  - العربية افتراضية واحتياطية.
- **أصناف النصوص** (`AppStrings`، `EssStrings`…) بقيت **نفس الواجهة** (`AppStrings.retry`)، فلم تتغير أي شاشة. داخلها `'app.retry'.tr` و`trParams` بدل `_t(ar, en)`.
- **اللغة:**
  - `LanguageController` يضبط `Get.locale` ويحفظ الاختيار كما كان.
  - `LanguageScope` (نُقل من main) يعيد بناء الشاشات عند التبديل.
  - `Directionality` من اللغة: RTL للعربية وLTR للإنجليزية.
- **مثبت باختبار:** تطابق **1,447 حالة** (كل نص وكل دالة بعدة قيم) مع ما قبل الترجمة، باللغتين.
- **استثناء مقصود واحد:** رسالة تذكير واتساب للعميل بالعربية دائمًا، كما كانت.

## Shared Widgets
- **`LoadingView` و`ErrorView` و`EmptyView`** (`core/widgets`، موجودة من قبل وبنفس التصميم) تستخدمها كل الوحدات المرحّلة.
- **(R7):** تبويب تحصيلات العميل صار يستخدم `LoadingView` بدل مؤشر مكرر، بنفس الشكل.

## المشكلات الخمس في ARCHITECTURE_BEFORE.md §9 وما حدث لها

| # | المشكلة قبل | الآن |
|---|---|---|
| 1 | خليط Provider/GetX: 27 ChangeNotifier مقابل 12 GetxController، ومتحكمات GetX تأخذ تبعياتها من `context.read` | **28 GetxController مقابل 16 ChangeNotifier**. كل `modules/` بلا `context.read` لإنشاء متحكم. **باقٍ** في `features/` غير المرحّلة |
| 2 | `main.dart` ضخم، و`DebtsApp` بنحو 20 معاملًا، و9 Factories | أُزيلت مزوّدات وحقول statement وsales invoices وemployee repository، والـ repositories تُسجَّل في InitialBinding. **جزئي:** `main.dart` 430 سطرًا، و8 Factories باقية لـ features |
| 3 | `Get.put` بالنوع فقط: شاشة مكررة تحذف متحكم الأخرى | في `modules/` كلها Bindings بمسار وtag عند الحاجة، والحذف مع المسار. **باقٍ** في 6 شاشات van_sales (لم تُرحَّل) |
| 4 | تكرار المنطق نفسه (مثل `_message` في كل شاشة HR، وتنسيق رسالة رفض الخادم) | `hrErrorMessage`/`hrServerError` في `hr/shared`، و`errorMessage` في المتحكمات. FutureBuilder من 9 شاشات إلى 2 |
| 5 | حالة `static` قابلة للتغيير في ErpConfig، ومستودع فان مكتوب في الكود | **لم يُعالج** (تغييره يغيّر السلوك والإعداد). موثّق كعمل لاحق |

## ما لم يُرحَّل بعد
- **features:** customers (CustomerScreen، CustomerDetails، OperationDialog، فواتير العميل، مسودات الطلبيات)، order، orders_section (الطلبيات والتسليمات)، purchases، sales_returns، visits، warehouses، inventory، van_sales، settings، home.
- **ما زال فيها:** ChangeNotifier وProvider، و`Get.put` في initState (van_sales)، وFutureBuilder في `order_details_screen` و`purchase_details_screen`.
- **التنقل فيها:** `X.route()` (MaterialPageRoute)، بلا مسارات مسماة.
