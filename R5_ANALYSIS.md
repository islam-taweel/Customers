# R5_ANALYSIS — فحص وحدات HR الأساسية قبل التعديل

> الحالة عند الفحص: الفرع `refactor/getx-architecture`، آخر commit هو `7dacbef` (R4). لم يُعدَّل أي ملف قبل كتابة هذا التقرير.

## 1. الشاشات الموجودة فعليًا (`lib/features/employee_services`)

| الخدمة (enum `EmployeeService`) | الشاشة | إدارة الحالة اليوم | الأسطر |
|---|---|---|---|
| profile «حسابي» | `MyAccountScreen` | FutureBuilder + `context.read<ErpEmployeeRepository>()`، وصورة الموظف FutureBuilder ثانٍ | 328 |
| checkin «البصمة» | `CheckinScreen` | `CheckinController extends ChangeNotifier` عبر ChangeNotifierProvider، وساعة `Timer` كل ثانية في الواجهة | 460 + 125 |
| attendance «حضوري» | `AttendanceLogScreen` | FutureBuilder، والشهر والسنة في State | 412 |
| correction «نسيت البصمة» | `AttendanceCorrectionScreen` | `CorrectionController extends ChangeNotifier` | 553 + 119 |
| leaves «إجازاتي» | `LeavesScreen` | `LeavesController extends ChangeNotifier` | 716 + 209 |
| overtime «عملي الإضافي» | `OvertimeScreen` | FutureBuilder | 625 |
| advances «سلفي» | `AdvancesScreen` | `AdvancesController` (GetX)، يُنشأ بـ `Get.put` في initState | 506 + 82 |
| expenses «مصاريفي» | `ExpensesScreen` | `ExpensesController` (GetX)، `Get.put` في initState | 708 + 139 |
| payslips «كشوف رواتبي» | `PayslipsScreen` و`PayslipDetailScreen` | `PayslipsController` و`PayslipDetailController` (GetX)، `Get.put` | 223 + 478 + 69 |
| team «فريقي» | `TeamScreen` | `TeamController` (GetX)، `Get.put` | 361 + 89 |
| (المدخل) | `EmployeeServicesScreen` | `HrAccessController` (GetX)، `Get.put` في initState | 188 |

**ملاحظات:**
- المطلوب في R5 هو Profile وPunch وAttendance وLeaves. «Punch» في المشروع هي شاشة `CheckinScreen`.
- «نسيت البصمة» (Attendance Request) موجودة وتخص الحضور، فتُرحَّل مع Attendance.
- «عملي الإضافي» موجودة ولم تُذكر في القائمة، فتُرحَّل في R6 حتى لا يبقى repository قديم.

## 2. Repository وModels
- **`ErpEmployeeRepository` (799 سطرًا):** واحد لكل HR، في `lib/data/repositories/`.
  - يُنشأ مرة واحدة في `main.dart:215`، ويُقدَّم عبر `Provider<ErpEmployeeRepository>`.
  - لا يستخدمه أي جزء خارج `employee_services`.
- **مساعدات الهوية مشتركة بين كل الأقسام:**
  - `_currentEmployee`: يستدعي `hrms.api.get_current_employee_info`، ورد فارغ يرمي `EmployeeNotLinkedException`.
  - `_employeeRow(fields)`: يقرأ من Employee ما ينقص.
  - `_employeeId`، `_userInfo`، `_loggedUser`، `_companyOf`، `_num`.
  - كلها **بلا حالة**: كل استدعاء يطلب من الخادم من جديد.
- **حالة مخزّنة واحدة فقط:** `_overtimeSupport` (نتيجة فحص Overtime Slip تُحفظ لبقية الجلسة). لذلك يجب أن يبقى repository العمل الإضافي كائنًا واحدًا دائمًا.
- **Models في `lib/data/models/`:**

  | الملف | الأصناف | المستخدم |
  |---|---|---|
  | `employee_models.dart` | EmployeeProfile، EmployeeShift، EmployeeCheckin | Profile وPunch |
  | `attendance_models.dart` | AttendanceRecord، AttendanceSummary، AttendanceRequestRecord، AttendanceStatus | Attendance |
  | `leave_models.dart` | LeaveBalance، LeaveDetails، LeaveRequest | Leaves |
  | `advance_models.dart`، `expense_models.dart`، `payslip_models.dart`، `team_models.dart` | — | R6 |

  كلها مستخدمة من HR فقط.

## 3. API endpoints (لن تتغير)

| الوحدة | الطلبات |
|---|---|
| Profile | `GET hrms.api.get_current_employee_info` ← `Employee` (الحقول الناقصة) ← `Shift Assignment` (Active، `start_date <= اليوم`، `end_date >= اليوم` أو غير محدد، الأحدث) ← `GET Shift Type/<name>`. الصورة عبر `downloadFile(path)` بكوكي الجلسة |
| Punch | `Employee Checkin` لليوم (`time >= اليوم 00:00:00`، `< الغد 00:00:00`، `time asc`). `POST Employee Checkin {employee, log_type: IN/OUT, time}` |
| Attendance | `Attendance` للشهر + `Shift Type` للتأخير والخروج المبكر. `POST Attendance Request` (مسودة)، وقائمة طلباتي |
| Leaves | `get_leave_details` + `Leave Type (is_lwp)` + `Leave Application` + `get_number_of_leave_days` + `get_leave_approver` ← `POST Leave Application (status Open)` |

## 4. حفظ وعرض بيانات الموظف
- لا يُحفظ شيء من بيانات الموظف على الجهاز: كل شاشة تجلبها عند فتحها.
- الموظف يُعرف من الجلسة الحالية في الخادم (`get_current_employee_info`)، لا من أي قيمة محلية.
- `SessionService` يحمل الاسم الكامل فقط (من R1).

## 5. التاريخ والوقت
- **`PalestineTime`** (`lib/core/utils/palestine_time.dart`):
  - يعتمد قاعدة `timezone` بالمنطقة **Asia/Gaza** (UTC+2 شتاءً وUTC+3 صيفًا، والتوقيت الصيفي من القاعدة).
  - `init()` يُستدعى مرة واحدة في main.
  - `now()` يعيد قيم «جدار» بتوقيت فلسطين في `DateTime` محلي عادي، بلا UTC.
  - `format()` بصيغة `YYYY-MM-DD HH:MM:SS` بلا Z ولا إزاحة.
- **البصمة:** `time = PalestineTime.format(PalestineTime.now())`. لا تحويل إلى UTC، ولا `toIso8601String`، فلا فرق ساعات.
- **العرض:** ساعة شاشة البصمة تتحدث كل ثانية من `PalestineTime.now()`. أوقات البصمات المعروضة هي قيم ERPNext نفسها، بتوقيت فلسطين.
- **ملاحظة (لن تتغير):** شاشة «حضوري» تبدأ بشهر `DateTime.now()` (وقت الجهاز). الفرق يظهر فقط إن كان الجهاز على منطقة زمنية أخرى في الساعات الأولى من الشهر.

## 6. صلاحيات المستخدم
- **«فريقي»:**
  - يظهر فقط لمن لديه دور Leave Approver أو Expense Approver، من `get_current_user_info` (`fetchApproverAccess`).
  - `HrAccessController` يفحص ذلك عند فتح المدخل، والبطاقة مخفية أثناء الفحص وعند فشله.
  - `TeamController` يعيد الفحص داخل الشاشة ويعرض «لا صلاحية» عند غيابها.
- **لا يوجد ManagerMiddleware.** الحماية اليوم بالإخفاء + فحص داخل الشاشة، والمسار غير محمي بـ Middleware.
- **التطبيق لا يرسل docstatus ولا يعتمد شيئًا:** كل الطلبات مسودات (Open أو Draft) تعتمدها الموارد البشرية في ERPNext.
- **403:** كل شاشة تحوّله إلى `EssStrings.noPermission`، و`EmployeeNotLinkedException` إلى `EssStrings.notLinked`. هذه الدالة `_message` مكررة في **كل** شاشة.

## 7. التنقلات
- `app_drawer.dart:46` يستدعي `EmployeeServicesScreen.route()` (MaterialPageRoute).
- المدخل ينتقل إلى كل خدمة بـ `Navigator.push(service.route)` (MaterialPageRoute على `EmployeeService.screen`).
- `PayslipsScreen` يفتح `PayslipDetailScreen` بـ MaterialPageRoute.
- لا توجد مسارات مسماة لـ HR.

## 8. الاعتماديات على Provider وGetX
- **Provider:** `ErpEmployeeRepository` (كل الشاشات بـ `context.read`)، وChangeNotifierProvider لثلاثة متحكمات (Checkin، Correction، Leaves).
- **GetX:** 7 متحكمات تُنشأ بـ `Get.put` داخل `initState` وتُحذف في `dispose`، بلا Bindings.
- **حالة إضافية في الواجهة:** `Timer` الساعة في البصمة، ومنتقيات التاريخ، و`TextEditingController` للنماذج.

## 9. الخطة (R5)
- **`lib/modules/hr/shared/`:**
  - `HrEmployeeIdentity`: مساعدات الهوية منقولة كما هي، كائن واحد.
  - `hrErrorMessage`: بديل `_message` المكررة.
  - `MonthYearPicker`: مشترك بين الحضور والعمل الإضافي.
- **repository لكل وحدة** بنقل الدوال حرفيًا: `profile`، `punch`، `attendance` (+ correction)، `leaves`. الجزء الباقي من `ErpEmployeeRepository` يبقى لوحدات R6 حتى ترحيلها، ويستخدم نفس `HrEmployeeIdentity`.
- **المتحكمات:**
  - Checkin وCorrection وLeaves تصبح GetxController + GetBuilder (`update()` بدل `notifyListeners`)، فيبقى نمط التحديث كما هو.
  - Profile وAttendance يصبحان GetxController + StateMixin (`controller.obx`).
- **Bindings** بـ `Get.lazyPut`، وGetPage مسماة لكل خدمة. المدخل ينتقل بـ `Get.toNamed`، والمدخل نفسه GetPageRoute مع `HrHomeBinding`.
- **الـ repositories** تُنشأ مرة واحدة في main وتُسجَّل في `InitialBinding`.
