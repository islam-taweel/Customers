# REGRESSION_CHECKLIST

**الرموز:**
- U = Unit test، W = Widget test، I = Integration test (ERPNext حقيقي)، M = اختبار يدوي على جهاز/محاكي.
- ✅ نُفّذ ونجح، ⛔ لم يُنفَّذ، — لا ينطبق.
- كل ✅ مربوط باختبار موجود في `test/` ويمر في `flutter test`.
- **لم يُنفَّذ أي I أو M في أي مرحلة:** لا يوجد اتصال فعلي بـ ERPNext ولا محاكي في بيئة التطوير.

| # | Check | R5 | R6 | R7 |
|---|---|---|---|---|
| 1 | Login and logout | U ✅ (login_controller، session_service، auth adapter)؛ M ⛔ | لم يتأثر: U ✅ | |
| 2 | Session restoration | U ✅ (SessionService.init من التخزين)؛ M ⛔ | لم يتأثر: U ✅ | |
| 3 | Session expired redirects to login | U ✅ (401/403 متزامن ← خروج واحد، AuthGate يتبع isAuthenticated)؛ W ⛔؛ M ⛔ | لم يتأثر: U ✅ | |
| 4 | Create, edit and delete draft order | ⛔ لا توجد اختبارات آلية لهذه الشاشات (لم تُرحَّل ولم تُمس)؛ M ⛔ | ⛔ لا اختبارات آلية (لم يُمسّ) | |
| 5 | Unpaid invoices list | U ✅، W ✅ (R3)؛ M ⛔ | لم يتأثر: U/W ✅ | |
| 6 | Collection draft | U ✅، W ✅ (R3)؛ M ⛔ | لم يتأثر: U/W ✅ | |
| 7 | Customer statement | U ✅، W ✅ (R2/R4)؛ M ⛔ | لم يتأثر: U/W ✅ | |
| 8 | Running Balance matches ERPNext | U ✅ للمعادلة ومطابقة الحساب القديم (R4)؛ I ⛔ | لم يتأثر: U ✅؛ I ⛔ | |
| 9 | Profile shows employee information | U ✅، W ✅ | لم يتأثر: U/W ✅ | |
| 10 | Profile shows today's shift | U ✅ (Shift Assignment ← Shift Type) | لم يتأثر: U ✅ | |
| 11 | Punch In | U ✅ (الطلب والحقول)؛ W ✅ (الشاشة)؛ I ⛔ | لم يتأثر: U/W ✅ | |
| 12 | Punch Out | U ✅؛ I ⛔ | لم يتأثر: U ✅ | |
| 13 | Punch uses Palestine time correctly | U ✅ (Asia/Gaza ‎+2/+3، الصيغة، القيمة المرسلة حرفيًا)؛ M ⛔ | لم يتأثر: U ✅؛ M ⛔ | |
| 14 | Attendance month view | U ✅، W ✅ (شهر سابق ولاحق) | لم يتأثر: U/W ✅ | |
| 15 | Late entry marks | U ✅ (17 د)، W ✅ (العلامة ظاهرة) | لم يتأثر: U/W ✅ | |
| 16 | Leave request | U ✅ (Open + المعتمِد + الحقول)؛ I ⛔ | لم يتأثر: U ✅ | |
| 17 | Leave balance | U ✅، W ✅ | لم يتأثر: U/W ✅ | |
| 18 | LWP warning | U ✅، W ✅ | لم يتأثر: U/W ✅ | |
| 19 | Advance request | ⛔ (R6) | U ✅ (القائمة، التحقق، المسودة بحقولها، رفض الخادم، الشبكة)؛ I ⛔؛ M ⛔ | |
| 20 | Expense Claim | ⛔ (R6) | U ✅ (المطالبة مسودة ببندها، الأنواع، التحقق)؛ I ⛔؛ M ⛔ | |
| 21 | Receipt photo upload | ⛔ (R6) | U ✅ (upload_file multipart بالمستند والاسم؛ فشل 413 ← المطالبة محفوظة + تحذير)؛ M ⛔ (اختيار صورة فعلية) | |
| 22 | Payslip Earnings | ⛔ (R6) | U ✅، W ✅ (3,250.50 ₪ كما من ERPNext) | |
| 23 | Payslip Deductions | ⛔ (R6) | U ✅، W ✅ («ضريبة الدخل» 120 ₪) | |
| 24 | Payslip Net Pay | ⛔ (R6) | U ✅، W ✅ (3,130.50 ₪) | |
| 25 | My Team authorization | ⛔ (R6) | U ✅ (الأدوار، فلترة المعتمِد)؛ W ✅ (غير المعتمِد ← /hr بـ ManagerMiddleware؛ المعتمِد يدخل؛ الخروج يمسح الصلاحية)؛ M ⛔ | |
| 26 | Arabic RTL | ⛔ (R7) | ⛔ (R7) | |
| 27 | English LTR | ⛔ (R7) | ⛔ (R7) | |
| 28 | Language switching | ⛔ (R7) | ⛔ (R7) | |
| 29 | No internet error handling | U ✅ (البصمة، الحساب، الإجازات + R3/R4) | U ✅ (+ السلف والمصاريف) | |
| 30 | 403 does not log out | U ✅ (erp_api_client_session_test)، U ✅ (HR: 403 ← noPermission) | لم يتأثر: U ✅ | |
| 31 | 401 handles session expiry | U ✅ (erp_api_client_session_test) | لم يتأثر: U ✅ | |
| 32 | No duplicate API calls | U ✅، W ✅ (البصمة طلب واحد رغم إعادة البناء كل ثانية؛ نفس الشهر لا يعيد الطلب) | U/W ✅ (فريقي: طلب واحد للإجازات) | |
