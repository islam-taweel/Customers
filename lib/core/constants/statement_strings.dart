import 'app_strings.dart';

/// نصوص «كشف حساب العملاء» وشاشة تفاصيل المستند (عربي/إنجليزي).
class StatementStrings {
  StatementStrings._();

  static String _t(String ar, String en) => AppStrings.isArabic ? ar : en;

  static String get section => _t('كشف حساب العملاء', 'Customer statements');

  // قائمة العملاء
  static String get searchHint =>
      _t('ابحث بالاسم أو الرقم', 'Search by name or ID');
  static String get loadingCustomers =>
      _t('جارٍ تحميل العملاء...', 'Loading customers...');
  static String get noCustomers => _t('لا يوجد عملاء', 'No customers');
  static String get loadFailed =>
      _t('تعذّر تحميل البيانات', 'Could not load the data');

  // الكشف
  static String get loadingStatement =>
      _t('جارٍ تحميل كشف الحساب...', 'Loading the statement...');
  static String get allPeriods => _t('كل الفترات', 'All periods');
  static String get chooseRange => _t('اختر الفترة', 'Choose period');
  static String get clearRange => _t('إلغاء الفترة', 'Clear period');
  static String get openingBalance => _t('الرصيد الافتتاحي', 'Opening balance');
  static String get totalDebit => _t('مجموع المدين', 'Total debit');
  static String get totalCredit => _t('مجموع الدائن', 'Total credit');
  static String get closingBalance => _t('الرصيد الختامي', 'Closing balance');
  static String get balance => _t('الرصيد', 'Balance');
  static String get debit => _t('مدين', 'Debit');
  static String get credit => _t('دائن', 'Credit');
  static String get owesUs => _t('مستحق على العميل', 'Customer owes us');
  static String get inCredit => _t('رصيد للعميل', 'Customer credit');
  static String get settled => _t('الحساب مسدد', 'Settled');
  static String get noEntries =>
      _t('لا توجد حركات في هذه الفترة', 'No transactions in this period');
  static String get needsAccountsRole => _t(
        'قراءة كشف الحساب تحتاج صلاحية محاسبة (قراءة GL Entry) في ERPNext.',
        'Reading statements needs an accounts role (read GL Entry) in ERPNext.',
      );

  // تفاصيل المستند
  static String get loadingDocument =>
      _t('جارٍ تحميل المستند...', 'Loading the document...');
  static String get number => _t('الرقم', 'Number');
  static String get date => _t('التاريخ', 'Date');
  static String get status => _t('الحالة', 'Status');
  static String get party => _t('العميل', 'Customer');
  static String get draft => _t('مسودة', 'Draft');
  static String get submitted => _t('معتمد', 'Submitted');
  static String get cancelled => _t('ملغى', 'Cancelled');
  static String get items => _t('الأصناف', 'Items');
  static String get qty => _t('الكمية', 'Qty');
  static String get rate => _t('السعر', 'Rate');
  static String get amount => _t('المبلغ', 'Amount');
  static String get invoiceTotal => _t('قيمة الفاتورة', 'Invoice total');
  static String get outstanding => _t('المتبقي', 'Outstanding');
  static String get returnAgainst => _t('مرتجع مقابل', 'Return against');
  static String get creditNote => _t('إشعار دائن (مرتجع)', 'Credit note (return)');
  static String get modeOfPayment => _t('طريقة الدفع', 'Mode of payment');
  static String get received => _t('المبلغ المستلم', 'Amount received');
  static String get creditedToCustomer =>
      _t('على حساب العميل', 'Credited to customer');
  static String get paidTo => _t('حساب القبض', 'Received into');
  static String get referenceNo => _t('رقم المرجع', 'Reference no.');
  static String get referenceDate => _t('تاريخ المرجع', 'Reference date');
  static String get allocations =>
      _t('مخصصة للفواتير', 'Allocated to invoices');
  static String get unallocated =>
      _t('غير مخصص (رصيد للعميل)', 'Unallocated (customer credit)');
  static String get notAllocated =>
      _t('غير مخصصة لأي فاتورة', 'Not allocated to any invoice');
  static String get remarks => _t('ملاحظات', 'Remarks');
  static String get accounts => _t('الحسابات', 'Accounts');
  static String get account => _t('الحساب', 'Account');

  static String voucherType(String doctype) => switch (doctype) {
        'Sales Invoice' => _t('فاتورة مبيعات', 'Sales invoice'),
        'Payment Entry' => _t('دفعة', 'Payment'),
        'Journal Entry' => _t('قيد يومية', 'Journal entry'),
        'Delivery Note' => _t('سند تسليم', 'Delivery note'),
        _ => doctype,
      };
}
