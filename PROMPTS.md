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


---

## R3 — Collections & Invoices

### الطلب (مختصر)
إعادة هيكلة التحصيلات والفواتير في `lib/modules/collections` و`lib/modules/invoices` بنمط View → Controller → Repository → ApiClient. القيود:
- لا تغيير في endpoints أو methods أو payloads أو أسماء الحقول.
- لا تغيير في حساب المبالغ، ولا في ربط الفواتير بالعملاء، ولا في حفظ المسودات.
- لا تغيير في قواعد التحقق أو الرسائل أو التنقلات.
- لا Repository مكرر.

### ما وُجد فعليًا في المشروع
| المطلوب | الموجود | المكان قبل R3 |
|---|---|---|
| الفواتير غير المدفوعة | قسم «الفواتير»: مسودة / غير مدفوعة / جزئيًا / مدفوعة | `orders_section` (SalesInvoicesController + InvoicesTabsView) |
| تفاصيل الفاتورة | InvoiceDetailsScreen (من فواتير العميل) | `customers` |
| إنشاء مسودة تحصيل | ① على فاتورة: payment_sheet → get_payment_entry → POST Payment Entry (مسودة) ② للعميل: «إضافة دفعة» → createPaymentEntry(submit: false) | `orders_section`، `customers` |
| تعديل مسودة تحصيل | **غير موجود**: لا يوجد في المشروع أي `putDoc('Payment Entry')` | — |
| حذف مسودة تحصيل | «إلغاء» → DELETE Payment Entry (404 = نجاح) | `customers/widgets/payments_tabs.dart` |
| اعتماد مسودة | «اعتماد» → GET المستند → frappe.client.submit (سلوك موجود سابقًا، لم يتغير) | نفسه |
| تفاصيل التحصيل | VoucherDetailsScreen('Payment Entry') | رُحّل في R2 |

### الملفات
- **نُقلت (git mv):**
  - `erp_payment_repository.dart` و`payment_entry.dart` إلى collections.
  - `payment_sheet.dart` و`payments_tabs.dart` إلى `collections/widgets`.
  - `invoices_tabs_view.dart` و`sales_invoice_card.dart` و`sales_invoices_controller.dart` و`invoice_details_controller.dart` و`invoice_details_screen.dart` إلى invoices.
  - `erp_sales_invoices_repository.dart` إلى invoices، ثم قُسِّم.
- **جديدة:**
  - `collections/{bindings/collections_bindings, controllers/{invoice_collections,payment_sheet,customer_collections}_controller, repository/invoice_collections_repository, models/collection_models}.dart`
  - `invoices/{bindings/invoices_bindings, models/sales_invoices_result}.dart`
- **عُدّلت:**
  - `customer_details_controller.dart`: أُزيلت حالة الدفعات، وأُضيفت `CustomerCollectionsHost`.
  - `customer_operations_screen.dart`: المسار والـ Obx لـ `isErpCustomer`.
  - `orders_screen.dart`: المسار.
  - `delivery_tile.dart`: `Get.find` و`reload`.
  - `main.dart` و`initial_binding.dart`.
  - تعديل سطر import فقط في: `operation_dialog`، `invoice_tab`، `customer_invoices_screen`، `erp_purchases_repository`، `purchases_controller`.

### نتائج R3
- **`dart format`:** على `lib/modules` والاختبارات و`main.dart` فقط. ملفات features القديمة تغيّرت فيها الأسطر المقصودة وحدها.
- **`flutter analyze`:** 23 ملاحظة info، كلها قديمة. كان العدد 25: اثنتان اختفتا لأن المتحكمين أُعيدت كتابتهما. ظهرت ملاحظتان جديدتان (if بلا أقواس بعد format) وأُصلحتا.
- **`flutter test`:** 56 ناجحة (31 سابقة + 25 جديدة).
  - `test/modules/collections/invoice_collections_test.dart` (11):
    - تسلسل الطلبات وجسم POST: حذف مفاتيح `__`، و`paid_to` لحساب الشركة، والملاحظة والمرجع والتاريخ، والحقول الفارغة لا تُرسل، ولا `docstatus`.
    - مفتاح المعلّقة القديم.
    - الشبكة ← `draftNeedsConnection`.
    - 417 ← الرسالة + نص ERPNext.
    - طريقة دفع بلا حساب ← لا POST.
    - reconcile.
    - التحقق: المبلغ (هامش 0.005، والأرقام العربية)، والشيك، والبطاقة (4 أرقام)، والتحويل.
    - الحفظ: النجاح والفشل، ومنع الحفظ المكرر.
  - `test/modules/collections/customer_collections_test.dart` (8):
    - عميل محلي بلا طلبات.
    - فلاتر التحميل وترتيبه.
    - مستمع المسودة.
    - DELETE ثم إعادة التحميل، و404 = نجاح.
    - الاعتماد: GET ثم submit بالمستند كاملًا، ثم السجل المحلي.
    - رفض الاعتماد.
    - ضغطتان = طلب واحد.
    - الشبكة.
  - `test/modules/invoices/sales_invoices_controller_test.dart` (5):
    - طلب واحد بنفس الفلتر والحقول، والحفظ المحلي.
    - التبويبات الأربعة (والمفوترة من التطبيق ← غير مدفوعة).
    - دون اتصال مع نسخة محفوظة ← تنبيه بالوقت.
    - دون اتصال ولا نسخة.
    - reload متزامن = طلب واحد.
  - `test/modules/invoices/invoices_screens_test.dart` (Widget، 2):
    - قسم الفواتير على GetPageRoute بالـ Bindings: طلب واحد، و«دفع» يفتح النافذة بمتحكمها، وإغلاق النافذة يحذف متحكمها، والرجوع يحذف متحكمي القسم، والـ repository يبقى.
    - تبويبات العميل: «إلغاء» ← تأكيد ← DELETE ← رسالة النجاح ← التبويب فارغ.
- **مقارنة الواجهة** (بعد حذف المسافات والفواصل): `_PaymentCard` و`SalesInvoiceCard.build` و`_InvoiceView` و`_InvoicesPage._empty` و`_DateField` و`_InfoLine` متطابقة. الفروق الوحيدة: `refresh` صارت `reload`، و`pendingAmount` يُقرأ من collections.
- **التكرار:** كل repository يُنشأ مرة واحدة في `main.dart` (الأسطر 109 و117 و167 و171). لا Repository ولا `Get.put` داخل views وwidgets، ولا BuildContext ولا http في المتحكمات.


---

## R4 — Customer Statement & GL Entries

### الطلب (مختصر)
إعادة هيكلة كشف الحساب والقيود المحاسبية في `lib/modules/statement`. الرصيد الجاري يبقى كما كان تمامًا. اختبارات Unit مستقلة للرصيد الجاري. لا نقل لحساب يقوم به ERPNext إلى التطبيق.

### ما وُجد فعليًا
| المطلوب | الموجود |
|---|---|
| كشف حساب العميل | CustomerStatementScreen (رُحّل في R2) |
| GL Entries | GlEntriesScreen.forInvoice / forOrder (Payment Ledger Entry، واحتياطًا GL Entry). الشاشة كانت FutureBuilder مع `context.read` |
| الرصيد الافتتاحي | من ERPNext: `get_balance_on` لليوم السابق للفترة (0 دون فترة) |
| Running Balance | يحسبه **التطبيق** من GL Entry: الافتتاحي + Σ(مدين − دائن)، داخل `fetchStatement`. ERPNext لا يعيده جاهزًا هنا، فبقي في التطبيق |
| الفلاتر والتواريخ | فترة من/إلى (`showDateRangePicker`) ← فلاتر `posting_date` |
| تفاصيل القيود | VoucherDetailsScreen (R2) |
| البحث | قائمة العملاء فقط (تصفية محلية، بلا debounce لأنه لا طلبات) |

### الملفات
- **نُقلت (git mv):**
  - `data/repositories/erp_ledger_repository.dart` إلى `statement/repository/`.
  - `data/models/gl_entry.dart` إلى `statement/models/`.
  - `features/customers/screens/gl_entries_screen.dart` إلى `statement/views/gl_entries_view.dart`.
- **جديدة:**
  - `statement/controllers/gl_entries_controller.dart`
  - `statement/widgets/{gl_ledger_table,statement_summary}.dart`: نُقلت من الشاشتين كما هي.
- **عُدّلت:**
  - `statement_models.dart`: `CustomerStatement.fromGlRows`.
  - `erp_statement_repository.dart`: يستدعيها.
  - `statement_bindings.dart`: `GlEntriesBinding`.
  - `customer_statement_view.dart`: يستخدم widgets.
  - `initial_binding.dart` و`main.dart`: `ErpLedgerRepository`.
  - سطر import فقط في: `order_details_screen`، `sales_invoice_card`، `invoice_details_view`.

### نتائج R4
- **`dart format`:** على `lib/modules` والاختبارات فقط.
- **`flutter analyze`:** 23 ملاحظة info، كلها قديمة. ظهر تحذيران جديدان (import غير مستخدم بعد نقل widgets) وأُصلحا.
- **`flutter test`:** 74 ناجحة (56 + 18 جديدة).
  - `test/modules/statement/running_balance_test.dart` (10):
    - افتتاحي + مدين ودائن معًا.
    - مدين فقط.
    - دائن فقط (سالب).
    - بلا حركات (الختامي = الافتتاحي).
    - تواريخ مختلفة وقيدان بنفس اليوم: الترتيب كما من ERPNext.
    - قيم نصية أو null.
    - **مطابقة الحساب القديم حرفيًا** على 20 × 300 صف عشوائي.
    - repository حقيقي:
      - مع فترة: فلاتر التاريخ والترتيب، و`get_balance_on` بتاريخ اليوم السابق (2025-12-31)، والختامي.
      - كل الفترات: بلا طلب افتتاحي.
      - الصفحات: 100 + 30 صفًا، والرصيد مستمر.
  - `test/modules/statement/gl_entries_test.dart` (8):
    - مسودة: طلب واحد ولا قيود.
    - معتمدة: فلاتر Payment Ledger Entry، وحذف السطور الصفرية، والمدين والدائن والفرق.
    - 403 ← احتياط GL Entry، والشبكة لا تُحتاط.
    - طلبية: فواتير مكررة مرة واحدة.
    - المتحكم: طلب واحد، ورسالة المسودة، والشبكة ثم إعادة المحاولة.
    - Widget:
      - GlEntriesScreen: Loading ثم الجدول و«متوازنة»، والمتحكم يُحذف مع المسار.
      - كشف الحساب: Empty ثم Error دون انهيار، ثم «إعادة المحاولة».
- **مقارنة الواجهة:** `GlLedgerTable` و`GlTotals` و`_num` و`StatementSummary` و`StatementLineTile` متطابقة مع الأصل بعد حذف المسافات والفواصل.
- **التكرار:**
  - `ErpLedgerRepository` يُنشأ مرة واحدة (`main.dart:218`). المستهلكان: GetX (`GlEntriesBinding`) وProvider (`order_details_screen`)، ونفس الكائن.
  - لا FutureBuilder في `lib/modules`.
- **ملاحظة سلوك قائم (لم يُغيَّر):** `forInvoice` لفاتورة غير موجودة في ERPNext يعاملها كمسودة (`rows.isEmpty ← docstatus 0`)، فتظهر رسالة «بانتظار الاعتماد». ثبّتناها في الاختبار كما هي.

### جدول الاختبارات (بعد R3 وR4)

**الرموز:**
- U = Unit test، W = Widget test، I = Integration test (على ERPNext حقيقي)، M = اختبار يدوي على الجهاز.
- ✅ نُفّذ ونجح، ⛔ لم يُنفَّذ، — لا ينطبق.
- **لم يُنفَّذ أي اختبار Integration ولا يدوي في R3 ولا R4:** لا يوجد اتصال فعلي بـ ERPNext من بيئة التطوير. كل الطلبات اختُبرت على ErpApiClient حقيقي فوق MockClient.

| الاختبار | R3 | R4 |
|---|---|---|
| عرض الفواتير غير المدفوعة | U ✅، W ✅، I ⛔، M ⛔ | لم يتأثر (اختبارات R3 ناجحة) |
| إنشاء مسودة تحصيل | U ✅ (الطلبات + الجسم)، W ✅ (فتح النافذة والتحقق)، I ⛔، M ⛔ | لم يتأثر |
| تعديل مسودة تحصيل | — غير موجود في المشروع | — |
| حذف مسودة تحصيل | U ✅، W ✅، I ⛔، M ⛔ | لم يتأثر |
| صحة مبالغ التحصيل | U ✅ (party_amount، allocated_amount، مجموع المعلّقة، حد المستحق) | لم يتأثر |
| عرض كشف حساب العميل | لم يتأثر: R2 U/W ✅ | U ✅، W ✅ (Empty/Error/Retry)، I ⛔، M ⛔ |
| عرض GL Entries | — | U ✅ (repository + controller)، W ✅ (الجدول، متوازنة، عمر المتحكم)، I ⛔، M ⛔ |
| صحة الرصيد الافتتاحي | لم يتأثر: R2 U ✅ | U ✅ (get_balance_on لليوم السابق، 0 دون فترة) |
| صحة Running Balance | لم يتأثر: R2 U ✅ | U ✅ (7 حالات + مطابقة الحساب القديم على 6000 صف) |
| تطابق الرصيد النهائي مع ERPNext | I ⛔، M ⛔ | U ✅ للمعادلة فقط (الختامي = الافتتاحي + Σ مدين − Σ دائن)؛ **المطابقة مع خادم حقيقي: I ⛔، M ⛔** |
| عمل الفلاتر والتواريخ | لم يتأثر: R2 U ✅ | U ✅ (فلاتر posting_date والترتيب) |
| معالجة أخطاء الشبكة | U ✅ (الدفع، التحميل، الفواتير، reconcile) | U ✅، W ✅ (الكشف والقيود دون انهيار) |
| عدم تأثر R1 وR2 | U/W ✅ (الـ 31 السابقة)، M ⛔ | U/W ✅ (كل الـ 56 السابقة)، M ⛔ |

---

## R5 — HR Core Modules (Profile، Punch، Attendance، Leaves)

### الطلب (مختصر)
- فحص HR أولًا، وكتابة R5_ANALYSIS.md.
- `lib/modules/hr/{profile,punch,attendance,leaves}`: لكل وحدة Binding بـ lazyPut، وController بلا BuildContext ولا HTTP، وView للعرض فقط.
- الحفاظ على كل البيانات والحقول، وتوقيت فلسطين في البصمة، وقواعد الإجازات وتحذير LWP.
- StateMixin لشاشة الحضور.
- اختبارات Unit وRepository وController وWidget، ثم commit مستقل.

### الملفات
- **نُقلت (git mv):** الشاشات الخمس وثلاثة متحكمات وثلاثة ملفات models و`month_year_picker` و`employee_service` ومدخل HR.
- **جديدة:**
  - `hr/shared/{repository/hr_employee_identity, hr_errors, hr_repositories}.dart`
  - repositories الوحدات الأربع.
  - `profile_controller` و`attendance_controller`.
  - Bindings (6).
  - `attendance_widgets` و`leave_widgets`.
  - `home/controllers/hr_access_controller` (مفصول من `team_controller`).
- **عُدّلت:**
  - `erp_employee_repository.dart`: ما بقي لـ R6 فقط، فوق `HrEmployeeIdentity`.
  - `app_routes`، `app_pages` (12 GetPage لـ HR)، `initial_binding` (`hr`)، `main.dart`.
  - `app_drawer` (import).
  - شاشات R6 (import فقط).
  - `team_models` (import).

### النتائج
التفاصيل في [R5_REPORT.md](R5_REPORT.md). analyze 23 (قديمة)، test **101 ناجحة**.
