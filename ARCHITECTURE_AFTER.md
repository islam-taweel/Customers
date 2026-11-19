# ARCHITECTURE_AFTER — الهيكلية بعد إعادة البناء (يُحدَّث بعد كل خطوة)

> المرجع السابق: [ARCHITECTURE_BEFORE.md](ARCHITECTURE_BEFORE.md).
> سجل الخطوات والاختبارات: [PROMPTS.md](PROMPTS.md).

## حالة الترحيل

| المرحلة | الحالة | Commit |
|---|---|---|
| R1: GetMaterialApp + SessionService + LoginController + Bindings + Middleware | ✅ مكتمل | `c92ca8c` |
| R2.1: وحدة `statement` (كشف حساب العملاء + تفاصيل المستند) | ✅ مكتمل | هذا الـ commit |
| R2.x: بقية الوحدات | ⏳ بانتظار الموافقة | — |

## البنية المستهدفة لكل Feature

```
lib/modules/<feature>/
  bindings/      Get.lazyPut للمتحكمات (وسم tag عند تكدّس نفس الشاشة)
  controllers/   GetxController: حالة Rx + منطق، بلا BuildContext وبلا HTTP
  views/         Widgets: عرض فقط (Obx) + تنقل + حوارات تحتاج context
  repository/    الوصول للبيانات عبر ErpApiClient الوحيد
  models/        نماذج خاصة بالوحدة
```

تدفق الاعتماديات: **View → Controller → Repository → ErpApiClient** (واحد، مسجّل في InitialBinding).

## وحدة statement (مُرحَّلة)

```
lib/modules/statement/
  bindings/statement_bindings.dart
      StatementCustomersBinding   → StatementCustomersController
      CustomerStatementBinding    → CustomerStatementController   (tag لكل مسار)
      VoucherDetailsBinding       → VoucherDetailsController      (tag لكل مسار)
  controllers/
      statement_customers_controller.dart   العملاء، البحث (query + TextEditingController)، الخطأ
      customer_statement_controller.dart    الفترة (range)، الكشف، رسالة 403 «يحتاج دور محاسبة»
      voucher_details_controller.dart       المستند الخام (Map)
  views/
      customer_statement_list_view.dart     CustomerStatementListScreen (GetView)
      customer_statement_view.dart          CustomerStatementScreen (StatelessWidget + Obx)
      voucher_details_view.dart             VoucherDetailsScreen (StatelessWidget + Obx)
  repository/erp_statement_repository.dart  (نُقل كما هو، دون تغيير منطقي)
  models/statement_models.dart              (نُقل كما هو)
```

### كيف تعمل
- `ErpStatementRepository` يُنشأ **مرة واحدة** في `main()` ويُسجَّل دائمًا (`permanent`) في `InitialBinding`. لم يعد في `MultiProvider` (لا مستهلك له هناك).
- كل شاشة تُفتح بنفس الواجهة القديمة `X.route(...)`، لكنها تعيد الآن `GetPageRoute` مع `binding` و`Transition.native` (نفس انتقال `MaterialPageRoute`).
- الـ Binding يسجّل المتحكم بـ `lazyPut`، فيُنشأ عند أول `Get.find` في الشاشة، ويُحذف تلقائيًا (`onClose`) عند إغلاق مساره.
- شاشات المستند وكشف الحساب قد تتكدّس (دفعة ← فاتورة مخصصة)، فلكل مسار وسم فريد (`nextStatementTag`).
- كل متحكم يُهمل رد أي طلب أقدم من آخر طلب. هذا نفس سلوك FutureBuilder الذي كان يتابع أحدث Future فقط.
- منتقي التاريخ (`showDateRangePicker`) يبقى في الواجهة لأنه يحتاج context، والمتحكم يستلم الفترة المختارة فقط.

### نقاط الدخول القديمة (ما زالت تعمل دون تعديل)
| المستدعي | الاستدعاء |
|---|---|
| `lib/core/widgets/app_drawer.dart` | `CustomerStatementListScreen.route()` |
| `lib/features/customers/widgets/payments_tabs.dart` | `VoucherDetailsScreen.route('Payment Entry', name)` |

تغيّر سطر الـ import فقط في الملفين.

## ما زال على الهيكلية القديمة
كل ما في `lib/features/*` عدا `auth` (R1) و`statement` (نُقلت إلى `lib/modules/statement`)، وكل الـ repositories الأخرى في `lib/data/repositories` عبر `MultiProvider`. المتحكمات الـ GetX الموجودة سابقًا في `employee_services` و`van_sales` تُنشأ بـ `Get.put` داخل `initState`، وستُنقل إلى Bindings عند ترحيل وحداتها.
