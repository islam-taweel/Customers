# R6_REPORT — بقية HR (Advances، Expenses، Payslips، My Team، + Overtime)

> **التحديث (في المستودع الأصلي مع Flutter):**
> - كُتب الكود أولًا في بيئة أخرى بلا SDK ولا git (القسم الأول أدناه).
> - بعد ذلك فُحص هنا على حالة R6 وحدها (index مستقل فوق commit R5، مختبَر في git worktree منفصل)، ثم أُنشئ commit `refactor: migrate remaining HR modules to GetX`.
> - النتائج الفعلية في قسم «التحقق الفعلي» آخر الملف.

## حالة الأرشيف عند الاستلام
- `Repository` و`Controller` و`Model` لوحدات R6 كانت منقولة أصلًا إلى `lib/modules/hr/{advances,expenses,payslips,team,overtime}`.
- **الشاشات (Views) لم تكن مرحَّلة**: كانت ما زالت تنشئ المتحكم بـ `Get.put` في `initState` وتقرأ `ErpEmployeeRepository` من Provider، واستيراداتها مكسورة (28 مسارًا غير موجود، مثل `lib/modules/core/...`).
- `app_pages.dart` كان يستورد `features/employee_services/...` وهو غير موجود. `ErpEmployeeRepository` نفسه غير موجود في الأرشيف.

## ما نُفِّذ
| البند | التغيير |
|---|---|
| Views | Advances، Expenses، Payslips، PayslipDetail، Team ← `GetView<Controller>`؛ حُذف `Get.put/Get.delete` و`context.read<ErpEmployeeRepository>` ودوال `_message` المكررة (تُستبدل بـ `controller.errorMessage`). Overtime ← `StateMixin` + `controller.obx` (حالة empty تُبقي الملخص ظاهرًا كما كانت) |
| Bindings (جديدة) | `AdvancesBinding`، `ExpensesBinding`، `PayslipsBinding`، `PayslipDetailBinding` (tag = رقم الكشف من `Get.arguments`)، `TeamBinding`، `OvertimeBinding`، كلها `Get.lazyPut` |
| الاستيرادات | أُصلحت كلها؛ فحص آلي: **0 استيراد غير موجود** (لا يعني نجاح الترجمة) |
| `HrRepositories` | أُضيفت advances/expenses/payslips/team/overtime وحُذف `legacy`؛ `OvertimeRepository` كائن واحد (يحفظ فحص Overtime Slip) و`TeamRepository` يشارك `ExpensesRepository` |
| `InitialBinding` / `main.dart` | تسجيل الـ repositories الجديدة؛ حُذف `ErpEmployeeRepository` من Provider و`DebtsApp` |
| المسارات | `Routes.hrPayslipDetail`؛ كل المسارات بـ `Binding`؛ التنقل لتفاصيل الكشف بـ `Get.toNamed(..., arguments: name)` بدل `MaterialPageRoute` |
| ManagerMiddleware (جديد) | `lib/app/middleware/manager_middleware.dart` على `/hr/team` بعد `AuthMiddleware`. لم يكن موجودًا |
| `HrApproverAccess` (جديد) | خدمة دائمة تحفظ آخر صلاحية معتمِد من أدوار ERPNext؛ تكتبها `HrAccessController` و`TeamController` وتُمسح عند الخروج/انتهاء الجلسة |

## ManagerMiddleware: كيف يعمل
- `redirect` متزامن في GetX، وفحص الدور يحتاج طلب شبكة، فالـ Middleware يقرأ آخر نتيجة فحص من `HrApproverAccess`.
- **غير معروف = ممنوع**: فتح `/hr/team` مباشرة قبل فحص الصلاحية يعيد إلى `/hr` الذي يفحصها.
- الفحص الفعلي يبقى من الخادم (`get_current_user_info`: Leave Approver / Expense Approver)، و`TeamController` يعيده عند كل فتح، وطلبات الفريق نفسها تُفلتر على الخادم. لم يتغير نظام الصلاحيات.
- قيد: إن سُحب الدور أثناء الجلسة تبقى القيمة المخزّنة حتى إعادة فتح مدخل HR أو شاشة الفريق.

## ما لم يُغيَّر (مقصود)
- منطق Repository (السلف، المصاريف، رفع صورة الإيصال، الكشوف، الفريق) لم يُمسّ، ولا حساب جديد للرواتب.
- لا ميزات ولا صلاحيات جديدة.

## ما لم يُنفَّذ ويلزم تنفيذه محليًا
1. `dart format .` ثم `flutter analyze` ثم `flutter test`، وإصلاح أي أخطاء ترجمة. توقّع أخطاء محتملة لم أتمكن من كشفها بلا مترجم (مثل استيراد غير مستخدم أو ترتيب استيرادات).
2. **لا توجد اختبارات** لـ R6 في الأرشيف (لا `test/`). المطلوب كتابتها: Controller/Repository/Middleware (الوصول للمخوّل ومنع غير المخوّل)، وWidget للشاشات عبر `AppPages`.
3. `PayslipDetailBinding` يقرأ `Get.arguments as String`: يلزم التحقق على جهاز أن الانتقال من القائمة يعمل.
4. Commit: `refactor: migrate remaining HR modules to GetX` (لم يُنشأ: لا يوجد `.git` في الأرشيف).
5. اختبار يدوي: رفع صورة الإيصال، My Team للمخوّل وغير المخوّل، وكل بنود R6 في `REGRESSION_CHECKLIST.md` (كلها ⛔).

---

## التحقق الفعلي (نُفّذ في المستودع، على حالة R6 وحدها)

**طريقة الفصل:**
- شجرة العمل كانت تحوي أيضًا تعديلات R7 غير مكتملة (الترجمات، ErpApiClient، SessionService).
- لم تُحذف ولم تُستبدل: نُسخت كلها احتياطيًا إلى `C:\Users\user\customer_wip_backup_r6r7`.
- وُضعت ملفات R6 وحدها في الـ index، وأُخذ `main.dart` بنسخة R6 (بلا أسطر الترجمة) عبر `git hash-object`/`update-index`، دون تغيير الملف في شجرة العمل.
- اختُبر الـ index كما هو في `git worktree` منفصل فوق commit R5.

| الفحص | النتيجة |
|---|---|
| `dart format` | `lib/modules/hr`، `test/modules/hr` |
| `flutter analyze` | 23 info، كلها قديمة. 0 errors، 0 warnings |
| `flutter test` | **114 ناجحة** (101 سابقة + 13 جديدة لـ R6) |

**الاختبارات الجديدة:**
- `test/modules/hr/r6_modules_test.dart` (10، Unit فوق ErpApiClient حقيقي + MockClient):
  - **السلف:**
    - القائمة للموظف الحالي فقط.
    - التحقق (المبلغ والسبب) ← لا POST.
    - الطلب مسودة بالحقول نفسها (`currency` و`advance_account` من ErpConfig)، بلا docstatus.
    - رفض الخادم ← نص ERPNext.
    - الشبكة ← رسالة.
  - **المصاريف:**
    - الأنواع (Travel ← مواصلات، Food ← وجبات).
    - Expense Claim مسودة ببنده (`amount` و`sanctioned_amount` والتاريخ والوصف).
    - ثم `upload_file` multipart (`doctype`=Expense Claim، `docname`=رقم المطالبة، `filename`، `is_private`).
    - **فشل الرفع (413) ← المطالبة محفوظة مرة واحدة + تحذير بدل خطأ.**
    - مبلغ صفر أو تاريخ مستقبلي ← لا طلب.
  - **كشوف الرواتب:**
    - القائمة: docstatus=1 للموظف الحالي.
    - Earnings وDeductions وNet Pay وGross كما من ERPNext.
    - كشف لموظف آخر أو مسودة ← forbidden.
  - **فريقي:**
    - الصلاحية من الأدوار (لا معتمِد، Leave Approver، Expense Approver).
    - الطلبات مفلترة بـ `leave_approver`/`expense_approver` = المستخدم الحالي.
- `test/modules/hr/hr_screens_test.dart` (+3 Widget عبر AppPages الحقيقية):
  - **غير المعتمِد** و`Get.toNamed(/hr/team)` ← ManagerMiddleware يعيده إلى `/hr`.
  - **المعتمِد** يرى البطاقة ويدخل `/hr/team`، ويُرسل طلب واحد للإجازات. **الخروج يمسح الصلاحية المخزّنة.**
  - **الرواتب:** القائمة ← التفاصيل بـ `Get.toNamed(arguments)`، ويظهر المستحق 3,250.50 ₪ و«ضريبة الدخل» 120 ₪ والصافي 3,130.50 ₪ كما من ERPNext.

**رفع الصور (لم يتغير):**
- `ImagePicker.pickImage(imageQuality: 70, maxWidth: 1600)` من الكاميرا أو المعرض.
- الاسم من الملف (أو `receipt.jpg`).
- لا ضغط إضافي ولا حد حجم في التطبيق: الخادم يقرّر (413 ← تحذير).
- الرفع بعد حفظ المطالبة، فلا يضيع المرفق ولا المطالبة.

**لم يُنفَّذ:**
- اختبار يدوي على جهاز (اختيار صورة فعلية من الكاميرا).
- اتصال حقيقي بـ ERPNext.
