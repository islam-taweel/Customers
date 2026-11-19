# PROMPTS — سجل خطوات إعادة الهيكلة إلى GetX

## R2 — Rebuild Feature Architecture with GetX

### الطلب (مختصر)
بنية Feature-first: View → Controller → Repository → ApiClient تحت `lib/modules/...`. البداية بفحص المشروع، ثم اختيار أقل Feature خطورة وتنفيذها فعليًا واختبارها، ثم commit، ثم التوقف وانتظار الموافقة.

**القيود:**
- لا تغيير في endpoints أو payloads أو parsing.
- لا مساس بالدخول والخروج.
- لا حذف لـ Provider قبل التأكد من خلوّه من المستهلكين.
- لا تغيير في التصميم أو النصوص.
- لا services أو repositories مكررة.
- التنقل القديم يبقى متوافقًا.
- Views بلا API أو منطق، ولا إنشاء متحكمات داخل build().
- Controllers بلا BuildContext وبلا HTTP.
- Bindings عبر `Get.lazyPut`.

### نتائج الفحص (قبل التنفيذ)

| Feature | ملفات | تستوردها وحدات أخرى | ملاحظات |
|---|---|---|---|
| statement | 3 | app_drawer، payments_tabs | 3 شاشات FutureBuilder تستدعي الـ repository مباشرة |
| visits | 5 | — | |
| warehouses | 6 | — | |
| inventory | 3 | — | |
| sales_returns | 5 | — | |
| purchases | 10 | — | |
| orders_section | 9 | — | |
| order | 11 | — | |
| customers | 32 | sync_service، main | الأكبر والأخطر، يُترك للنهاية |
| employee_services | 22 | — | فيها متحكمات GetX عبر `Get.put` في initState |
| van_sales | 15 | — | نفس النمط |
| home / settings / auth | 2 / 1 / 4 | — | auth رُحّلت في R1 |

**الأعداد بعد R1:**
- GetxController: 13 صنفًا في 11 ملفًا.
- ChangeNotifier: 31.
- شاشات FutureBuilder: 9، منها 3 في statement.

**سبب اختيار `statement` أولًا:**
- الأصغر، والـ repository الخاص بها لا يستخدمه أحد غيرها.
- لها نقطتا دخول خارجيتان فقط.
- للقراءة فقط: لا كتابة إلى ERPNext.
- تمثّل مشكلة R2 بالضبط: منطق التحميل داخل الشاشات.

### التنفيذ
1. `git mv` للشاشات الثلاث والـ repository والنماذج إلى `lib/modules/statement/{views,repository,models}`. أسماء الأصناف لم تتغير.
2. ثلاثة متحكمات تنقل الحالة كما هي من `State`:
   - `StatementCustomersController`
   - `CustomerStatementController`
   - `VoucherDetailsController`
3. `statement_bindings.dart`: ثلاثة Bindings بـ `lazyPut`، مع tag فريد لكشف الحساب وللمستند.
4. الشاشات: `FutureBuilder` و`setState` و`context.read` استُبدلت بـ `Obx` و`Get.find`. شجرة الـ Widgets والنصوص لم تتغير.
5. `route()` القديمة تعيد `GetPageRoute(binding, Transition.native)` بنفس التوقيع.
6. `ErpStatementRepository` (نفس الكائن من main) سُجّل في `InitialBinding`، وأُزيل `Provider<ErpStatementRepository>` وحقل `DebtsApp` الخاص به بعد التأكد أن لا مستهلك له.
7. في `app_drawer.dart` و`payments_tabs.dart` تغيّر سطر الـ import فقط.

### الاختبارات
- **`dart format`:** طُبّق على ملفات الوحدة والاختبارات وinitial_binding فقط. أُعيد بناء `app_drawer` و`payments_tabs` من HEAD مع تعديل سطر الـ import وحده، بعد أن أعاد format تنسيقهما بالكامل.
- **`flutter analyze`:** 25 ملاحظة info، كلها موجودة قبل التعديل (نفس خط الأساس)، ولا شيء في الملفات الجديدة.
- **`flutter test`:** 31 ناجحة (22 سابقة + 9 جديدة):
  - `test/modules/statement/statement_controllers_test.dart` (7):
    - تحميل واحد عند الإنشاء.
    - البحث بالاسم والرقم والهاتف والأرقام العربية.
    - الخطأ ثم إعادة المحاولة.
    - إهمال الرد الأقدم.
    - مع `ErpApiClient` حقيقي و`MockClient`:
      - بلا فترة: طلب GL Entry واحد.
      - مع فترة: نفس فلاتر `posting_date` + `get_balance_on` لليوم السابق، والرصيد الجاري صحيح.
      - مسح الفترة.
      - 403 ← «يحتاج دور محاسبة».
      - `GET /api/resource/Sales Invoice/SINV-1`.
  - `test/modules/statement/statement_routes_test.dart` (2):
    - فتح القائمة بـ `route()` القديمة: طلب واحد فقط حتى مع إعادة البناء والكتابة في البحث، والمتحكم يُحذف عند الرجوع، والـ repository يبقى.
    - مستندان متداخلان (دفعة ← فاتورة): متحكم بوسم مختلف لكل منهما، كل واحد يُحذف مع مساره، والرجوع لا يعيد الطلب.
  - `initial_binding_test`: يتحقق أيضًا أن `Get.find<ErpStatementRepository>()` هو نفس الكائن.
- **فحص التكرار:**
  - `ErpStatementRepository(` يُنشأ في `main.dart:213` فقط.
  - لا `Get.put` ولا `context.read` ولا Repository في الـ views.
  - لا BuildContext ولا http في المتحكمات.
  - لا مراجع لمسارات `features/statement` القديمة.
- **التصميم:** مقارنة نصية بعد حذف المسافات والفواصل: `_Summary` و`_LineTile` و`_Header` و`_Section` و`_KeyValue` ومحتوى الأقسام متطابقة مع الأصل.

**بانتظار التجربة اليدوية على الجهاز:**
- القائمة الجانبية ← كشف حساب العملاء ← عميل ← فترة ← حركة ← مستند.
- العملاء ← دفعة ← تفاصيل الدفعة ← الفاتورة المخصصة.
