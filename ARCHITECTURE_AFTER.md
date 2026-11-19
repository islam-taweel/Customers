# ARCHITECTURE_AFTER — الهيكلية بعد إعادة البناء (يُحدَّث بعد كل خطوة)

> المرجع السابق: [ARCHITECTURE_BEFORE.md](ARCHITECTURE_BEFORE.md).
> سجل الخطوات والاختبارات: [PROMPTS.md](PROMPTS.md).

## حالة الترحيل

| المرحلة | الحالة | Commit |
|---|---|---|
| R1: GetMaterialApp + SessionService + LoginController + Bindings + Middleware | ✅ مكتمل | `c92ca8c` |
| R2.1: وحدة `statement` (كشف حساب العملاء + تفاصيل المستند) | ✅ مكتمل | `fb9bf00` |
| R3: وحدتا `invoices` و`collections` | ✅ مكتمل | `12c99df` |
| R4: `statement` — الرصيد الجاري + القيود المحاسبية (GL Entries) | ✅ مكتمل | `refactor: migrate customer statement and GL entries to GetX` |

## البنية المستهدفة لكل Feature

```
lib/modules/<feature>/
  bindings/      Get.lazyPut للمتحكمات (وسم tag عند تكدّس نفس الشاشة)
  controllers/   GetxController: حالة Rx + منطق، بلا BuildContext وبلا HTTP
  views/         شاشات كاملة: عرض فقط (Obx) + تنقل + حوارات تحتاج context
  widgets/       أجزاء واجهة تُستخدم داخل الشاشات (بطاقات، نوافذ، تبويبات)
  repository/    الوصول للبيانات عبر ErpApiClient الوحيد
  models/        نماذج خاصة بالوحدة
```

**تدفق الاعتماديات:**

```
View / Widget ──Obx──▶ Controller (GetxController) ──▶ Repository ──▶ ErpApiClient (واحد)
      │                        ▲                            ▲
      │ Get.find(tag)          │ Get.lazyPut (Binding       │ Get.put(permanent) في
      ▼                        │  على GetPageRoute)         │ InitialBinding = نفس كائن main()
 Navigator / حوارات            │
```

- كل الـ repositories تُنشأ **مرة واحدة** في `main()`. ما يستخدمه GetX يُسجَّل بنفس الكائن في `InitialBinding` (`_putOnce` يمنع التسجيل المكرر).
- المتحكم يُنشأ عند أول `Get.find` في شاشته (lazyPut)، ويُحذف تلقائيًا عند إغلاق مساره (`GetPageRoute`). النوافذ السفلية تحذف متحكمها في `dispose`.
- ما زال `MultiProvider` يقدّم الـ repositories التي لها مستهلكون قدامى، وهو نفس الكائن.

## وحدة invoices (R3)

```
lib/modules/invoices/
  bindings/invoices_bindings.dart
      SalesInvoicesBinding        → SalesInvoicesController        (مع مسار «الطلبات»)
      InvoiceDetailsBinding       → InvoiceDetailsController       (tag لكل مسار)
  controllers/
      sales_invoices_controller.dart    القائمة: التبويبات، النسخة المحلية، التنبيه، reload
      invoice_details_controller.dart   تفاصيل فاتورة (محفوظ ثم ERPNext)، PDF، زر القيود
  views/
      invoices_tabs_view.dart           InvoicesTabsView: مسودة / غير مدفوعة / جزئيًا / مدفوعة
      invoice_details_view.dart         InvoiceDetailsScreen
  widgets/sales_invoice_card.dart       بطاقة الفاتورة: دفع، طباعة، إرجاع للتعديل، القيود
  repository/sales_invoices_repository.dart   ErpSalesInvoicesRepository: الجلب + النسخة المحلية + PDF
  models/sales_invoices_result.dart
```

## وحدة collections (R3)

```
lib/modules/collections/
  bindings/collections_bindings.dart
      InvoiceCollectionsBinding   → InvoiceCollectionsController   (مع مسار «الطلبات»)
      PaymentSheetBinding         → PaymentSheetController         (tag لكل نافذة دفع)
      CustomerCollectionsBinding  → CustomerCollectionsController  (tag لمسار «العمليات»)
  controllers/
      invoice_collections_controller.dart   مسودات التحصيل المعلّقة على الفواتير + pay()
      payment_sheet_controller.dart         نموذج «دفع فاتورة»: طرق الدفع، التحقق، الحفظ
      customer_collections_controller.dart  مسودات/معتمدة العميل: تحميل، اعتماد، حذف
  widgets/
      payment_sheet.dart                    showPaymentSheet(context, invoice:)
      payments_tabs.dart                    PaymentsTabs(tag:) تحت «إضافة دفعة»
  repository/
      invoice_collections_repository.dart   ErpInvoiceCollectionsRepository: get_payment_entry ← مسودة
      erp_payment_repository.dart           ErpPaymentRepository (نُقل كما هو)
  models/
      collection_models.dart                PendingPayment، PaymentDetails
      payment_entry.dart                    PaymentEntrySummary (نُقل كما هو)
```

### الفصل بين الفواتير والتحصيلات
- `ErpSalesInvoicesRepository` القديم كان يجمع الأمرين، فقُسِّم إلى جزأين:
  - **invoices:** قراءة الفواتير والنسخة المحلية وPDF.
  - **collections:** حفظ مسودة الدفع والدفعات المعلّقة.
- الكود نُقل كما هو: نفس الطلبات، ونفس مفاتيح النسخة المحلية (`sales_invoices:all` و`sales_invoices:pending_payments`). لا يوجد كود مكرر.
- `SalesInvoicesController` يأخذ `InvoiceCollectionsController` (نفس المسار)، فيستدعي `loadPending` عند الفتح و`reconcile` بعد كل جلب ناجح، كما كان.
- `CustomerCollectionsController` لا يعرف قاعدة البيانات المحلية. يصل إلى العميل عبر واجهة `CustomerCollectionsHost` التي يطبّقها `CustomerDetailsController`:
  - `erpId()`
  - `recordApprovedPayment(doc)`: تسجيل الدفعة محليًا ثم تحديث الرصيد، نفس منطق `approvePayment` السابق.
  - مستمع «حُفظت مسودة»: بديل `unawaited(loadPayments())`، في نفس الموضع.

### المشكلات التي عولجت في R3
- منطق التحقق والحفظ في نافذة الدفع كان داخل `State` (setState)، وصار في متحكم قابل للاختبار. حقول النص (`TextEditingController`) بقيت في الواجهة وتُحذف معها.
- `CustomerDetailsController` (651 سطرًا) كان يحمل حالة دفعات ERPNext أيضًا، فانتقلت إلى متحكم مستقل.
- `SalesInvoicesController` كان يُنشأ عبر Factory في MultiProvider، وأُزيل المصنع ومزوّده (لم يبقَ مستهلك).
- `refresh()` في المتحكم صار اسمه `reload()`، لأن `refresh` اسم محجوز في GetxController يستدعيه `update()`.

### نقاط الدخول القديمة (التوقيع نفسه)
| المستدعي | الاستدعاء |
|---|---|
| `app_drawer.dart` | `OrdersScreen.route()` ← صار GetPageRoute مع `[InvoiceCollectionsBinding, SalesInvoicesBinding]` |
| `customer_details_screen.dart` | `CustomerOperationsScreen.route(controller)` ← GetPageRoute مع `CustomerCollectionsBinding` |
| `customer_invoices_screen.dart`، `invoice_tab.dart` | `InvoiceDetailsScreen.route(details.openInvoice(...))` |
| `delivery_tile.dart` | `Get.find<SalesInvoicesController>().reload()` بعد الفوترة |

## وحدة statement (R2 + R4)

```
lib/modules/statement/
  bindings/statement_bindings.dart
      StatementCustomersBinding   → StatementCustomersController
      CustomerStatementBinding    → CustomerStatementController   (tag)
      VoucherDetailsBinding       → VoucherDetailsController      (tag)
      GlEntriesBinding            → GlEntriesController           (tag) ← R4
  controllers/
      statement_customers_controller.dart   العملاء + البحث (تصفية محلية)
      customer_statement_controller.dart    الفترة + الكشف + رسالة 403
      voucher_details_controller.dart       المستند الخام
      gl_entries_controller.dart            ← R4: القيود لفاتورة/طلبية، الخطأ، رسالة المسودات
  views/
      customer_statement_list_view.dart     CustomerStatementListScreen
      customer_statement_view.dart          CustomerStatementScreen
      voucher_details_view.dart             VoucherDetailsScreen
      gl_entries_view.dart                  ← R4: GlEntriesScreen.forInvoice / forOrder
  widgets/                                  ← R4: أجزاء العرض نُقلت كما هي
      statement_summary.dart                StatementSummary، StatementLineTile
      gl_ledger_table.dart                  GlLedgerTable، GlTotals
  repository/
      erp_statement_repository.dart         GL Entry + get_balance_on
      erp_ledger_repository.dart            ← R4 (نُقل): Payment Ledger Entry (احتياط GL Entry)، orderInvoices
  models/
      statement_models.dart                 StatementLine، CustomerStatement (+ fromGlRows ← R4)
      gl_entry.dart                         ← R4 (نُقل): CustomerLedgerLine، CustomerLedger
```

### الرصيد الجاري (R4)
- **المصدر:**
  - حركات GL Entry على حساب العميل، بترتيب ERPNext (`posting_date asc, creation asc`). التطبيق لا يعيد ترتيبها.
  - الرصيد الافتتاحي من ERPNext (`get_balance_on` لليوم السابق لبداية الفترة)، أو 0 دون فترة.
- **المعادلة (لم تتغير):** `الرصيد = الافتتاحي + Σ (مدين − دائن)` سطرًا بسطر. الختامي = آخر رصيد، أو الافتتاحي إن لم توجد حركات.
- الحلقة نفسها نُقلت من `ErpStatementRepository.fetchStatement` إلى `CustomerStatement.fromGlRows`، وهي دالة نقية بلا شبكة. الـ repository يستدعيها كما كان يستدعي الحلقة، ولا Widget يحسب رصيدًا.
- **القيود لفاتورة (GL Entries):** المجاميع والتوازن والفرق في `CustomerLedger`، كما كانت.

### البحث
- البحث الوحيد في كشف الحساب هو قائمة العملاء، وهو تصفية محلية على قائمة محمّلة، بلا طلب شبكة.
- لذلك لم يُضف `debounce`: لا يوجد طلب يُوفَّر، والتأخير سيغيّر سلوك الكتابة الحالي.

### نقاط الدخول (التوقيع نفسه)
| المستدعي | الاستدعاء |
|---|---|
| `sales_invoice_card.dart`، `invoice_details_view.dart` | `GlEntriesScreen.forInvoice(name)` / `forOrder(id)` |
| `order_details_screen.dart` | `GlEntriesScreen.forOrder(id)`؛ و`context.read<ErpLedgerRepository>().orderInvoices` (Provider: نفس الكائن المسجّل في GetX) |
| `app_drawer.dart`، `payments_tabs.dart` | `CustomerStatementListScreen.route()`، `VoucherDetailsScreen.route(...)` |

## ما لم تتم إعادة هيكلته بعد
- **في customers:**
  - CustomerScreen وCustomerDetailsScreen ومتحكماتها (ChangeNotifier).
  - فواتير العميل (`CustomerInvoicesScreen` و`CustomerInvoicesController`).
  - مسودات الطلبيات (`DraftInvoiceController` و`EditDraftScreen`): مسودة Sales Order، وليست مسودة تحصيل.
  - نافذة «إضافة دفعة» (`OperationDialog`) و`addOperation`: إنشاء مسودة تحصيل العميل باقٍ في `CustomerDetailsController`، لأنه نفس مسار الديون والدفعات المحلية.
- **في orders_section:** الطلبيات والتسليمات (`OrdersController`، Provider)، و`OrderDetailsScreen` (FutureBuilder على `orderInvoices`).
- **وحدات أخرى:** purchases وsales_returns وvisits وwarehouses وinventory وvan_sales وemployee_services.
- **تعديل مسودة التحصيل:** غير موجود في المشروع أصلًا، فلا يوجد شيء يُرحَّل.
