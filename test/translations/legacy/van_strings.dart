// مُولَّد: نسخة نصوص قبل R7 (مرجع اختبار التكافؤ). لا تُعدَّل يدويًا.
// ignore_for_file: type=lint, unused_import
import 'legacy_lang.dart';
import 'app_strings.dart';

/// نصوص قسم «مبيعات الفان» (عربي/إنجليزي). اللغة الحالية من [LegacyLang.isArabic].
class LegacyVanStrings {
  LegacyVanStrings._();

  static String _t(String ar, String en) => LegacyLang.isArabic ? ar : en;

  static String get section => _t('مبيعات الفان', 'Van sales');
  static String get stockTitle => _t('مخزون الفان', 'Van stock');
  static String get loading =>
      _t('جارٍ تحميل مخزون الفان...', 'Loading van stock...');
  static String get loadFailed =>
      _t('تعذّر تحميل مخزون الفان', 'Could not load the van stock');
  static String get searchHint =>
      _t('ابحث باسم المنتج أو كوده', 'Search by product name or code');
  static String get scan => _t('مسح الباركود', 'Scan barcode');
  static String get empty =>
      _t('لا توجد منتجات في الفان', 'No products in the van');
  static String get emptyHint => _t(
    'يظهر هنا كل منتج كميته في مستودع الفان أكبر من صفر',
    'Every product with stock in the van warehouse shows up here',
  );
  static String get noMatch =>
      _t('لا يوجد منتج مطابق للبحث', 'No product matches the search');
  static String productsCount(int n) => _t('$n منتج', '$n products');
  static String get available => _t('الكمية المتوفرة', 'Available');
  static String get code => _t('الكود', 'Code');
  static String scanned(String code) =>
      _t('نتيجة المسح: $code', 'Scan result: $code');
  static String notInVan(String code) => _t(
    'الباركود $code لا يطابق أي منتج في مخزون الفان',
    'Barcode $code does not match any product in the van stock',
  );
  static String get scanFailed =>
      _t('تعذّر البحث عن الباركود', 'Could not look up the barcode');
  static String get clearScan => _t('إظهار الكل', 'Show all');

  // الأقسام
  static String get stockDesc =>
      _t('منتجات الفان وكمياتها', 'Products and quantities in the van');
  static String get newSale => _t('فاتورة بيع جديدة', 'New sale');
  static String get newSaleDesc => _t(
    'بيع من الفان مباشرة للعميل',
    'Sell straight from the van to a customer',
  );

  // العميل
  static String get customer => _t('العميل', 'Customer');
  static String get chooseCustomer => _t('اختر العميل', 'Choose a customer');
  static String get searchCustomer =>
      _t('ابحث بالاسم أو الرقم أو الهاتف', 'Search by name, ID or phone');
  static String get loadingCustomers =>
      _t('جارٍ تحميل العملاء...', 'Loading customers...');
  static String get noCustomers => _t('لا يوجد عملاء', 'No customers');
  static String get customersFailed =>
      _t('تعذّر تحميل العملاء', 'Could not load customers');

  // المنتجات
  static String get products => _t('المنتجات', 'Products');
  static String get addProduct => _t('إضافة منتج', 'Add product');
  static String get chooseProduct => _t('اختر المنتج', 'Choose a product');
  static String get noLines => _t(
    'لم تُضف منتجات بعد. ابحث عن منتج أو امسح الباركود.',
    'No products yet. Search for a product or scan its barcode.',
  );
  static String inVan(String qty) => _t('في الفان: $qty', 'In van: $qty');
  static String get unit => _t('وحدة البيع', 'Sales unit');
  static String unitFactor(String uom, String factor, String stockUom) =>
      _t('1 $uom = $factor $stockUom', '1 $uom = $factor $stockUom');
  static String get loadingUnits =>
      _t('جارٍ تحميل الوحدات...', 'Loading units...');
  static String get unitsFailed =>
      _t('تعذّر تحميل وحدات المنتج', 'Could not load the product units');
  static String get quantity => _t('الكمية', 'Quantity');
  static String get qtyPositive =>
      _t('الكمية يجب أن تكون أكبر من صفر', 'Quantity must be above 0');
  static String qtyWhole(String uom) =>
      _t('الوحدة $uom لا تقبل كسورًا', 'The unit $uom must be a whole number');
  static String qtyAboveStock(String available) => _t(
    'الكمية أكبر من المتوفر في الفان ($available)',
    'Quantity is above the van stock ($available)',
  );
  static String get estimatedPrice => _t('السعر التقديري', 'Estimated price');
  static String get noPrice => _t('لا يوجد سعر', 'No price');
  static String get add => _t('إضافة', 'Add');
  static String get update => _t('تحديث', 'Update');
  static String get remove => _t('حذف', 'Remove');
  static String get cancel => LegacyAppStrings.cancel;
  static String linesCount(int n) => _t('$n منتج', '$n products');

  // المراجعة والحفظ
  static String get review => _t('مراجعة الفاتورة', 'Review invoice');
  static String get reviewAndSave => _t('مراجعة وحفظ', 'Review and save');
  static String get saveDraft => _t('حفظ كمسودة', 'Save as draft');
  static String get estimatedTotal =>
      _t('الإجمالي التقديري', 'Estimated total');
  static String get reviewNote => _t(
    'تُحفظ الفاتورة في ERPNext مسودة مع «تحديث المخزون» من مستودع الفان، ولا تخرج البضاعة إلا بعد اعتمادها. الأسعار تقديرية من قائمة الأسعار، وERPNext يحسب السعر النهائي بعملة العميل.',
    'The invoice is saved in ERPNext as a draft with Update Stock from the van warehouse; stock leaves only after it is submitted. Prices are estimates from the price list; ERPNext sets the final price in the customer currency.',
  );
  static String get warehouseLabel => _t('المستودع', 'Warehouse');
  static String get needCustomer =>
      _t('اختر العميل أولًا', 'Choose the customer first');
  static String get needLines =>
      _t('أضف منتجًا واحدًا على الأقل', 'Add at least one product');
  static String saved(String name, String total) => _t(
    'حُفظت الفاتورة $name مسودة • الإجمالي $total',
    'Invoice $name saved as draft • total $total',
  );
  static String get saveFailed =>
      _t('تعذّر حفظ الفاتورة', 'Could not save the invoice');
  static String get discardTitle =>
      _t('تجاهل الفاتورة؟', 'Discard the invoice?');
  static String get discardMessage => _t(
    'ستُفقد المنتجات التي أضفتها.',
    'The products you added will be lost.',
  );
  static String get discard => _t('تجاهل', 'Discard');

  // إرجاع المنتجات
  static String get returnTitle => _t('إرجاع منتجات', 'Return products');
  static String get returnDesc =>
      _t('إرجاع من فاتورة فان معتمدة', 'Return from a submitted van invoice');
  static String get loadingInvoices =>
      _t('جارٍ تحميل الفواتير...', 'Loading invoices...');
  static String get invoicesFailed =>
      _t('تعذّر تحميل الفواتير', 'Could not load invoices');
  static String get noInvoices =>
      _t('لا توجد فواتير فان معتمدة', 'No submitted van invoices');
  static String get noInvoicesHint => _t(
    'تظهر هنا فواتير المبيعات المعتمدة (Submitted) التي خرجت بضاعتها من الفان',
    'Submitted sales invoices whose stock left the van show up here',
  );
  static String get searchInvoice => _t(
    'ابحث برقم الفاتورة أو اسم العميل',
    'Search by invoice number or customer',
  );
  static String get chooseInvoice =>
      _t('اختر الفاتورة للإرجاع منها', 'Choose the invoice to return from');
  static String invoiceTotal(String v) => _t('الإجمالي: $v', 'Total: $v');
  static String get loadingItems =>
      _t('جارٍ تحميل منتجات الفاتورة...', 'Loading invoice products...');
  static String get itemsFailed =>
      _t('تعذّر تحميل منتجات الفاتورة', 'Could not load invoice products');
  static String get chooseItems => _t(
    'حدد المنتجات وأدخل كمية الإرجاع',
    'Select products and enter the return quantity',
  );
  static String soldQty(String q) => _t('المباع: $q', 'Sold: $q');
  static String returnedQty(String q) =>
      _t('أُرجع سابقًا: $q', 'Already returned: $q');
  static String returnableQty(String q) =>
      _t('المسموح إرجاعه: $q', 'Returnable: $q');
  static String get nothingReturnable => _t('أُرجع بالكامل', 'Fully returned');
  static String get returnQty => _t('كمية الإرجاع', 'Return quantity');
  static String qtyAboveReturnable(String max) => _t(
    'لا يمكن إرجاع أكثر من المسموح ($max)',
    'Cannot return more than the returnable quantity ($max)',
  );
  static String get needReturnLines =>
      _t('حدد منتجًا واحدًا على الأقل للإرجاع', 'Select at least one product');
  static String selectedForReturn(int n) =>
      _t('$n منتج للإرجاع', '$n products to return');
  static String get saveReturn =>
      _t('حفظ الإرجاع كمسودة', 'Save return as draft');
  static String get returnFailed =>
      _t('تعذّر حفظ الإرجاع', 'Could not save the return');
  static String get returnSavedTitle =>
      _t('حُفظ مستند الإرجاع', 'Return document saved');
  static String get returnSavedNote => _t(
    'مسودة Sales Invoice من نوع Return مرتبطة بالفاتورة الأصلية. القيم أدناه كما حسبها ERPNext، وتعود البضاعة إلى الفان عند اعتماد المستند.',
    'A draft Sales Invoice of type Return linked to the original invoice. The values below are as calculated by ERPNext; stock returns to the van when it is submitted.',
  );
  static String get returnAgainst => _t('مرتبط بالفاتورة', 'Against invoice');
  static String get returnValue => _t('قيمة الإرجاع', 'Return value');
  static String get netTotal => _t('الصافي', 'Net total');
  static String get taxes => _t('الضرائب', 'Taxes');
  static String get grandTotal => _t('الإجمالي', 'Grand total');
  static String get done => _t('تم', 'Done');

  // رصيد العميل
  static String get creditTitle => _t('رصيد العميل', 'Customer credit');
  static String get creditDesc => _t(
    'الحد الائتماني والرصيد المستحق',
    'Credit limit and outstanding balance',
  );
  static String get loadingCredit =>
      _t('جارٍ تحميل رصيد العميل...', 'Loading customer credit...');
  static String get creditFailed =>
      _t('تعذّر تحميل رصيد العميل', 'Could not load customer credit');
  static String get chooseCustomerHint => _t(
    'اختر عميلًا لعرض حده الائتماني ورصيده',
    'Choose a customer to see the credit limit and balance',
  );
  static String get creditLimit => _t('الحد الائتماني', 'Credit limit');
  static String get currentBalance => _t('الرصيد الحالي', 'Current balance');
  static String get currentBalanceHint =>
      _t('المستحق على العميل الآن', 'What the customer owes now');
  static String get availableCredit => _t('المتاح من الحد', 'Available credit');
  static String get noCreditLimit => _t(
    'لا يوجد حد ائتماني لهذا العميل في ERPNext',
    'This customer has no credit limit in ERPNext',
  );
  static String get limitFromCustomer =>
      _t('الحد من بيانات العميل', 'Limit set on the customer');
  static String limitFromGroup(String g) => _t(
    'الحد من مجموعة العملاء ($g) أو إعدادات الشركة',
    'Limit from the customer group ($g) or company settings',
  );
  static String get overLimit =>
      _t('تجاوز العميل حده الائتماني', 'The customer is over the credit limit');
  static String get customerGroup => _t('المجموعة', 'Group');
  static String get phone => _t('الهاتف', 'Phone');
  static String get customerId => _t('رقم العميل', 'Customer ID');
  static String usedPercent(String p) => _t('مستخدم $p%', '$p% used');
  static String get creditNote => _t(
    'الرصيد والحد كما يحسبهما ERPNext لفحص الحد الائتماني (المستحق على العميل مع أوامر البيع غير المفوترة)، بعملة الشركة. ERPNext يفحص الحد عند اعتماد الفاتورة.',
    'Balance and limit as ERPNext calculates them for its credit check (customer outstanding including unbilled sales orders), in company currency. ERPNext checks the limit when the invoice is submitted.',
  );

  // تحذير الحد في الفاتورة الجديدة
  static String get creditCheck => _t('فحص الحد الائتماني', 'Credit check');
  static String afterInvoice(String v) =>
      _t('الرصيد بعد الفاتورة: $v', 'Balance after invoice: $v');
  static String exceedsLimit(String over) => _t(
    'تحذير: هذه الفاتورة تتجاوز الحد الائتماني للعميل بمقدار $over. قد يرفض ERPNext اعتمادها.',
    'Warning: this invoice exceeds the customer credit limit by $over. ERPNext may refuse to submit it.',
  );
  static String get withinLimit =>
      _t('ضمن الحد الائتماني', 'Within the credit limit');
  static String get cannotCheckLimit => _t(
    'لا يمكن فحص الحد: بعض المنتجات بلا سعر معروف',
    'Cannot check the limit: some products have no known price',
  );
  static String get exceedsTitle =>
      _t('تجاوز الحد الائتماني', 'Credit limit exceeded');
  static String get saveAnyway => _t('حفظ رغم ذلك', 'Save anyway');

  // نهاية اليوم
  static String get eodTitle => _t('نهاية اليوم', 'End of day');
  static String get eodDesc => _t(
    'جرد الفان وملخص مبيعات اليوم',
    'Van count and today\'s sales summary',
  );
  static String get stockCountTab => _t('جرد الفان', 'Van count');
  static String get daySalesTab => _t('مبيعات اليوم', 'Today\'s sales');
  static String get systemQty => _t('كمية النظام', 'System qty');
  static String get physicalQty => _t('الكمية الفعلية', 'Physical qty');
  static String get difference => _t('الفرق', 'Difference');
  static String get onlyDifferences =>
      _t('إظهار الفروقات فقط', 'Show differences only');
  static String differencesCount(int n) => n == 0
      ? _t('لا توجد فروقات', 'No differences')
      : _t('$n منتج فيه فرق', '$n products with a difference');
  static String get countHint => _t(
    'الكمية الفعلية مكتوبة بكمية النظام: عدّل فقط ما يختلف بعد الجرد.',
    'Physical quantities start at the system quantity: change only what differs after counting.',
  );
  static String get qtyNotNegative =>
      _t('الكمية لا يمكن أن تكون سالبة', 'Quantity cannot be negative');
  static String get createReconciliation =>
      _t('إنشاء تسوية مخزون (مسودة)', 'Create stock reconciliation (draft)');
  static String get noDifferences => _t(
    'لا توجد فروقات بين كمية النظام والكمية الفعلية، فلا حاجة لتسوية.',
    'System and physical quantities match: no reconciliation needed.',
  );
  static String get reconcileTitle =>
      _t('إنشاء تسوية المخزون؟', 'Create the stock reconciliation?');
  static String reconcileMessage(int n) => _t(
    'ستُحفظ تسوية مخزون مسودة في ERPNext بـ $n منتج فيه فرق. لا يتغير مخزون الفان إلا بعد اعتمادها.',
    'A draft stock reconciliation with $n products that differ will be saved in ERPNext. The van stock changes only after it is submitted.',
  );
  static String reconcileSaved(String name) => _t(
    'حُفظت تسوية المخزون $name مسودة',
    'Stock reconciliation $name saved as draft',
  );
  static String get reconcileFailed =>
      _t('تعذّر إنشاء تسوية المخزون', 'Could not create the reconciliation');
  static String get loadingDaySales =>
      _t('جارٍ تحميل مبيعات اليوم...', 'Loading today\'s sales...');
  static String get daySalesFailed =>
      _t('تعذّر تحميل مبيعات اليوم', 'Could not load today\'s sales');
  static String get totalSales => _t('إجمالي المبيعات', 'Total sales');
  static String get totalReturns => _t('إجمالي الإرجاعات', 'Total returns');
  static String get netSales => _t('الصافي', 'Net');
  static String invoicesCount(int n) => _t('$n فاتورة', '$n invoices');
  static String returnsCount(int n) => _t('$n مرتجع', '$n returns');
  static String draftsPending(int n, String total) => _t(
    '$n مسودة بانتظار الاعتماد بقيمة $total (غير محتسبة في الإجماليات)',
    '$n drafts awaiting submission worth $total (not counted in the totals)',
  );
  static String get noDaySales =>
      _t('لا توجد فواتير اليوم', 'No invoices today');
  static String get dayTotalsNote => _t(
    'الإجماليات من الفواتير والمرتجعات المعتمدة اليوم من الفان، بعملة الشركة كما في ERPNext.',
    'Totals come from today\'s submitted van invoices and returns, in company currency as in ERPNext.',
  );
  static String get draftLabel => _t('مسودة', 'Draft');
  static String get returnLabel => _t('مرتجع', 'Return');

  // طلب تزويد الفان
  static String get refillTitle => _t('طلب تزويد الفان', 'Van replenishment');
  static String get refillDesc => _t(
    'اطلب منتجات من المستودع الرئيسي',
    'Request products from the main store',
  );
  static String get refillHint => _t(
    'اختر المنتجات القليلة وأدخل الكمية المطلوبة من المستودع الرئيسي',
    'Pick the low products and enter the quantity you need from the main store',
  );
  static String get requestedQty => _t('الكمية المطلوبة', 'Requested quantity');
  static String requestedCount(int n) =>
      _t('$n منتج مطلوب', '$n products requested');
  static String get from => _t('من', 'From');
  static String get to => _t('إلى', 'To');
  static String get saveRequest =>
      _t('حفظ الطلب كمسودة', 'Save request as draft');
  static String get needRequestLines =>
      _t('اختر منتجًا واحدًا على الأقل', 'Choose at least one product');
  static String get requestFailed =>
      _t('تعذّر حفظ طلب التزويد', 'Could not save the request');
  static String get requestSavedTitle =>
      _t('حُفظ طلب التزويد', 'Replenishment request saved');
  static String get requestSavedNote => _t(
    'طلب مواد (Material Request) من نوع Material Transfer محفوظ مسودة في ERPNext. يُنفَّذ النقل بعد اعتماده من المستودع.',
    'A Material Request of type Material Transfer saved as draft in ERPNext. The transfer happens after the store approves it.',
  );
  static String get requestNo => _t('رقم الطلب', 'Request no.');
  static String get requestStatus => _t('الحالة', 'Status');
  static String get requestDate => _t('تاريخ الطلب', 'Request date');
  static String get requiredBy => _t('مطلوب بحلول', 'Required by');
}
