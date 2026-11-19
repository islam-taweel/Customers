# REGRESSION_CHECKLIST

**الرموز:**
- U = Unit test، W = Widget test، I = Integration test (ERPNext حقيقي)، M = اختبار يدوي على جهاز/محاكي.
- ✅ نُفّذ ونجح، ⛔ لم يُنفَّذ، — لا ينطبق.
- كل ✅ مربوط باختبار موجود في `test/` ويمر في `flutter test`.
- **لم يُنفَّذ أي I أو M في أي مرحلة:** لا يوجد اتصال فعلي بـ ERPNext ولا محاكي في بيئة التطوير.

| # | Check | R5 | R6 | R7 |
|---|---|---|---|---|
| 1 | Login and logout | U ✅ (login_controller، session_service، auth adapter)؛ M ⛔ | | |
| 2 | Session restoration | U ✅ (SessionService.init من التخزين)؛ M ⛔ | | |
| 3 | Session expired redirects to login | U ✅ (401/403 متزامن ← خروج واحد، AuthGate يتبع isAuthenticated)؛ W ⛔؛ M ⛔ | | |
| 4 | Create, edit and delete draft order | ⛔ لا توجد اختبارات آلية لهذه الشاشات (لم تُرحَّل ولم تُمس)؛ M ⛔ | | |
| 5 | Unpaid invoices list | U ✅، W ✅ (R3)؛ M ⛔ | | |
| 6 | Collection draft | U ✅، W ✅ (R3)؛ M ⛔ | | |
| 7 | Customer statement | U ✅، W ✅ (R2/R4)؛ M ⛔ | | |
| 8 | Running Balance matches ERPNext | U ✅ للمعادلة ومطابقة الحساب القديم (R4)؛ I ⛔ | | |
| 9 | Profile shows employee information | U ✅، W ✅ | | |
| 10 | Profile shows today's shift | U ✅ (Shift Assignment ← Shift Type) | | |
| 11 | Punch In | U ✅ (الطلب والحقول)؛ W ✅ (الشاشة)؛ I ⛔ | | |
| 12 | Punch Out | U ✅؛ I ⛔ | | |
| 13 | Punch uses Palestine time correctly | U ✅ (Asia/Gaza ‎+2/+3، الصيغة، القيمة المرسلة حرفيًا)؛ M ⛔ | | |
| 14 | Attendance month view | U ✅، W ✅ (شهر سابق ولاحق) | | |
| 15 | Late entry marks | U ✅ (17 د)، W ✅ (العلامة ظاهرة) | | |
| 16 | Leave request | U ✅ (Open + المعتمِد + الحقول)؛ I ⛔ | | |
| 17 | Leave balance | U ✅، W ✅ | | |
| 18 | LWP warning | U ✅، W ✅ | | |
| 19 | Advance request | ⛔ (R6) | | |
| 20 | Expense Claim | ⛔ (R6) | | |
| 21 | Receipt photo upload | ⛔ (R6) | | |
| 22 | Payslip Earnings | ⛔ (R6) | | |
| 23 | Payslip Deductions | ⛔ (R6) | | |
| 24 | Payslip Net Pay | ⛔ (R6) | | |
| 25 | My Team authorization | ⛔ (R6) | | |
| 26 | Arabic RTL | ⛔ (R7) | | |
| 27 | English LTR | ⛔ (R7) | | |
| 28 | Language switching | ⛔ (R7) | | |
| 29 | No internet error handling | U ✅ (البصمة، الحساب، الإجازات + R3/R4) | | |
| 30 | 403 does not log out | U ✅ (erp_api_client_session_test)، U ✅ (HR: 403 ← noPermission) | | |
| 31 | 401 handles session expiry | U ✅ (erp_api_client_session_test) | | |
| 32 | No duplicate API calls | U ✅، W ✅ (البصمة طلب واحد رغم إعادة البناء كل ثانية؛ نفس الشهر لا يعيد الطلب) | | |
