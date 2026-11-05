import 'app_strings.dart';

/// نصوص قسم «مردود المبيعات» (عربي/إنجليزي). اللغة الحالية من [AppStrings.isArabic].
class ReturnsStrings {
  ReturnsStrings._();

  static String _t(String ar, String en) => AppStrings.isArabic ? ar : en;

  static String get section => _t('مردود المبيعات', 'Sales returns');

  // اختيار العميل
  static String get chooseCustomer => _t('اختر العميل', 'Choose a customer');
  static String get chooseCustomerHint => _t(
        'العملاء الذين لديهم فواتير مبيعات معتمدة سابقة',
        'Customers with previous submitted sales invoices',
      );
  static String get searchHint =>
      _t('ابحث بالاسم أو الرقم', 'Search by name or ID');
  static String get loadingCustomers =>
      _t('جارٍ تحميل العملاء...', 'Loading customers...');
  static String get noCustomers => _t(
        'لا يوجد عملاء لديهم فواتير سابقة',
        'No customers with previous invoices',
      );
  static String get loadFailed =>
      _t('تعذّر تحميل البيانات', 'Could not load the data');
  static String invoicesCount(int n) => _t('$n فاتورة', '$n invoices');
  static String lastInvoice(String date) =>
      _t('آخر فاتورة: $date', 'Last invoice: $date');
  static String savedAt(String time) =>
      _t('نسخة محفوظة من $time', 'Saved copy from $time');

  // فواتير العميل
  static String get chooseInvoice =>
      _t('اختر الفاتورة المراد الإرجاع منها', 'Choose the invoice to return from');
  static String get loadingInvoices =>
      _t('جارٍ تحميل الفواتير...', 'Loading invoices...');
  static String get noInvoices =>
      _t('لا توجد فواتير معتمدة لهذا العميل', 'No submitted invoices for this customer');
  static String total(String amount) => _t('الإجمالي: $amount', 'Total: $amount');
  static String outstanding(String amount) =>
      _t('المتبقي: $amount', 'Outstanding: $amount');

  // أصناف الفاتورة
  static String get loadingItems =>
      _t('جارٍ تحميل الأصناف...', 'Loading items...');
  static String get noItems =>
      _t('لا توجد أصناف في هذه الفاتورة', 'No items in this invoice');
  static String get soldQty => _t('المباع', 'Sold');
  static String get returnedQty => _t('أُرجع سابقًا', 'Returned');
  static String get returnableQty => _t('المتاح للإرجاع', 'Returnable');
  static String get returnQty => _t('كمية الإرجاع', 'Return qty');
  static String get fullyReturned => _t('أُرجع بالكامل', 'Fully returned');
  static String get wholeNumberOnly =>
      _t('هذه الوحدة لا تقبل كسورًا', 'This unit accepts whole numbers only');
  static String maxReturnable(String qty) =>
      _t('الحد الأقصى للإرجاع $qty', 'You can return at most $qty');
  static String get reasonLabel =>
      _t('سبب الإرجاع (اختياري)', 'Return reason (optional)');
  static String returnTotal(String amount) =>
      _t('قيمة المرتجع: $amount', 'Return value: $amount');
  static String get createReturn => _t('إنشاء المرتجع', 'Create return');
  static String get nothingChosen =>
      _t('اختر كمية صنف واحد على الأقل', 'Choose a quantity for at least one item');
  static String get fixErrors =>
      _t('صحّح الكميات المعلّمة', 'Fix the marked quantities');
  static String get confirmTitle => _t('إنشاء المرتجع؟', 'Create the return?');
  static String confirmBody(int n, String amount) => _t(
        'سيُحفظ إشعار دائن مسودة بـ $n صنف بقيمة $amount، مع إرجاع البضاعة للمخزون كمسودة.',
        'A draft credit note with $n items worth $amount will be saved, '
            'with a draft stock return.',
      );
  static String get createFailed =>
      _t('تعذّر إنشاء المرتجع', 'Could not create the return');
  static String get createdTitle => _t('حُفظ المرتجع', 'Return saved');
  static String creditNoteSaved(String id) => _t(
        'إشعار الدائن: $id (مسودة بانتظار الاعتماد)',
        'Credit note: $id (draft awaiting approval)',
      );
  static String stockReturnSaved(String id) => _t(
        'إرجاع البضاعة: $id (مسودة بانتظار الاعتماد)',
        'Stock return: $id (draft awaiting approval)',
      );
  static String stockReturnFailed(String dn, String error) => _t(
        'تعذّر إرجاع بضاعة إذن التسليم $dn: $error',
        'Could not create the stock return for $dn: $error',
      );
  static String get ok => _t('حسنًا', 'OK');

  // بانتظار الاعتماد
  static String get pendingTitle =>
      _t('مرتجعات بانتظار الاعتماد', 'Returns awaiting approval');
  static String get creditNotes => _t('إشعارات دائن', 'Credit notes');
  static String get stockReturns => _t('إرجاع بضاعة', 'Stock returns');
  static String get noPending =>
      _t('لا توجد مرتجعات بانتظار الاعتماد', 'No returns awaiting approval');
  static String against(String id) => _t('مقابل: $id', 'Against: $id');
  static String get approve => _t('اعتماد', 'Approve');
  static String get reject => _t('رفض', 'Reject');
  static String approveTitle(String id) => _t('اعتماد $id؟', 'Approve $id?');
  static String rejectTitle(String id) => _t('رفض $id؟', 'Reject $id?');
  static String get rejectBody =>
      _t('ستُحذف المسودة من ERPNext.', 'The draft will be deleted from ERPNext.');
  static String approved(String id) => _t('اعتُمد $id', '$id approved');
  static String rejected(String id) => _t('حُذف $id', '$id deleted');
  static String get actionFailed =>
      _t('تعذّر تنفيذ العملية', 'Could not complete the action');

  // رد المال
  static String get refundTitle => _t('رد المال للعميل', 'Refund the customer');
  static String refundAmount(String amount) =>
      _t('المبلغ المستحق للعميل: $amount', 'Amount due to the customer: $amount');
  static String customerStillOwes(String amount) => _t(
        'العميل ما زال مدينًا بـ $amount، فإشعار الدائن يُنقص دينه ولا يُرد مال.',
        'The customer still owes $amount, so the credit note reduces the debt; no refund.',
      );
  static String get paymentMode => _t('طريقة الدفع', 'Mode of payment');
  static String get referenceNo => _t('رقم المرجع', 'Reference no.');
  static String get referenceDate => _t('تاريخ المرجع', 'Reference date');
  static String get referenceRequired =>
      _t('رقم المرجع وتاريخه مطلوبان لغير النقد', 'Reference no. and date are required for non-cash');
  static String get saveRefund => _t('حفظ دفعة الرد', 'Save refund');
  static String get skipRefund => _t('لاحقًا', 'Later');
  static String refundSaved(String id) => _t(
        'حُفظت دفعة الرد $id (مسودة بانتظار الاعتماد)',
        'Refund $id saved (draft awaiting approval)',
      );
  static String get refundFailed =>
      _t('تعذّر حفظ دفعة الرد', 'Could not save the refund');
  static String get refundNotPay => _t(
        'ERPNext لم يُرجع دفعة صرف (Pay) لهذا الإشعار',
        'ERPNext did not return a Pay entry for this credit note',
      );
  static String refundNoAccount(String mode) => _t(
        'لا يوجد حساب افتراضي لطريقة الدفع «$mode» في الشركة',
        'No default account for mode of payment "$mode" in the company',
      );
  static String get modesFailed =>
      _t('تعذّر تحميل طرق الدفع', 'Could not load modes of payment');
}
