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
