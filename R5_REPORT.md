# R5_REPORT — إعادة هيكلة HR الأساسية (Profile، Punch، Attendance، Leaves)

> الفحص قبل التعديل: [R5_ANALYSIS.md](R5_ANALYSIS.md). Commit: `refactor: migrate HR core modules to GetX`.

## الهيكل الجديد

```
lib/modules/hr/
  shared/
    repository/hr_employee_identity.dart   HrEmployeeIdentity + EmployeeNotLinkedException (مساعدات الهوية منقولة حرفيًا)
    models/employee_models.dart            EmployeeProfile، EmployeeShift، EmployeeCheckin (نُقل)
    widgets/month_year_picker.dart         (نُقل، مشترك مع العمل الإضافي)
    hr_errors.dart                         hrErrorMessage / hrServerError (بديل _message المكرر في كل شاشة)
    hr_repositories.dart                   كل repositories الـ HR مرة واحدة (+ legacy لوحدات R6)
  home/        bindings/hr_home_binding · controllers/hr_access_controller · views/hr_home_view · employee_service.dart
  profile/     bindings · controllers/profile_controller (StateMixin) · views/profile_view · repository/profile_repository
  punch/       bindings · controllers/punch_controller (CheckinController) · views/punch_view · repository/punch_repository
  attendance/  bindings (Attendance + Correction) · controllers (AttendanceController StateMixin، CorrectionController)
               views (attendance_view، attendance_correction_view) · widgets/attendance_widgets · repository · models
  leaves/      bindings · controllers/leaves_controller · views/leaves_view · widgets/leave_widgets · repository · models
```

## ما تغيّر
| قبل | بعد |
|---|---|
| `ErpEmployeeRepository` واحد (799 سطرًا) | repository لكل وحدة؛ الدوال منقولة **حرفيًا** (سكربت يستخرج كل دالة بتعليقاتها). التغيير الوحيد: `_employeeRow(`/`_employeeId()`/`_shift(`/`_companyOf(` ← `_identity.…`. ما بقي من الملف القديم (499 سطرًا) لوحدات R6 فقط |
| ChangeNotifier + ChangeNotifierProvider (Checkin، Correction، Leaves) | GetxController + **GetBuilder**: `notifyListeners()` ← `update()` في نفس المواضع، فتوقيت إعادة البناء لم يتغير |
| FutureBuilder (حسابي، حضوري) | `StateMixin` + `controller.obx` (loading/error/empty/success) |
| `Timer` الساعة داخل شاشة البصمة | في `CheckinController` (Rx `now`، يُلغى في onClose)، والواجهة Obx |
| `_message(e)` مكررة في 5 شاشات | `controller.errorMessage` ← `hrErrorMessage` واحدة |
| `Navigator.push(service.route)` (MaterialPageRoute) | `Get.toNamed(service.routeName)` ← `GetPage` + Binding + `AuthMiddleware` |
| `Get.put(HrAccessController)` في initState | `HrHomeBinding` (lazyPut)، و`EmployeeServicesScreen.route()` (القائمة الجانبية) صار GetPageRoute بنفس التوقيع |

## التوقيت (Punch)
- **المنطقة:** `PalestineTime` على **Asia/Gaza** من قاعدة `timezone` (UTC+2 شتاءً وUTC+3 صيفًا)، ولم يتغير.
- **الوقت المرسل:** `time = PalestineTime.format(now)` بصيغة `YYYY-MM-DD HH:MM:SS`، بلا UTC ولا `Z` ولا إزاحة، كما كان.
- **العرض:** القيمة نفسها المرسلة. ساعة الشاشة من `PalestineTime.now()` كل ثانية.
- **الحقن للاختبار:** `PunchRepository(now:)` و`CheckinController(clock:)`، والقيمة الافتراضية `PalestineTime.now`. لا تغيير في التشغيل الفعلي.
- **لم تُضف أي آلية موقع أو حضور جديدة.**

## ما بقي كما هو (مقصود)
- `AttendanceController` يبدأ بشهر `DateTime.now()` (وقت الجهاز) كما كانت الشاشة.
- أسماء الأصناف العامة: `MyAccountScreen`، `CheckinScreen`، `AttendanceLogScreen`، `AttendanceCorrectionScreen`، `LeavesScreen`، `CheckinController`.
- قواعد الإجازات:
  - الرصيد من `get_leave_details`.
  - الأيام من `get_number_of_leave_days`.
  - LWP من `lwps` ومن `is_lwp` معًا.
  - `status: Open` بلا docstatus.
- `context.select<AuthController>` لاسم المستخدم في المدخل (المحوّل من R1).

## الاختبارات (R5)
| الفحص | النتيجة |
|---|---|
| `dart format` | `lib/modules/hr`، `lib/app`، الاختبارات |
| `flutter analyze` | 23 info، كلها قديمة. ظهرت 6 info و2 warning جديدة أثناء النقل (key للـ widgets العامة، import غير مستخدم) وأُصلحت |
| `flutter test` | **101 ناجحة** (74 سابقة + 27 جديدة) |

**الاختبارات الجديدة:**
- `test/modules/hr/punch_test.dart` (12، Unit):
  - Asia/Gaza صيفًا +3 وشتاءً +2.
  - `PalestineTime.now` يطابق Asia/Gaza.
  - الصيغة.
  - POST Punch In وOut بالحقول والوقت حرفيًا (`2026-07-15 07:58:09`).
  - فلتر بصمات اليوم.
  - غير مرتبط بموظف ← لا POST.
  - حالات الدوام وحضور مكرر يُتجاهل.
  - مدة العمل.
  - رفض ERPNext والشبكة.
  - الساعة تتوقف عند الإغلاق.
- `test/modules/hr/profile_attendance_leaves_test.dart` (11، Unit):
  - Profile: الحقول والوردية وترتيب الطلبات والصورة، وnotLinked والشبكة.
  - Attendance:
    - فلتر أول الشهر وآخره.
    - التأخير 17 دقيقة من وردية 8:00.
    - الغياب والإجازة والملخص.
    - شهر سابق، وعبر السنة إلى فبراير (28 يومًا).
    - نفس الشهر لا يعيد الطلب.
    - Empty.
    - طلب الحضور: الحقول، ورفض نفس اليوم.
  - Leaves:
    - الرصيد وLWP من المصدرين.
    - تحذير LWP.
    - تجاوز الرصيد ← لا POST.
    - الطلب: `Open` + المعتمِد + الحقول + تفريغ النموذج.
    - «Insufficient» ← رسالة عربية.
    - الشبكة.
- `test/modules/hr/hr_screens_test.dart` (4، Widget، عبر `AppPages` الحقيقية):
  - المدخل ← البصمة: `Get.currentRoute`، والمتحكم يُنشأ مرة ويُحذف عند الرجوع، وطلب واحد رغم إعادة البناء كل ثانية.
  - حضوري: علامة «متأخر 17 د» وزرا الشهر السابق واللاحق.
  - إجازاتي: الرصيد ونص تحذير LWP.
  - حسابي: الاسم.

**مقارنة الواجهة:** 18 صنف عرض متطابقة مع الأصل بعد تجاهل التنسيق. الفرقان الوحيدان مقصودان: `context.read` ← `Get.find` في `_LeaveFormState` و`_RequestFormState`.

**لم يُنفَّذ:** اختبار يدوي على جهاز، وبصمة فعلية على ERPNext. لا يوجد اتصال بالخادم من بيئة التطوير.
