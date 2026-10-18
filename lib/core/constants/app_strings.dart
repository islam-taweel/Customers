/// كل النصوص الظاهرة للمستخدم في مكان واحد، بالعربية والإنجليزية.
/// اللغة الحالية يضبطها [LanguageController] عبر [isArabic].
class AppStrings {
  AppStrings._();

  /// true = العربية، false = الإنجليزية
  static bool isArabic = true;

  static String _t(String ar, String en) => isArabic ? ar : en;

  // ───────── عام ─────────
  static String get appName => _t('دفتر الديون', 'Debt Ledger');
  static String get save => _t('حفظ', 'Save');
  static String get cancel => _t('إلغاء', 'Cancel');
  static String get retry => _t('إعادة المحاولة', 'Retry');
  static String get errorTitle => _t('حدث خطأ', 'Something went wrong');

  // ───────── القائمة الجانبية ─────────
  static String get dashboard => _t('لوحة التحكم', 'Dashboard');
  static String get customerOrders => _t('طلبيات العملاء', 'Customer orders');

  // ───────── شاشة العملاء ─────────
  static String get customers => _t('العملاء', 'Customers');
  static String get addCustomer => _t('إضافة عميل', 'Add customer');
  static String get addCustomerTitle =>
      _t('إضافة عميل جديد', 'Add new customer');
  static String get addFirstCustomer =>
      _t('إضافة أول عميل', 'Add your first customer');
  static String get searchHint =>
      _t('ابحث باسم العميل...', 'Search by customer name...');
  static String get loadingCustomers =>
      _t('جاري تحميل العملاء...', 'Loading customers...');
  static String get noCustomersTitle =>
      _t('لا يوجد عملاء بعد', 'No customers yet');
  static String get noCustomersMessage => _t(
        'ابدأ بإضافة أول عميل لتسجيل ديونه ودفعاته.',
        'Start by adding your first customer to record their debts and payments.',
      );
  static String get noSearchResultsTitle =>
      _t('لا توجد نتائج مطابقة', 'No matching results');
  static String get noSearchResultsMessage =>
      _t('جرّب البحث باسم آخر.', 'Try searching with a different name.');
  static String get customerAdded =>
      _t('تمت إضافة العميل', 'Customer added');
  static String get customerSaveFailed =>
      _t('تعذّر حفظ العميل', 'Could not save the customer');
  static String get totalDebts => _t('إجمالي الديون', 'Total debts');
  static String get loadCustomersError => _t(
        'تعذّر تحميل العملاء. حاول مرة أخرى.',
        'Could not load customers. Please try again.',
      );
  static String get loadMoreCustomersError => _t(
        'تعذّر تحميل المزيد من العملاء',
        'Could not load more customers',
      );
  static String get unknownInitial => _t('؟', '?');

  // ───────── الفرز ─────────
  static String get sortTooltip => _t('فرز القائمة', 'Sort list');
  static String get sortByName => _t('الاسم (أ - ي)', 'Name (A–Z)');
  static String get sortNewest => _t('الأحدث أولًا', 'Newest first');
  static String get sortHighestDebt => _t('الأعلى ديونًا', 'Highest debt');

  // ───────── الحقول والتحقق ─────────
  static String get name => _t('الاسم', 'Name');
  static String get phone => _t('رقم الهاتف', 'Phone number');
  static String get nameRequired =>
      _t('الرجاء إدخال الاسم', 'Please enter the name');
  static String get phoneRequired =>
      _t('الرجاء إدخال رقم الهاتف', 'Please enter the phone number');
  static String get amount => _t('المبلغ', 'Amount');
  static String get noteOptional =>
      _t('ملاحظة (اختياري)', 'Note (optional)');
  static String get amountInvalid =>
      _t('الرجاء إدخال مبلغ صحيح', 'Please enter a valid amount');
  static String get amountMustBePositive =>
      _t('يجب أن يكون المبلغ أكبر من صفر', 'Amount must be greater than zero');

  // ───────── تعديل العميل ─────────
  static String get editCustomer => _t('تعديل', 'Edit');
  static String get editCustomerTitle =>
      _t('تعديل بيانات العميل', 'Edit customer');
  static String get saveChanges => _t('حفظ التغييرات', 'Save changes');
  static String get phoneInvalid => _t(
        'رقم الهاتف يجب أن يتكون من 10 أرقام ويبدأ بـ 05',
        'Phone number must be 10 digits and start with 05',
      );
  static String get phoneHint => '05XXXXXXXX';
  static String get customerUpdated =>
      _t('تم حفظ التعديلات', 'Changes saved');
  static String get customerUpdateFailed =>
      _t('تعذّر حفظ التعديلات', 'Could not save changes');

  // ───────── حذف العميل ─────────
  static String get delete => _t('حذف', 'Delete');
  static String get undo => _t('تراجع', 'Undo');
  static String get deleteCustomerTitle =>
      _t('حذف العميل', 'Delete customer');
  static String get deleteCustomerMessage => _t(
        'هل أنت متأكد من حذف هذا العميل وكل عملياته؟',
        'Are you sure you want to delete this customer and all their transactions?',
      );
  static String get customerDeleteFailed =>
      _t('تعذّر حذف العميل', 'Could not delete the customer');
  static String get customerRestored =>
      _t('تمت استعادة العميل', 'Customer restored');
  static String get customerRestoreFailed =>
      _t('تعذّرت استعادة العميل', 'Could not restore the customer');
  static String customerDeleted(String name) =>
      _t('تم حذف «$name»', '“$name” deleted');

  // ───────── واتساب ─────────
  static String get whatsappButton =>
      _t('إرسال تذكير عبر واتساب', 'Send reminder via WhatsApp');
  static String get whatsappNotInstalled => _t(
        'تطبيق واتساب غير مثبّت على هذا الجهاز',
        'WhatsApp is not installed on this device',
      );
  static String get whatsappInvalidPhone => _t(
        'رقم هاتف العميل غير صالح لفتح واتساب',
        'The customer’s phone number is not valid for WhatsApp',
      );
  static String get whatsappNoDebt => _t(
        'لا يوجد مبلغ مستحق على هذا العميل',
        'This customer has no outstanding balance',
      );
  static String get whatsappFailed =>
      _t('تعذّر فتح واتساب. حاول مرة أخرى', 'Could not open WhatsApp. Try again');

  /// نص الرسالة الجاهزة المرسلة للعميل. يبقى بالعربية دائمًا (عملاؤك عرب)،
  /// ولا يتبع لغة التطبيق. لجعله يتبعها استخدم _t(...) هنا.
  static String whatsappDebtMessage(String name, String amount) =>
      'مرحبًا $name،\n'
      'نود تذكيرك بأن المبلغ المستحق عليك هو $amount.\n'
      'نرجو التكرم بالتسديد في أقرب وقت. شكرًا لك.';

  // ───────── حالة الرصيد ─────────
  static String get owed => _t('مستحق', 'Owes');
  static String get hasCredit => _t('له رصيد', 'Has credit');
  static String get settled => _t('مسدد', 'Settled');
  static String get balanceOwedLong =>
      _t('الرصيد المستحق على العميل', 'Balance owed by the customer');
  static String get balanceCreditLong =>
      _t('للعميل رصيد عندك', 'Customer has credit with you');
  static String get balanceSettledLong =>
      _t('الحساب مسدد', 'Account settled');

  // ───────── العمليات (شاشة التفاصيل) ─────────
  static String get addDebt => _t('إضافة دين', 'Add debt');
  static String get addPayment => _t('إضافة دفعة', 'Add payment');
  static String get debt => _t('دين', 'Debt');
  static String get payment => _t('دفعة', 'Payment');
  static String get debtAdded => _t('تمت إضافة الدين', 'Debt added');
  static String get paymentAdded => _t('تمت إضافة الدفعة', 'Payment added');
  static String get operationsLog =>
      _t('سجل العمليات', 'Transaction history');
  static String get noOperationsTitle =>
      _t('لا توجد عمليات بعد', 'No transactions yet');
  static String get noOperationsMessage => _t(
        'أضف دينًا أو دفعة من الزرين أعلاه.',
        'Add a debt or a payment using the buttons above.',
      );
  static String get loadOperationsError => _t(
        'تعذّر تحميل عمليات العميل. حاول مرة أخرى.',
        'Could not load the customer’s transactions. Please try again.',
      );
  static String get operationSaveFailed =>
      _t('تعذّر حفظ العملية', 'Could not save the transaction');

  // ───────── الفاتورة ─────────
  static String get tabOperations => _t('العمليات', 'Transactions');
  static String get tabInvoice => _t('الفاتورة', 'Invoice');
  static String get invoiceTitle => _t('فاتورة', 'Invoice');
  static String get invoiceNumber => _t('رقم الفاتورة', 'Invoice no.');
  static String get invoiceCustomer => _t('اسم العميل', 'Customer name');
  static String get invoiceAmount => _t('مبلغ الفاتورة', 'Invoice amount');
  static String get viewInvoicePdf => _t('عرض الفاتورة PDF', 'View invoice PDF');
  static String get invoicePdfFailed =>
      _t('تعذّر إنشاء ملف PDF', 'Could not create the PDF file');

  // ───────── ERPNext (الفواتير فقط) ─────────
  static String get erpMissingCredentials => _t(
        'لم تُضبط مفاتيح ERPNext. شغّل التطبيق مع --dart-define-from-file=env.json (راجع env.example.json).',
        'ERPNext keys are not set. Run the app with --dart-define-from-file=env.json (see env.example.json).',
      );
  static String get erpUnauthorized => _t(
        'رفض ERPNext مفاتيح الدخول. تأكد من صحة API key و secret وصلاحياتهما.',
        'ERPNext rejected the API keys. Check the key, the secret and their permissions.',
      );
  static String get erpNetworkError => _t(
        'تعذّر الاتصال بـ ERPNext. تأكد أنك على نفس شبكة Wi-Fi وأن عنوان الخادم صحيح.',
        'Could not reach ERPNext. Make sure you are on the same Wi-Fi and the server address is correct.',
      );
  static String get erpServerError => _t(
        'ردّ ERPNext بخطأ. حاول مرة أخرى.',
        'ERPNext returned an error. Please try again.',
      );
  static String get offlineNoCache => _t(
        'لا يوجد اتصال بالإنترنت، ولا توجد نسخة محفوظة لهذه البيانات بعد. افتحها مرة واحدة وأنت متصل.',
        'You are offline and there is no saved copy of this data yet. Open it once while online.',
      );
  static String offlineNotice(String when) => _t(
        'غير متصل بالإنترنت. تُعرض بيانات محفوظة (آخر تحديث: $when)',
        'You are offline. Showing saved data (last updated: $when)',
      );
  static String staleNotice(String reason, String when) => _t(
        '$reason تُعرض بيانات محفوظة (آخر تحديث: $when)',
        '$reason Showing saved data (last updated: $when)',
      );
  static String get erpNotFound => _t(
        'لم يُعثر على الفاتورة في ERPNext.',
        'The invoice was not found in ERPNext.',
      );

  static String get loadInvoicesError => _t(
        'تعذّر تحميل الفواتير. حاول مرة أخرى.',
        'Could not load the invoices. Please try again.',
      );
  static String get loadInvoiceError => _t(
        'تعذّر تحميل تفاصيل الفاتورة. حاول مرة أخرى.',
        'Could not load the invoice details. Please try again.',
      );
  static String get invoicesNoMatchTitle =>
      _t('العميل غير موجود في ERPNext', 'Customer not found in ERPNext');
  static String get invoicesNoMatchMessage => _t(
        'لم نجد عميلًا في ERPNext يطابق رقم هاتف هذا العميل أو اسمه.',
        'No ERPNext customer matches this customer’s phone number or name.',
      );
  static String get noInvoicesTitle => _t('لا توجد فواتير', 'No invoices');
  static String get noInvoicesMessage => _t(
        'لا توجد فواتير معتمدة لهذا العميل في ERPNext.',
        'There are no submitted invoices for this customer in ERPNext.',
      );
  static String get invoiceRemaining => _t('المتبقي', 'Remaining');
  static String get invoicePostingDate => _t('تاريخ الفاتورة', 'Invoice date');
  static String get invoiceDueDate => _t('تاريخ الاستحقاق', 'Due date');
  static String get invoiceStatusLabel => _t('الحالة', 'Status');
  static String get invoiceItems => _t('الأصناف', 'Items');
  static String get invoiceTaxes => _t('الضرائب والرسوم', 'Taxes and charges');
  static String get invoiceOutstanding => _t('المتبقي', 'Outstanding');

  /// حالة الفاتورة في ERPNext بلغة التطبيق (الحالة غير المعروفة تُعرض كما هي)
  static String invoiceStatus(String status) => switch (status) {
        'Draft' => _t('طلبية (مسودة)', 'Order (draft)'),
        'Paid' => _t('مدفوعة', 'Paid'),
        'Unpaid' => _t('غير مدفوعة', 'Unpaid'),
        'Overdue' => _t('متأخرة', 'Overdue'),
        'Partly Paid' => _t('مدفوعة جزئيًا', 'Partly paid'),
        'Return' => _t('مرتجع', 'Return'),
        'Credit Note Issued' => _t('أُصدر لها إشعار دائن', 'Credit note issued'),
        _ => status,
      };

  // ───────── طلبيات العملاء ─────────
  static String get newOrderTitle => _t('طلبية جديدة', 'New order');
  static String get stepCustomer => _t('العميل', 'Customer');
  static String get stepItems => _t('الأصناف', 'Items');
  static String get stepInvoice => _t('الفاتورة', 'Invoice');
  static String get next => _t('التالي', 'Next');
  static String get back => _t('رجوع', 'Back');
  static String get chooseCustomer =>
      _t('اختر العميل', 'Choose the customer');
  static String get chooseCustomerHint => _t(
        'اختر عميلًا واحدًا ثم اضغط «التالي».',
        'Pick one customer, then tap “Next”.',
      );
  static String get orderCustomersEmpty =>
      _t('لا يوجد عملاء في ERPNext', 'No customers in ERPNext');
  static String orderFor(String name) =>
      _t('طلبية لـ $name', 'Order for $name');
  static String get chooseGroupHint =>
      _t('اختر مجموعة لعرض أصنافها', 'Choose a group to see its items');
  static String get loadingGroups =>
      _t('جاري تحميل المجموعات...', 'Loading groups...');
  static String get loadingItems =>
      _t('جاري تحميل الأصناف...', 'Loading items...');
  static String get loadGroupsError => _t(
        'تعذّر تحميل مجموعات الأصناف. حاول مرة أخرى.',
        'Could not load item groups. Please try again.',
      );
  static String get loadItemsError => _t(
        'تعذّر تحميل الأصناف. حاول مرة أخرى.',
        'Could not load the items. Please try again.',
      );
  static String get noGroupsTitle =>
      _t('لا توجد مجموعات أصناف', 'No item groups');
  static String get noItemsTitle =>
      _t('لا توجد أصناف في هذه المجموعة', 'No items in this group');
  static String get noItemsMessage => _t(
        'لا توجد أصناف مفعّلة وقابلة للبيع هنا.',
        'There are no enabled sales items here.',
      );
  static String get itemPrice => _t('السعر', 'Price');
  static String get itemStock => _t('المتبقي في المخزن', 'Stock left');
  static String get quantity => _t('الكمية', 'Quantity');
  static String get lineTotal => _t('إجمالي الصنف', 'Item total');
  static String get loadingPricing =>
      _t('جاري جلب السعر والمخزون...', 'Fetching price and stock...');
  static String get loadPricingError => _t(
        'تعذّر جلب السعر والمخزون.',
        'Could not fetch price and stock.',
      );
  static String get noPriceTitle =>
      _t('لا يوجد سعر لهذا الصنف', 'No price is set for this item');
  static String get noPriceMessage => _t(
        'لا يمكن إضافته للطلبية قبل تحديد سعره في «Standard Selling».',
        'It cannot be ordered until a price is set in “Standard Selling”.',
      );
  static String get outOfStock => _t('نفد المخزون', 'Out of stock');
  static String get outOfStockMessage => _t(
        'لا توجد كمية متاحة من هذا الصنف في المستودع.',
        'There is no available quantity of this item in the warehouse.',
      );
  static String afterOrder(String qty) =>
      _t('بعد طلبك: $qty', 'After your order: $qty');
  static String maxAvailable(String qty) =>
      _t('المتاح فقط $qty', 'Only $qty available');
  static String selectedItemsCount(int n) =>
      _t('$n أصناف مختارة', '$n items selected');
  static String get orderTotal => _t('إجمالي الطلبية', 'Order total');
  static String get invoiceHeading => _t('فاتورة الزبون', 'Customer invoice');
  static String get invoiceLinesEmpty =>
      _t('لم تختر أي صنف بعد', 'No items selected yet');
  static String get unitPrice => _t('سعر الوحدة', 'Unit price');
  static String get removeItem => _t('إزالة الصنف', 'Remove item');
  static String get deliveryDate => _t('تاريخ التسليم', 'Delivery date');
  static String get orderDate => _t('تاريخ الطلبية', 'Order date');
  static String get savedAsDraft => _t(
        'ستُحفظ الطلبية كمسودة في ERPNext.',
        'The order will be saved as a draft in ERPNext.',
      );
  static String get submitOrder => _t('إرسال الطلبية', 'Send order');
  static String get submittingOrder => _t('جاري الإرسال...', 'Sending...');
  static String get orderCreateFailed =>
      _t('تعذّر إنشاء الطلبية', 'Could not create the order');
  static String get orderCreatedTitle =>
      _t('تم إنشاء الطلبية', 'Order created');
  static String get orderNumber => _t('رقم الطلبية', 'Order number');
  static String get orderCreatedNote => _t(
        'حُفظت كمسودة، ويمكنك مراجعتها واعتمادها من ERPNext.',
        'Saved as a draft. You can review and submit it in ERPNext.',
      );
  static String get invoiceSavedNote => _t(
        'تم حفظ الفاتورة في سجل العميل.',
        'The invoice was saved to the customer record.',
      );
  static String get invoiceNotSavedNote => _t(
        'تم إنشاء الطلبية، لكن تعذّر حفظ الفاتورة محليًا (تأكد أن العميل تمت مزامنته).',
        'Order created, but the invoice could not be saved locally (make sure the customer is synced).',
      );
  static String get newOrderAgain => _t('طلبية جديدة', 'New order');
  static String get close => _t('إغلاق', 'Close');
  static String get copied => _t('تم نسخ الرقم', 'Number copied');
  static String get leaveOrderTitle =>
      _t('إلغاء الطلبية؟', 'Discard this order?');
  static String get leaveOrderMessage => _t(
        'الأصناف التي اخترتها لن تُحفظ.',
        'The items you selected will not be saved.',
      );
  static String get keepEditing => _t('متابعة التعديل', 'Keep editing');
  static String get discard => _t('إلغاء الطلبية', 'Discard');

  /// أسماء مجموعات الأصناف بلغة التطبيق (غير المعروفة تُعرض كما هي)
  static String itemGroupName(String group) => switch (group) {
        'Consumable' => _t('مستهلكات', 'Consumable'),
        'Electrical' => _t('كهربائيات', 'Electrical'),
        'Hand Tools' => _t('عدد يدوية', 'Hand Tools'),
        'Plumbing' => _t('سباكة', 'Plumbing'),
        'Power Tools' => _t('عدد كهربائية', 'Power Tools'),
        'Products' => _t('منتجات', 'Products'),
        'Raw Material' => _t('مواد خام', 'Raw Material'),
        'Services' => _t('خدمات', 'Services'),
        'Sub Assemblies' => _t('تجميعات فرعية', 'Sub Assemblies'),
        _ => group,
      };

  // ───────── الوقت ─────────
  static String get am => _t('ص', 'AM');
  static String get pm => _t('م', 'PM');

  // ───────── للتطوير فقط (debug) ─────────
  static String addFakeCustomersTooltip(int n) =>
      _t('للتطوير: إضافة $n عميل وهمي', 'Dev: add $n fake customers');
  static String fakeCustomersAdded(int n) =>
      _t('تمت إضافة $n عميل وهمي', '$n fake customers added');
  static String get fakeCustomersFailed =>
      _t('تعذّرت إضافة العملاء الوهميين', 'Could not add fake customers');
}
