# REGRESSION_CHECKLIST

**الرموز:**
- U = Unit test، W = Widget test، I = Integration test (ERPNext حقيقي)، M = اختبار يدوي على جهاز/محاكي.
- ✅ نُفّذ ونجح، ⛔ لم يُنفَّذ، — لا ينطبق.
- كل ✅ مربوط باختبار موجود في `test/` ويمر في `flutter test`.
- **لم يُنفَّذ أي I أو M في أي مرحلة:** لا يوجد اتصال فعلي بـ ERPNext ولا محاكي في بيئة التطوير.

| # | Check | R5 | R6 | R7 |
|---|---|---|---|---|
| 1 | Login and logout | U ✅ (login_controller، session_service، auth adapter)؛ M ⛔ | لم يتأثر: U ✅ | U ✅ (login_controller، session_service)؛ M ⛔ |
| 2 | Session restoration | U ✅ (SessionService.init من التخزين)؛ M ⛔ | لم يتأثر: U ✅ | U ✅؛ M ⛔ |
| 3 | Session expired redirects to login | U ✅ (401/403 متزامن ← خروج واحد، AuthGate يتبع isAuthenticated)؛ W ⛔؛ M ⛔ | لم يتأثر: U ✅ | U ✅ (401 مركزي: خروج واحد؛ 403 Guest: خروج واحد)؛ M ⛔ |
| 4 | Create, edit and delete draft order | ⛔ لا توجد اختبارات آلية لهذه الشاشات (لم تُرحَّل ولم تُمس)؛ M ⛔ | ⛔ لا اختبارات آلية (لم يُمسّ) | ⛔ لا اختبارات آلية (لم يُمسّ)؛ M ⛔ |
| 5 | Unpaid invoices list | U ✅، W ✅ (R3)؛ M ⛔ | لم يتأثر: U/W ✅ | U/W ✅ (بالترجمات)؛ M ⛔ |
| 6 | Collection draft | U ✅، W ✅ (R3)؛ M ⛔ | لم يتأثر: U/W ✅ | U/W ✅؛ M ⛔ |
| 7 | Customer statement | U ✅، W ✅ (R2/R4)؛ M ⛔ | لم يتأثر: U/W ✅ | U/W ✅؛ M ⛔ |
| 8 | Running Balance matches ERPNext | U ✅ للمعادلة ومطابقة الحساب القديم (R4)؛ I ⛔ | لم يتأثر: U ✅؛ I ⛔ | U ✅ للمعادلة؛ I ⛔ |
| 9 | Profile shows employee information | U ✅، W ✅ | لم يتأثر: U/W ✅ | U/W ✅ (+ هوية الموظف في SessionService) |
| 10 | Profile shows today's shift | U ✅ (Shift Assignment ← Shift Type) | لم يتأثر: U ✅ | U ✅ |
| 11 | Punch In | U ✅ (الطلب والحقول)؛ W ✅ (الشاشة)؛ I ⛔ | لم يتأثر: U/W ✅ | U/W ✅؛ I ⛔ |
| 12 | Punch Out | U ✅؛ I ⛔ | لم يتأثر: U ✅ | U ✅؛ I ⛔ |
| 13 | Punch uses Palestine time correctly | U ✅ (Asia/Gaza ‎+2/+3، الصيغة، القيمة المرسلة حرفيًا)؛ M ⛔ | لم يتأثر: U ✅؛ M ⛔ | U ✅؛ M ⛔ |
| 14 | Attendance month view | U ✅، W ✅ (شهر سابق ولاحق) | لم يتأثر: U/W ✅ | U/W ✅ |
| 15 | Late entry marks | U ✅ (17 د)، W ✅ (العلامة ظاهرة) | لم يتأثر: U/W ✅ | U/W ✅ |
| 16 | Leave request | U ✅ (Open + المعتمِد + الحقول)؛ I ⛔ | لم يتأثر: U ✅ | U ✅؛ I ⛔ |
| 17 | Leave balance | U ✅، W ✅ | لم يتأثر: U/W ✅ | U/W ✅ |
| 18 | LWP warning | U ✅، W ✅ | لم يتأثر: U/W ✅ | U/W ✅ |
| 19 | Advance request | ⛔ (R6) | U ✅ (القائمة، التحقق، المسودة بحقولها، رفض الخادم، الشبكة)؛ I ⛔؛ M ⛔ | U ✅؛ I ⛔ |
| 20 | Expense Claim | ⛔ (R6) | U ✅ (المطالبة مسودة ببندها، الأنواع، التحقق)؛ I ⛔؛ M ⛔ | U ✅؛ I ⛔ |
| 21 | Receipt photo upload | ⛔ (R6) | U ✅ (upload_file multipart بالمستند والاسم؛ فشل 413 ← المطالبة محفوظة + تحذير)؛ M ⛔ (اختيار صورة فعلية) | U ✅؛ M ⛔ |
| 22 | Payslip Earnings | ⛔ (R6) | U ✅، W ✅ (3,250.50 ₪ كما من ERPNext) | U/W ✅ |
| 23 | Payslip Deductions | ⛔ (R6) | U ✅، W ✅ («ضريبة الدخل» 120 ₪) | U/W ✅ |
| 24 | Payslip Net Pay | ⛔ (R6) | U ✅، W ✅ (3,130.50 ₪) | U/W ✅ |
| 25 | My Team authorization | ⛔ (R6) | U ✅ (الأدوار، فلترة المعتمِد)؛ W ✅ (غير المعتمِد ← /hr بـ ManagerMiddleware؛ المعتمِد يدخل؛ الخروج يمسح الصلاحية)؛ M ⛔ | U/W ✅؛ M ⛔ |
| 26 | Arabic RTL | ⛔ (R7) | ⛔ (R7) | W ✅ (العربية افتراضيًا، Directionality = RTL، نصوص عربية)؛ U ✅ (تكافؤ 1,447 نصًا)؛ M ⛔ |
| 27 | English LTR | ⛔ (R7) | ⛔ (R7) | W ✅ (Directionality = LTR، نصوص إنجليزية)؛ U ✅ (تكافؤ بالإنجليزية)؛ M ⛔ |
| 28 | Language switching | ⛔ (R7) | ⛔ (R7) | W ✅ (تبديل أثناء التشغيل بلا إعادة تشغيل، وحفظ الاختيار واستعادته)؛ M ⛔ |
| 29 | No internet error handling | U ✅ (البصمة، الحساب، الإجازات + R3/R4) | U ✅ (+ السلف والمصاريف) | U ✅ |
| 30 | 403 does not log out | U ✅ (erp_api_client_session_test)، U ✅ (HR: 403 ← noPermission) | لم يتأثر: U ✅ | U ✅ (403 حقيقي، و403 مع تعذّر الفحص: لا مسح ولا خروج) |
| 31 | 401 handles session expiry | U ✅ (erp_api_client_session_test) | لم يتأثر: U ✅ | U ✅ (401 متزامن ← خروج واحد بلا فحص؛ دخول جديد لا يُحذف) |
| 32 | No duplicate API calls | U ✅، W ✅ (البصمة طلب واحد رغم إعادة البناء كل ثانية؛ نفس الشهر لا يعيد الطلب) | U/W ✅ (فريقي: طلب واحد للإجازات) | U/W ✅ |

## ملاحظات R7
- **عمود R7 نُفّذ بعد تفعيل الترجمات:** `test/flutter_test_config.dart` يحمّل ترجمات التطبيق قبل كل اختبار، فكل نص في الاختبارات هو النص الحقيقي لا المفتاح.
- **تغيير مقصود في 401/403** (البنود 3 و30 و31): التفاصيل في R7_REPORT.md §4.
- **التشغيل الفعلي (Final Technical Verification):**
  - **لم يُشغَّل التطبيق على محاكي أو جهاز،** ولم يُتصل بـ ERPNext: غير متوفرين في بيئة التطوير.
  - لذلك كل بنود M وI ⛔، ويجب تنفيذها قبل الدمج.
