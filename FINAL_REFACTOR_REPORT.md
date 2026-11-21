# FINAL_REFACTOR_REPORT — إعادة الهيكلة إلى GetX (R1–R7)

**الفرع:** `refactor/getx-architecture`. **لا push ولا دمج مع main.**

## الهدف والقاعدة
- **الهدف:** تطبيق Flutter/ERPNext منظم بـ GetX (View ← Controller ← Repository ← ApiClient) **دون ميزات جديدة ودون تغيير السلوك**.
- **القاعدة في كل مرحلة:** فحص أولًا، ثم نقل الكود حرفيًا حيث أمكن، ثم format وanalyze وtest، ثم commit مستقل.

## المراحل
| المرحلة | ما أُنجز | الاختبارات بعدها |
|---|---|---|
| R1 `c92ca8c` | GetMaterialApp وGetPage، SessionService دائم، LoginController، InitialBinding (نفس كائنات main)، AuthMiddleware/GuestMiddleware، محوّل AuthController لـ Provider | 22 |
| R2 `fb9bf00` | `modules/statement`: أول وحدة كاملة، FutureBuilder ← متحكمات، GetPageRoute بنفس توقيع `route()` | 31 |
| R3 `12c99df` | `modules/invoices` و`modules/collections`: قُسم repository الفواتير/الدفعات، وتحصيلات العميل خرجت من CustomerDetailsController | 56 |
| R4 `7dacbef` | الرصيد الجاري دالة نقية (مطابق للحساب القديم على 6000 صف)، وGL Entries على GetX | 74 |
| R5 `6dad1fc` | `modules/hr` الأساسية: قُسم ErpEmployeeRepository حرفيًا بسكربت، وتوقيت فلسطين مثبت باختبار | 101 |
| R6 `4af3586` | بقية HR، وحُذف ErpEmployeeRepository، وManagerMiddleware | 114 |
| R7 | GetX Translations (تكافؤ 1,447 نصًا)، 401/403 مركزي، SessionService، تنظيف | **124** |

## الأرقام
| المقياس | قبل | بعد |
|---|---|---|
| GetxController / ChangeNotifier | 12 / 27 | 28 / 16 |
| شاشات FutureBuilder | 9 | 2 |
| شاشات `Get.put` في initState | 11 | 6 (van_sales) |
| Bindings / GetPage | 0 / 0 | 23 / 15 |
| ErpEmployeeRepository | 799 سطرًا لكل HR | محذوف ← 9 repositories + HrEmployeeIdentity |
| النصوص | `_t(ar, en)` في 9 أصناف | `ar.dart` و`en.dart` (GetX Translations) |
| الاختبارات الآلية | 2 (ملف واحد) | 124 |
| `flutter analyze` | 25 info | 23 info (لا errors ولا warnings) |

## ما لم يتغير (مقصود ومثبت)
- endpoints وmethods وpayloads وأسماء الحقول. كل طلب مرحّل مختبر على ErpApiClient حقيقي فوق MockClient.
- حساب المبالغ والرصيد الجاري ورفع الإيصال وقيم الرواتب من ERPNext.
- التطبيق لا يرسل `docstatus`، باستثناء «اعتماد» دفعة العميل، وهو سلوك موجود قبل البدء ولم يُغيَّر.
- النصوص ومعناها (تكافؤ آلي)، والتصميم: مقارنة آلية للـ widgets المنقولة.

## تغييرات سلوك مقصودة (كلها بطلب صريح وموثّقة)
1. **R7 401:** إنهاء مركزي مباشر.
2. **R7 403 مع تعذّر فحص الجلسة:** لا يُخرج المستخدم، وكان يُخرجه.
3. **R6 «فريقي»:** محمي بالمسار (ManagerMiddleware) لا بالإخفاء فقط.
4. **R3/R5/R6:** التنقل في الوحدات المرحّلة بمسارات GetX (`GetPageRoute` أو `Get.toNamed`) بنفس الانتقال (`Transition.native`).

## لم يُنجز
- **ترحيل `features/` الباقية:**
  - customers، orders (order + orders_section)، purchases، sales_returns، visits، warehouses، inventory، van_sales، settings، home، auth.
  - لذلك `modules/customers` و`modules/orders` غير موجودة.
  - فيها ما زال Provider وChangeNotifier، و`Get.put` في van_sales، وFutureBuilder في شاشتين.
- **`ErpConfig` static** ومستودع الفان المكتوب في الكود (مشكلة §9-5): لم يُعالج، لأن تغييره يغيّر الإعداد والسلوك.
- **اختبار الطلبيات المسودة** (إنشاء، تعديل، حذف): لا توجد اختبارات آلية لها. لم تُمس شاشاتها.
- **Integration ويدوي:**
  - لم يُنفَّذ أي اختبار على ERPNext حقيقي ولا على جهاز أو محاكي في أي مرحلة.
  - الاختبار اليدوي لـ R1 (تبديل اللغة، الدخول/الخروج، انتهاء الجلسة) ما زال مطلوبًا.

## المطلوب قبل الدمج
1. تشغيل التطبيق على جهاز واتباع بنود `M ⛔` في REGRESSION_CHECKLIST.md.
2. مطابقة الرصيد الختامي لكشف عميل مع General Ledger في ERPNext.
3. بصمة حضور وانصراف حقيقية، والتأكد من الوقت في ERPNext.
4. طلب مصروف بصورة إيصال من الكاميرا.
5. مراجعة تغيير 401/403 مع مسؤول الخادم.
