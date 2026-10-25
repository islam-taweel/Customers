import 'app_strings.dart';

/// نصوص قسم «المشتريات» (عربي/إنجليزي). اللغة الحالية من [AppStrings.isArabic].
class PurchaseStrings {
  PurchaseStrings._();

  static String _t(String ar, String en) => AppStrings.isArabic ? ar : en;

  // القائمة والتنقل
  static String get section => _t('المشتريات', 'Purchases');
  static String get navOrders => _t('أوامر الشراء', 'Purchase orders');
  static String get navReceipts => _t('الاستلامات', 'Receipts');
  static String get navInvoices => _t('الفواتير', 'Invoices');

  // التبويبات
  static String get tabToReceive => _t('انتظار الاستلام', 'To receive');

  // أوامر الشراء
  static String get newOrder => _t('أمر شراء جديد', 'New purchase order');
  static String get orderDraftsEmptyTitle =>
      _t('لا توجد أوامر شراء مسودة', 'No draft purchase orders');
  static String get orderDraftsEmptyMessage => _t(
        'اضغط «أمر شراء جديد». يبقى هنا مسودة إلى أن تعتمده.',
        'Tap “New purchase order”. It stays here as a draft until you approve it.',
      );
  static String get toReceiveEmptyTitle =>
      _t('لا توجد أوامر بانتظار الاستلام', 'No orders waiting to be received');
  static String get toReceiveEmptyMessage => _t(
        'أمر الشراء الذي تعتمده يظهر هنا إلى أن يُستلم.',
        'Orders you approve appear here until they are received.',
      );
  static String get orderToBillEmptyTitle =>
      _t('لا توجد أوامر بانتظار الفوترة', 'No orders waiting for billing');
  static String get orderToBillEmptyMessage => _t(
        'أمر الشراء الذي يُستلم يظهر هنا إلى أن يُفوتَر.',
        'Received orders appear here until they are billed.',
      );
  static String get orderCompletedEmptyTitle =>
      _t('لا توجد أوامر مكتملة', 'No completed orders');
  static String get orderCompletedEmptyMessage => _t(
        'أمر الشراء الذي استُلم وفُوتِر يظهر هنا.',
        'Orders that are received and billed appear here.',
      );

  static String get approve => _t('اعتماد', 'Approve');
  static String get approveOrderTitle =>
      _t('اعتماد أمر الشراء؟', 'Approve this purchase order?');
  static String get approveOrderMessage => _t(
        'بعد الاعتماد لا يمكن تعديله أو حذفه، وينتقل إلى «انتظار الاستلام».',
        'After approval it cannot be edited or deleted, and moves to “To receive”.',
      );
  static String get orderApproved =>
      _t('تم اعتماد أمر الشراء', 'Purchase order approved');
  static String get approveFailed =>
      _t('تعذّر اعتماد أمر الشراء', 'Could not approve the purchase order');
  static String get deleteOrderTitle =>
      _t('حذف أمر الشراء؟', 'Delete this purchase order?');
  static String get deleteOrderMessage => _t(
        'سيُحذف أمر الشراء المسودة من ERPNext.',
        'The draft purchase order will be deleted from ERPNext.',
      );
  static String get orderDeleted =>
      _t('تم حذف أمر الشراء', 'Purchase order deleted');
  static String get deleteFailed =>
      _t('تعذّر حذف أمر الشراء', 'Could not delete the purchase order');
  static String get orderCreateFailed =>
      _t('تعذّر حفظ أمر الشراء', 'Could not save the purchase order');

  // الاستلام
  static String get receive => _t('استلام', 'Receive');
  static String get receiveTitle => _t('استلام البضاعة؟', 'Receive the goods?');
  static String get receiveMessage => _t(
        'سيُنشأ استلام مسودة في ERPNext، وتدخل البضاعة المخزون بعد أن يعتمده ERPNext.',
        'A draft receipt is created in ERPNext. Stock is updated once ERPNext approves it.',
      );
  static String get orderReceived =>
      _t('تم إنشاء الاستلام (مسودة)', 'Receipt created (draft)');
  static String get receiveFailed =>
      _t('تعذّر إنشاء الاستلام', 'Could not create the receipt');
  static String get receiptAwaitingApproval =>
      _t('استلام بانتظار اعتماد ERPNext', 'Receipt awaiting ERPNext approval');
  static String get receiptDraftStatus =>
      _t('استلام مسودة', 'Draft receipt');

  // الاستلامات
  static String get receiptsDraftEmptyTitle =>
      _t('لا توجد استلامات مسودة', 'No draft receipts');
  static String get receiptsDraftEmptyMessage => _t(
        'الاستلامات المسودة تظهر هنا إلى أن يعتمدها ERPNext.',
        'Draft receipts appear here until ERPNext approves them.',
      );
  static String get receiptsToBillEmptyTitle =>
      _t('لا توجد استلامات بانتظار الفوترة', 'No receipts waiting for billing');
  static String get receiptsToBillEmptyMessage => _t(
        'الاستلام المعتمد يظهر هنا إلى أن يُفوتَر.',
        'Approved receipts appear here until they are billed.',
      );
  static String get receiptsCompletedEmptyTitle =>
      _t('لا توجد استلامات مكتملة', 'No completed receipts');
  static String get receiptsCompletedEmptyMessage => _t(
        'الاستلام الذي فُوتِر يظهر هنا.',
        'Receipts that have been billed appear here.',
      );
  static String get receiptNumber => _t('رقم الاستلام', 'Receipt no.');

  // الفوترة
  static String get bill => _t('فوترة', 'Bill');
  static String get billTitle => _t('فوترة الاستلام؟', 'Bill this receipt?');
  static String get billMessage => _t(
        'ستُنشأ فاتورة مشتريات مسودة في ERPNext ليعتمدها المسؤول.',
        'A draft purchase invoice is created in ERPNext for the approver to submit.',
      );
  static String get billed =>
      _t('تم إنشاء الفاتورة (مسودة)', 'Invoice created (draft)');
  static String get billFailed =>
      _t('تعذّر إنشاء الفاتورة', 'Could not create the invoice');
  static String get billWaitingApproval => _t(
        'الفوترة تتفعّل بعد اعتماد الاستلام في ERPNext',
        'Billing is enabled once the receipt is approved in ERPNext',
      );
  static String get billNoReceipt => _t(
        'لا يوجد استلام معتمد لأمر الشراء هذا في ERPNext.',
        'There is no approved receipt for this purchase order in ERPNext.',
      );

  // الفواتير
  static String get invoicesDraftEmptyTitle =>
      _t('لا توجد فواتير مسودة', 'No draft invoices');
  static String get invoicesDraftEmptyMessage => _t(
        'فواتير المشتريات المسودة تظهر هنا إلى أن يعتمدها ERPNext.',
        'Draft purchase invoices appear here until ERPNext approves them.',
      );
  static String get invoicesUnpaidEmptyTitle =>
      _t('لا توجد فواتير غير مدفوعة', 'No unpaid invoices');
  static String get invoicesUnpaidEmptyMessage => _t(
        'الفواتير التي لم تُدفع للمورد تظهر هنا.',
        'Invoices not yet paid to the supplier appear here.',
      );
  static String get invoicesPartlyEmptyTitle =>
      _t('لا توجد فواتير مدفوعة جزئيًا', 'No partly paid invoices');
  static String get invoicesPartlyEmptyMessage => _t(
        'الفواتير التي دُفع جزء منها تظهر هنا.',
        'Invoices that are partly paid appear here.',
      );
  static String get invoicesPaidEmptyTitle =>
      _t('لا توجد فواتير مدفوعة', 'No paid invoices');
  static String get invoicesPaidEmptyMessage => _t(
        'الفواتير المدفوعة بالكامل تظهر هنا.',
        'Fully paid invoices appear here.',
      );
  static String get supplier => _t('المورد', 'Supplier');
  static String get purchaseOrderNumber => _t('رقم أمر الشراء', 'PO no.');
  static String get itemsCount => _t('عدد القطع', 'Items count');
  static String get invoiceWaitingApproval => _t(
        'الدفع يتفعّل بعد اعتماد الفاتورة في ERPNext',
        'Payment is enabled once the invoice is approved in ERPNext',
      );

  // الدفع للمورد
  static String get payToSupplier => _t('الدفع للمورد', 'Pay supplier');
  static String get payToSupplierAction => _t('دفع للمورد', 'Pay supplier');
  static String get payAmount => _t('المبلغ', 'Amount');
  static String get payMode => _t('طريقة الدفع', 'Payment method');
  static String get payModesFailed => _t(
        'تعذّر تحميل طرق الدفع من ERPNext',
        'Could not load payment methods from ERPNext',
      );
  static String get payChooseMode =>
      _t('اختر طريقة الدفع', 'Choose a payment method');
  static String payExceeds(String due) => _t(
        'المبلغ أكبر من قيمة المشتريات المستحقة ($due). لا يمكن دفع أكثر من المستحق.',
        'The amount is more than the purchase amount due ($due). You cannot pay more than is due.',
      );
  static String get payZero => _t(
        'لا يمكن أن يكون المبلغ صفرًا. أدخل مبلغًا أكبر من صفر.',
        'The amount cannot be zero. Enter an amount greater than zero.',
      );
  static String get payInvalid => _t('أدخل مبلغًا صحيحًا', 'Enter a valid amount');
  static String get payReference => _t(
        'رقم المرجع (رقم الشيك أو مرجع التحويل)',
        'Reference no. (cheque number or transfer reference)',
      );
  static String get payReferenceDate =>
      _t('تاريخ المرجع', 'Reference date');
  static String get paySave => _t('تأكيد الدفع', 'Confirm payment');
  static String get paymentSaved => _t(
        'تم حفظ الدفعة مسودة. تتغير حالة الفاتورة ومستحقها بعد اعتمادها في ERPNext.',
        'Payment saved as a draft. The invoice status and amount due change once ERPNext approves it.',
      );
  static String get paymentFailed =>
      _t('تعذّر حفظ الدفعة', 'Could not save the payment');
  static String paymentPending(String amount) => _t(
        'دفعة بانتظار اعتماد ERPNext: $amount',
        'Payment awaiting ERPNext approval: $amount',
      );

  // أمر شراء جديد
  static String get newOrderTitle => _t('أمر شراء جديد', 'New purchase order');
  static String get chooseSupplier => _t('اختر المورد', 'Choose supplier');
  static String get searchSupplier => _t('ابحث عن مورد', 'Search suppliers');
  static String get searchItem => _t('ابحث عن صنف', 'Search items');
  static String get addItem => _t('إضافة صنف', 'Add item');
  static String get noResults => _t('لا توجد نتائج', 'No results');
  static String get qty => _t('الكمية', 'Quantity');
  static String get unitPrice => _t('سعر الوحدة', 'Unit price');
  static String get requiredBy => _t('تاريخ الاستلام المطلوب', 'Required by');
  static String get itemsTitle => _t('الأصناف', 'Items');
  static String get noItemsYet =>
      _t('لم تضف أي صنف بعد', 'No items added yet');
  static String get saveDraft => _t('حفظ كمسودة', 'Save as draft');
  static String get subtotal => _t('المجموع قبل الضريبة', 'Subtotal');
  static String get taxes => _t('الضريبة', 'Tax');
  static String get total => _t('الإجمالي', 'Total');
  static String get orderSaved =>
      _t('تم حفظ أمر الشراء مسودة', 'Purchase order saved as draft');
  static String get invalidLine => _t(
        'أدخل كمية وسعرًا أكبر من صفر',
        'Enter a quantity and price greater than zero',
      );

  // تعديل كميات بنود المستند المسودة (المستودع للعرض، بلا سعر)
  static String get editItems => _t('تعديل الكميات', 'Edit quantities');
  static String get editItemsTitle => _t('تعديل الكميات', 'Edit quantities');
  static String get qtyLabel => _t('الكمية', 'Quantity');
  static String get warehouseLabel => _t('المستودع', 'Warehouse');
  static String get saveItems => _t('حفظ الكميات', 'Save quantities');
  static String get itemsSaved => _t('تم حفظ الكميات', 'Quantities saved');
  static String get itemsSaveFailed =>
      _t('تعذّر حفظ الكميات', 'Could not save the quantities');
  static String get itemsInvalid =>
      _t('الكمية يجب أن تكون أكبر من صفر', 'Quantity must be greater than zero');
  static String get totalsFromErp => _t(
        'الإجمالي والضريبة يحسبهما ERPNext ويظهران بعد الحفظ',
        'Total and tax are calculated by ERPNext and shown after saving',
      );
}
