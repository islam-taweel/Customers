import '../../data/models/sync_models.dart';

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

  // ───────── قسم الطلبات: الطلبيات / التسليمات / الفواتير ─────────
  static String get ordersSection => _t('الطلبات', 'Orders');
  static String get navOrders => _t('الطلبيات', 'Orders');
  static String get navDeliveries => _t('التسليمات', 'Deliveries');
  static String get navInvoices => _t('الفواتير', 'Invoices');
  static String get tabToDeliver => _t('بانتظار التسليم', 'To deliver');
  static String get tabToBill => _t('بانتظار الفوترة', 'To bill');
  static String get tabCompleted => _t('مكتملة', 'Completed');
  static String get addNewOrder => _t('إضافة طلبية جديدة', 'Add new order');
  static String get ordersRefresh => _t('تحديث', 'Refresh');
  static String get ordersDraftsEmptyMessage => _t(
        'اضغط «إضافة طلبية جديدة» لإنشاء طلبية. تبقى هنا كمسودة إلى أن تعتمدها.',
        'Tap “Add new order” to create one. It stays here as a draft until you submit it.',
      );
  static String get toDeliverEmptyTitle =>
      _t('لا توجد طلبيات بانتظار التسليم', 'No orders waiting for delivery');
  static String get toDeliverEmptyMessage => _t(
        'الطلبية التي تعتمدها تظهر هنا إلى أن تُسلَّم.',
        'Orders you submit appear here until they are delivered.',
      );
  static String get toBillEmptyTitle =>
      _t('لا توجد طلبيات بانتظار الفوترة', 'No orders waiting for billing');
  static String get toBillEmptyMessage => _t(
        'الطلبية التي تُسلَّم تظهر هنا إلى أن تُفوتَر.',
        'Delivered orders appear here until they are billed.',
      );
  static String get completedEmptyTitle =>
      _t('لا توجد طلبيات مكتملة', 'No completed orders');
  static String get completedEmptyMessage => _t(
        'الطلبية التي سُلِّمت وفُوتِرت تظهر هنا.',
        'Orders that are delivered and billed appear here.',
      );
  static String get deliver => _t('تسليم', 'Deliver');
  static String get deliverTitle => _t('تسليم الطلبية؟', 'Deliver this order?');
  static String get deliverMessage => _t(
        'سيُنشأ سند تسليم في ERPNext، وتنتقل الطلبية إلى «بانتظار الفوترة».',
        'A delivery note will be created in ERPNext and the order moves to “To bill”.',
      );
  static String get orderDelivered => _t('تم تسليم الطلبية', 'Order delivered');
  static String get deliverFailed =>
      _t('تعذّر تسليم الطلبية', 'Could not deliver the order');
  static String get ordersRefreshFailed => _t(
        'تعذّر تحديث حالات الطلبيات من ERPNext. تُعرض آخر حالة محفوظة.',
        'Could not update order statuses from ERPNext. Showing the last saved status.',
      );
  // ───────── قسم الفواتير ─────────
  static String get tabUnpaid => _t('غير مدفوعة', 'Unpaid');
  static String get tabPartlyPaid => _t('مدفوعة جزئيًا', 'Partly paid');
  static String get tabPaid => _t('مدفوعة', 'Paid');
  static String get invoicesDraftEmptyTitle =>
      _t('لا توجد فواتير مسودة', 'No draft invoices');
  static String get invoicesDraftEmptyMessage => _t(
        'فواتير المبيعات المسودة في ERPNext تظهر هنا إلى أن تُعتمد.',
        'Draft sales invoices in ERPNext appear here until they are submitted.',
      );
  static String get invoicesUnpaidEmptyTitle =>
      _t('لا توجد فواتير غير مدفوعة', 'No unpaid invoices');
  static String get invoicesUnpaidEmptyMessage => _t(
        'الفواتير التي لم يُدفع منها شيء تظهر هنا.',
        'Invoices with no payment yet appear here.',
      );
  static String get invoicesPartlyEmptyTitle =>
      _t('لا توجد فواتير مدفوعة جزئيًا', 'No partly paid invoices');
  static String get invoicesPartlyEmptyMessage => _t(
        'الفاتورة التي يُدفع جزء من مبلغها تنتقل إلى هنا.',
        'An invoice moves here once part of it is paid.',
      );
  static String get invoicesPaidEmptyTitle =>
      _t('لا توجد فواتير مدفوعة', 'No paid invoices');
  static String get invoicesPaidEmptyMessage => _t(
        'الفواتير التي سُدِّدت بالكامل تظهر هنا.',
        'Fully paid invoices appear here.',
      );
  static String get amountDue => _t('المبلغ المستحق', 'Amount due');
  static String get payAction => _t('دفع', 'Pay');
  static String get payInvoiceTitle => _t('دفع فاتورة', 'Pay invoice');
  static String get payAmountLabel =>
      _t('المبلغ الذي تريد دفعه', 'Amount to pay');
  static String get payNoteLabel => _t('ملاحظة (اختياري)', 'Note (optional)');
  static String get payAmountRequired =>
      _t('أدخل المبلغ', 'Enter the amount');
  static String get payAmountPositive => _t(
        'يجب أن يكون المبلغ أكبر من صفر',
        'The amount must be greater than zero',
      );
  static String payAmountExceeds(String due) => _t(
        'تنبيه: المبلغ أكبر من المستحق ($due). لا يمكن دفع أكثر من المستحق.',
        'Warning: the amount is more than the amount due ($due). You cannot pay more than is due.',
      );
  static String get paySave => _t('حفظ الدفعة', 'Save payment');
  static String get paymentSavedPending => _t(
        'تم حفظ الدفعة. تتغير حالة الفاتورة ومستحقها بعد اعتمادها في ERPNext.',
        'Payment saved. The invoice status and amount due change once it is approved in ERPNext.',
      );
  static String get paymentSaveFailed =>
      _t('تعذّر حفظ الدفعة', 'Could not save the payment');
  static String paymentPending(String amount) => _t(
        'دفعة بانتظار الاعتماد في ERPNext: $amount',
        'Payment awaiting approval in ERPNext: $amount',
      );

  // ───────── قسم التسليمات ─────────
  static String get deliveriesDraftEmptyTitle =>
      _t('لا توجد تسليمات مسودة', 'No draft deliveries');
  static String get deliveriesDraftEmptyMessage => _t(
        'سندات التسليم المسودة التي لم تُعتمد بعد في ERPNext تظهر هنا.',
        'Draft delivery notes that are not yet approved in ERPNext appear here.',
      );
  static String get deliveriesToBillEmptyTitle =>
      _t('لا توجد تسليمات بانتظار الفوترة', 'No deliveries waiting for billing');
  static String get deliveriesToBillEmptyMessage => _t(
        'الطلبية التي تُسلَّمها تظهر هنا إلى أن تُفوتَر.',
        'Orders you deliver appear here until they are billed.',
      );
  static String get deliveriesCompletedEmptyTitle =>
      _t('لا توجد فواتير مكتملة', 'No completed invoices');
  static String get deliveriesCompletedEmptyMessage => _t(
        'الطلبيات التي فوترتها تظهر هنا.',
        'Orders you have billed appear here.',
      );
  static String get deliveryDraftStatus =>
      _t('سند تسليم مسودة', 'Draft delivery note');
  static String get bill => _t('فوترة', 'Bill');
  static String get billTitle => _t('فوترة الطلبية؟', 'Bill this order?');
  static String get billMessage => _t(
        'ستُنشأ فاتورة مبيعات مسودة في ERPNext يعتمدها المسؤول هناك، وتنتقل الطلبية إلى «مكتملة».',
        'A draft sales invoice will be created in ERPNext for the approver to submit, and the order moves to “Completed”.',
      );
  static String get orderBilled => _t(
        'تم إنشاء الفاتورة وهي بانتظار الاعتماد في ERPNext',
        'Invoice created and waiting for approval in ERPNext',
      );
  static String get invoiceAwaitingApproval => _t(
        'فاتورة بانتظار الاعتماد',
        'Invoice awaiting approval',
      );
  static String get billNoDeliveryNote => _t(
        'لا يوجد سند تسليم معتمد لهذه الطلبية في ERPNext.',
        'There is no approved delivery note for this order in ERPNext.',
      );
  static String paymentNoAccountForMode(String mode) => _t(
        'لا يوجد حساب افتراضي لطريقة الدفع ($mode) في الشركة. اضبطه في ERPNext.',
        'No default account for the mode of payment ($mode) in this company. Set it in ERPNext.',
      );
  static String get payWaitingInvoiceApproval => _t(
        'الدفع يتفعّل بعد اعتماد الفاتورة في ERPNext',
        'Payment is enabled once the invoice is approved in ERPNext',
      );
  static String get payFieldRequired =>
      _t('هذا الحقل مطلوب', 'This field is required');
  static String get payRefCheque => _t('رقم الشيك', 'Cheque number');
  static String get payDateCheque => _t('تاريخ الشيك', 'Cheque date');
  static String get payChequeBank => _t('بنك الشيك', 'Cheque bank');
  static String get payDrawerName => _t('اسم الساحب', 'Drawer name');
  static String get payRefCard =>
      _t('رمز الموافقة أو العملية', 'Approval / transaction code');
  static String get payDateCard => _t('تاريخ العملية', 'Transaction date');
  static String get payCardLast4 =>
      _t('آخر 4 أرقام من البطاقة', 'Card last 4 digits');
  static String get payCardLast4Helper => _t(
        'أدخل آخر 4 أرقام فقط. لا تُدخل رقم البطاقة كاملًا.',
        'Enter only the last 4 digits. Never enter the full card number.',
      );
  static String get payCardLast4Invalid =>
      _t('أدخل 4 أرقام بالضبط', 'Enter exactly 4 digits');
  static String get payCardBrand =>
      _t('نوع البطاقة (Visa, Mastercard…)', 'Card brand (Visa, Mastercard…)');
  static String get payRefTransfer =>
      _t('رقم مرجع التحويل', 'Transfer reference');
  static String get payDateTransfer => _t('تاريخ التحويل', 'Transfer date');
  static String get paySenderBank =>
      _t('بنك المُحوِّل (اختياري)', 'Sender bank (optional)');
  static String get payRefGeneric => _t('رقم المرجع', 'Reference number');
  static String get payDateGeneric => _t('تاريخ المرجع', 'Reference date');
  static String get billFailed =>
      _t('تعذّرت فوترة الطلبية', 'Could not bill the order');
  static String get billWaitingApproval => _t(
        'الفوترة تتفعّل بعد اعتماد التسليم في ERPNext',
        'Billing is enabled once the delivery is approved in ERPNext',
      );
  static String get comingSoon => _t('قريبًا', 'Coming soon');
  static String get comingSoonMessage =>
      _t('هذا القسم قيد الإعداد.', 'This section is being set up.');
  static String get settings => _t('الإعدادات', 'Settings');

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
  static String get customerSavedLocalOnly => _t(
        'لا يوجد اتصال بـ ERPNext، فحُفظ العميل على الجهاز فقط.',
        'ERPNext is not reachable, so the customer was saved on this device only.',
      );
  static String get customerPhoneNotSaved => _t(
        'أُنشئ العميل في ERPNext لكن تعذّر تسجيل هاتفه هناك.',
        'The customer was created in ERPNext, but the phone number could not be saved there.',
      );
  static String get customerType => _t('نوع العميل', 'Customer type');
  static String get customerTypeCompany => _t('شركة', 'Company');
  static String get customerTypeIndividual => _t('فرد', 'Individual');
  static String get customerGroup => _t('مجموعة العملاء', 'Customer group');
  static String get customerGroupRequired =>
      _t('اختر مجموعة العميل', 'Select a customer group');
  static String get territory => _t('المنطقة', 'Territory');
  static String get territoryRequired =>
      _t('اختر المنطقة', 'Select a territory');
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
  static String get balancesPerCurrencyNote => _t(
        'كل عملة تُحسب على حدة ولا تُحوَّل إلى أخرى',
        'Each currency is calculated separately, with no conversion',
      );

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

  // ───────── العملة وطريقة الدفع (Payment Entry) ─────────
  static String get currency => _t('العملة', 'Currency');
  static String get modeOfPayment => _t('طريقة الدفع', 'Mode of payment');
  static String get currencyRequired =>
      _t('اختر العملة', 'Select a currency');
  static String get accountCurrency =>
      _t('عملة حساب العميل', 'Customer account currency');
  static String get accountCurrencyHelper => _t(
        'الدفعات بأي عملة أخرى تُحوَّل إلى هذه العملة بسعر الصرف',
        'Payments in any other currency are converted to this currency',
      );
  static String get accountCurrencyAuto =>
      _t('حسب حساب ERPNext', 'Per the ERPNext account');
  static String get modeOfPaymentRequired =>
      _t('اختر طريقة الدفع', 'Select a mode of payment');
  static String get modesOfPaymentUnavailable => _t(
        'تعذّر تحميل طرق الدفع من ERPNext. تحقق من الاتصال ثم أعد فتح النافذة.',
        'Could not load modes of payment from ERPNext. Check the connection and reopen this dialog.',
      );
  static String get paymentCustomerAccountMissing => _t(
        'لم يُعثر على حساب العميل المدين في ERPNext',
        'The customer’s receivable account was not found in ERPNext',
      );
  static String paymentModeAccountMissing(String mode) => _t(
        'لا يوجد حساب لطريقة الدفع «$mode» للشركة في ERPNext',
        'Mode of payment “$mode” has no account for the company in ERPNext',
      );
  static String exchangeRateMissing(String from, String to) => _t(
        'لا يوجد سعر صرف من $from إلى $to في ERPNext',
        'No exchange rate from $from to $to in ERPNext',
      );
  static String paymentNoAccountForCurrency(String currency) => _t(
        'لا يوجد حساب نقدي أو بنكي بعملة $currency للشركة في ERPNext',
        'No cash or bank account in $currency exists for the company in ERPNext',
      );
  static String get invoicesOutstandingTitle =>
      _t('مستحق الفواتير', 'Invoice outstanding');
  static String get accountBalance => _t('رصيد الحساب', 'Account balance');
  static String get noInvoiceOutstanding =>
      _t('لا مبالغ مستحقة في الفواتير', 'No outstanding invoices');
  static String get accountBalanceHint => _t(
        'يشمل الدفعات غير المربوطة بفواتير',
        'Includes payments not linked to invoices',
      );
  static String conversionNote(String to) => _t(
        'سيُحوَّل المبلغ إلى عملة حساب العميل ($to) بسعر صرف ERPNext',
        'The amount is converted to the customer account currency ($to) at the ERPNext rate',
      );
  static String conversionResult(String converted, String from, String rate, String to) =>
      _t(
        '≈ $converted  (1 $from = $rate $to)',
        '≈ $converted  (1 $from = $rate $to)',
      );
  static String get loadingRate =>
      _t('جاري جلب سعر الصرف...', 'Fetching the exchange rate...');
  static String settledAs(String amount, String rate) => _t(
        'سُدِّد بعد التحويل: $amount (سعر الصرف $rate)',
        'Settled after conversion: $amount (rate $rate)',
      );
  static String paymentEntryRef(String name) =>
      _t('سند الدفع: $name', 'Payment Entry: $name');

  // ───────── الفاتورة ─────────
  static String get tabOperations => _t('العمليات', 'Transactions');
  static String get tabInvoice => _t('الفاتورة', 'Invoice');

  // ───────── شاشتا العمليات والفواتير (من تفاصيل العميل) ─────────
  static String get invoicesTitle => _t('الفواتير', 'Invoices');
  static String get invoicesButtonHint =>
      _t('المسودات والفواتير المعتمدة', 'Drafts and submitted invoices');
  static String operationsCount(int n) =>
      _t('$n عملية مسجّلة', '$n recorded transactions');
  static String get tabDraft => _t('مسودة', 'Draft');
  static String get tabSubmitted => _t('معتمدة', 'Submitted');
  static String get draftsEmptyTitle => _t('لا توجد مسودات', 'No drafts');
  static String get draftsEmptyMessage => _t(
        'الطلبيات التي تنشئها لهذا العميل تظهر هنا كمسودات إلى أن تعتمدها.',
        'Orders you create for this customer appear here as drafts until you submit them.',
      );
  static String get draftEdit => _t('تعديل', 'Edit');
  static String get draftApprove => _t('اعتماد', 'Submit');
  static String get draftSubmit => _t('اعتماد الفاتورة', 'Submit invoice');
  static String get editDraftTitle => _t('تعديل المسودة', 'Edit draft');
  static String get draftNeedsUploadNote => _t(
        'هذه المسودة لم تُرفع إلى ERPNext بعد. ستُرفع تلقائيًا عند عودة الاتصال، ثم يمكنك اعتمادها.',
        'This draft has not been uploaded to ERPNext yet. It uploads automatically when the connection returns, then you can submit it.',
      );
  static String get draftDeleteTitle => _t('حذف المسودة؟', 'Delete draft?');
  static String get draftDeleteMessage => _t(
        'ستُحذف هذه المسودة نهائيًا، ولا يمكن التراجع عن ذلك.',
        'This draft will be permanently deleted. This cannot be undone.',
      );
  static String get draftSubmitTitle =>
      _t('اعتماد الفاتورة؟', 'Submit this invoice?');
  static String get draftSubmitMessage => _t(
        'بعد الاعتماد تنتقل إلى تبويب «معتمدة» ولا يمكن تعديلها أو حذفها.',
        'After submitting it moves to the “Submitted” tab and can no longer be edited or deleted.',
      );
  static String get draftDeleted => _t('تم حذف المسودة', 'Draft deleted');
  static String get draftSubmitted =>
      _t('تم اعتماد الفاتورة', 'Invoice submitted');
  static String get draftUpdated => _t('تم حفظ التعديلات', 'Changes saved');
  static String get draftNeedsConnection => _t(
        'لا يوجد اتصال بـ ERPNext. هذا الإجراء يحتاج اتصالًا.',
        'ERPNext is not reachable. This action needs a connection.',
      );
  static String get draftSaveFailed =>
      _t('تعذّر حفظ التعديلات', 'Could not save the changes');
  static String get draftDeleteFailed =>
      _t('تعذّر حذف المسودة', 'Could not delete the draft');
  static String get draftSubmitFailed =>
      _t('تعذّر اعتماد الفاتورة', 'Could not submit the invoice');
  static String get draftStateChanged => _t(
        'تغيّرت حالة هذه المسودة. ارجع إلى القائمة وافتحها من جديد.',
        'This draft changed. Go back to the list and open it again.',
      );
  static String get draftNoItems => _t(
        'يجب أن تبقى في المسودة صنف واحد على الأقل. لإلغائها احذفها.',
        'A draft needs at least one item. To cancel it, delete it.',
      );
  static String get printInvoice => _t('طباعة', 'Print');
  static String get invoiceTitle => _t('فاتورة', 'Invoice');
  static String get invoiceNumber => _t('رقم الفاتورة', 'Invoice no.');
  static String get invoiceCustomer => _t('اسم العميل', 'Customer name');
  static String get invoiceAmount => _t('مبلغ الفاتورة', 'Invoice amount');
  static String get viewInvoicePdf => _t('عرض الفاتورة PDF', 'View invoice PDF');
  static String get invoicePdfFailed =>
      _t('تعذّر إنشاء ملف PDF', 'Could not create the PDF file');

  // ───────── ERPNext (الفواتير فقط) ─────────
  static String get erpSessionExpired => _t(
        'انتهت جلسة الدخول. سجّل الدخول من جديد.',
        'Your session has expired. Please sign in again.',
      );
  static String get erpForbidden => _t(
        'ليس لديك صلاحية لهذا الإجراء.',
        "You don't have permission for this.",
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
        'Pending Upload' => _t('بانتظار الرفع', 'Waiting to upload'),
        'Submitted' => _t('معتمدة', 'Submitted'),
        'To Deliver' => _t('بانتظار التسليم', 'Waiting for delivery'),
        'To Bill' => _t('بانتظار الفوترة', 'Waiting for billing'),
        'Completed' => _t('مكتملة', 'Completed'),
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
  static String get orderNotes => _t('ملاحظات', 'Notes');
  static String get orderNotesHint => _t(
        'أضف ملاحظات على الطلبية (اختياري)',
        'Add notes to the order (optional)',
      );
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

  // ───────── عملة الطلبية ─────────
  static String get orderRateLoading =>
      _t('جاري جلب سعر الصرف...', 'Fetching the exchange rate...');
  static String get orderRateNeedsConnection => _t(
        'عملة هذا العميل ليست الشيكل، ويلزم اتصال بـ ERPNext لجلب سعر الصرف.',
        'This customer’s currency is not the shekel; a connection to ERPNext is needed to fetch the exchange rate.',
      );
  static String get orderRateFailed => _t(
        'تعذّر جلب سعر الصرف. حاول مرة أخرى.',
        'Could not fetch the exchange rate. Please try again.',
      );
  static String orderCurrencyInfo(String currency, double rate) {
    final text = rate
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return _t(
      'عملة الطلبية: $currency • 1 $currency = $text ₪',
      'Order currency: $currency • 1 $currency = $text ₪',
    );
  }
  static String get orderOfflineNeedsConnection => _t(
        'الطلبية بعملة غير الشيكل تحتاج اتصالًا بـ ERPNext لتحديد سعر الصرف، فلا تُحفظ دون اتصال.',
        'An order in a non-shekel currency needs ERPNext to get the exchange rate, so it cannot be saved offline.',
      );

  // ───────── طلبية دون اتصال ─────────
  static String get orderSavedOfflineTitle =>
      _t('تم حفظ الطلبية على الجهاز', 'Order saved on this device');
  static String get orderWaitingUpload =>
      _t('بانتظار الرفع إلى ERPNext', 'Waiting to upload to ERPNext');
  static String get orderSavedOfflineNote => _t(
        'لا يوجد اتصال بـ ERPNext الآن. ستُرفع الطلبية تلقائيًا عند عودة الاتصال، ويمكنك متابعتها من الإعدادات.',
        'ERPNext is not reachable right now. The order will upload automatically when the connection returns; you can follow it in Settings.',
      );
  static String get orderOfflineSaveFailed => _t(
        'تعذّر حفظ الطلبية على الجهاز',
        'Could not save the order on this device',
      );

  // ───────── الإعدادات والمزامنة ─────────
  static String get syncCustomersTitle =>
      _t('مزامنة العملاء', 'Customers sync');
  static String get syncCustomersDesc => _t(
        'جلب أسماء العملاء وهواتفهم من ERPNext وحفظها على الجهاز.',
        'Fetch customer names and phones from ERPNext and keep them on this device.',
      );
  static String get syncItemsTitle => _t('مزامنة الأصناف', 'Items sync');
  static String get syncItemsDesc => _t(
        'جلب المجموعات والأصناف وأسعارها ومخزونها لإنشاء الطلبيات دون إنترنت.',
        'Fetch groups, items, prices and stock so orders can be created offline.',
      );
  static String get syncInvoicesTitle =>
      _t('مزامنة الفواتير', 'Invoices sync');
  static String get syncInvoicesDesc => _t(
        'رفع الطلبيات المحفوظة على الجهاز إلى ERPNext، ثم جلب فواتير العملاء وحفظها.',
        'Upload the orders saved on this device to ERPNext, then fetch and keep customer invoices.',
      );
  static String get syncNow => _t('مزامنة الآن', 'Sync now');
  static String get syncRunning => _t('جارٍ المزامنة...', 'Syncing...');
  static String get neverSynced =>
      _t('لم تتم المزامنة بعد', 'Not synced yet');
  static String lastSynced(String when) =>
      _t('آخر مزامنة: $when', 'Last sync: $when');
  static String syncedCustomers(int n) => _t('$n عميل', '$n customers');
  static String syncedItems(int items, int groups) =>
      _t('$items صنف في $groups مجموعة', '$items items in $groups groups');
  static String syncedInvoices(int n) => _t('$n فاتورة', '$n invoices');
  static String get syncFailed => _t(
        'تعذّرت المزامنة. حاول مرة أخرى.',
        'Sync failed. Please try again.',
      );
  static String get syncCustomersFirst => _t(
        'زامن العملاء أولًا ليرتبط كل عميل بـ ERPNext.',
        'Sync customers first so each customer is linked to ERPNext.',
      );
  static String get autoUploadNote => _t(
        'الطلبيات المنشأة دون اتصال تُرفع تلقائيًا عند عودة الاتصال.',
        'Orders created offline upload automatically when the connection returns.',
      );
  static String pendingOrdersCount(int n) =>
      _t('طلبيات بانتظار الرفع: $n', 'Orders waiting to upload: $n');
  static String failedOrdersCount(int n) => _t(
        'طلبيات رفضها الخادم: $n (اضغط «مزامنة الآن» لإعادة المحاولة)',
        'Orders rejected by the server: $n (tap “Sync now” to retry)',
      );

  static String syncStep(SyncStep step) => switch (step) {
        SyncStep.customers => _t('جلب العملاء...', 'Fetching customers...'),
        SyncStep.groups => _t('جلب المجموعات...', 'Fetching groups...'),
        SyncStep.items => _t('جلب الأصناف...', 'Fetching items...'),
        SyncStep.prices => _t('جلب الأسعار...', 'Fetching prices...'),
        SyncStep.stock => _t('جلب المخزون...', 'Fetching stock...'),
        SyncStep.saving => _t('الحفظ على الجهاز...', 'Saving to device...'),
        SyncStep.uploadingOrders =>
          _t('رفع الطلبيات المحفوظة...', 'Uploading saved orders...'),
        SyncStep.invoicesList => _t('جلب الفواتير...', 'Fetching invoices...'),
        SyncStep.invoiceDetails =>
          _t('جلب تفاصيل أحدث الفواتير...', 'Fetching latest invoice details...'),
      };

  // ───────── تسجيل الدخول ─────────
  static String get loginTitle => _t('تسجيل الدخول', 'Sign in');
  static String get loginSubtitle => _t(
         '',
        '',
      );
  static String get emailLabel => _t('البريد الإلكتروني', 'Email');
  static String get siteLabel => _t('اسم الموقع أو عنوان الخادم', 'Site name or server address');
  static String get siteHelper => _t(
        '',
        '',
      );
  static String get siteInvalid =>
      _t('الرجاء إدخال اسم موقع أو عنوان صالح', 'Enter a valid site name or address');
  static String get passwordLabel => _t('كلمة المرور', 'Password');
  static String get emailRequired =>
      _t('الرجاء إدخال البريد الإلكتروني', 'Please enter your email');
  static String get passwordRequired =>
      _t('الرجاء إدخال كلمة المرور', 'Please enter your password');
  static String get loginButton => _t('دخول', 'Sign in');
  static String get loggingIn => _t('جارٍ تسجيل الدخول...', 'Signing in...');
  static String get loginInvalid => _t(
        'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
        'Incorrect email or password.',
      );
  static String get loginNetworkError => _t(
        'تعذّر الاتصال بالخادم. تأكد من الاتصال وحاول مرة أخرى.',
        'Could not reach the server. Check your connection and try again.',
      );
  static String get loginServerError => _t(
        'ردّ الخادم بخطأ غير متوقع. حاول لاحقًا.',
        'The server returned an unexpected error. Please try again later.',
      );
  static String get loginLockWarning => _t(
        'تنبيه: تكرار المحاولات الخاطئة قد يقفل الحساب مؤقتًا.',
        'Note: repeated failed attempts may temporarily lock the account.',
      );
  static String get sessionExpiredNotice => _t(
        'انتهت جلستك. سجّل الدخول من جديد للمتابعة.',
        'Your session has expired. Sign in again to continue.',
      );
  static String get showPassword => _t('إظهار كلمة المرور', 'Show password');
  static String get hidePassword => _t('إخفاء كلمة المرور', 'Hide password');
  static String get logout => _t('تسجيل الخروج', 'Sign out');
  static String get logoutConfirmTitle =>
      _t('تسجيل الخروج', 'Sign out');
  static String get logoutConfirmMessage => _t(
        'هل تريد تسجيل الخروج من حسابك؟ الطلبيات المحفوظة على الجهاز تبقى وتُرفع عند الدخول مرة أخرى.',
        'Do you want to sign out? Orders saved on this device are kept and uploaded after you sign in again.',
      );

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
