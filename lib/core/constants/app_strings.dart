/// كل النصوص الظاهرة للمستخدم في مكان واحد.
/// (عند إضافة لغة ثانية لاحقًا يسهل نقلها إلى ملفات ترجمة.)
class AppStrings {
  AppStrings._();

  // ───────── عام ─────────
  static const appName = 'دفتر الديون';
  static const save = 'حفظ';
  static const cancel = 'إلغاء';
  static const retry = 'إعادة المحاولة';
  static const errorTitle = 'حدث خطأ';

  // ───────── شاشة العملاء ─────────
  static const customers = 'العملاء';
  static const addCustomer = 'إضافة عميل';
  static const addCustomerTitle = 'إضافة عميل جديد';
  static const addFirstCustomer = 'إضافة أول عميل';
  static const searchHint = 'ابحث باسم العميل...';
  static const loadingCustomers = 'جاري تحميل العملاء...';
  static const noCustomersTitle = 'لا يوجد عملاء بعد';
  static const noCustomersMessage = 'ابدأ بإضافة أول عميل لتسجيل ديونه ودفعاته.';
  static const noSearchResultsTitle = 'لا توجد نتائج مطابقة';
  static const noSearchResultsMessage = 'جرّب البحث باسم آخر.';
  static const customerAdded = 'تمت إضافة العميل';
  static const customerSaveFailed = 'تعذّر حفظ العميل';
  static const totalDebts = 'إجمالي الديون';
  static const loadCustomersError = 'تعذّر تحميل العملاء. حاول مرة أخرى.';
  static const loadMoreCustomersError = 'تعذّر تحميل المزيد من العملاء';
  static const unknownInitial = '؟';

  // ───────── الحقول والتحقق ─────────
  static const name = 'الاسم';
  static const phone = 'رقم الهاتف';
  static const nameRequired = 'الرجاء إدخال الاسم';
  static const phoneRequired = 'الرجاء إدخال رقم الهاتف';
  static const amount = 'المبلغ';
  static const noteOptional = 'ملاحظة (اختياري)';
  static const amountInvalid = 'الرجاء إدخال مبلغ صحيح';
  static const amountMustBePositive = 'يجب أن يكون المبلغ أكبر من صفر';

  // ───────── تعديل العميل ─────────
  static const editCustomer = 'تعديل';
  static const editCustomerTitle = 'تعديل بيانات العميل';
  static const saveChanges = 'حفظ التغييرات';
  static const phoneInvalid = 'رقم الهاتف يجب أن يتكون من 10 أرقام ويبدأ بـ 05';
  static const phoneHint = '05XXXXXXXX';
  static const customerUpdated = 'تم حفظ التعديلات';
  static const customerUpdateFailed = 'تعذّر حفظ التعديلات';

  // ───────── حذف العميل ─────────
  static const delete = 'حذف';
  static const undo = 'تراجع';
  static const deleteCustomerTitle = 'حذف العميل';
  static const deleteCustomerMessage = 'هل أنت متأكد من حذف هذا العميل وكل عملياته؟';
  static const customerDeleteFailed = 'تعذّر حذف العميل';
  static const customerRestored = 'تمت استعادة العميل';
  static const customerRestoreFailed = 'تعذّرت استعادة العميل';
  static String customerDeleted(String name) => 'تم حذف «$name»';

  // ───────── واتساب ─────────
  static const whatsappButton = 'إرسال تذكير عبر واتساب';
  static const whatsappNotInstalled = 'تطبيق واتساب غير مثبّت على هذا الجهاز';
  static const whatsappInvalidPhone = 'رقم هاتف العميل غير صالح لفتح واتساب';
  static const whatsappNoDebt = 'لا يوجد مبلغ مستحق على هذا العميل';
  static const whatsappFailed = 'تعذّر فتح واتساب. حاول مرة أخرى';

  /// نص الرسالة الجاهزة (اسم العميل والمبلغ المستحق عليه)
  static String whatsappDebtMessage(String name, String amount) =>
      'مرحبًا $name،\n'
      'نود تذكيرك بأن المبلغ المستحق عليك هو $amount.\n'
      'نرجو التكرم بالتسديد في أقرب وقت. شكرًا لك.';

  // ───────── حالة الرصيد ─────────
  static const owed = 'مستحق';
  static const hasCredit = 'له رصيد';
  static const settled = 'مسدد';
  static const balanceOwedLong = 'الرصيد المستحق على العميل';
  static const balanceCreditLong = 'للعميل رصيد عندك';
  static const balanceSettledLong = 'الحساب مسدد';

  // ───────── العمليات (شاشة التفاصيل) ─────────
  static const addDebt = 'إضافة دين';
  static const addPayment = 'إضافة دفعة';
  static const debt = 'دين';
  static const payment = 'دفعة';
  static const debtAdded = 'تمت إضافة الدين';
  static const paymentAdded = 'تمت إضافة الدفعة';
  static const operationsLog = 'سجل العمليات';
  static const noOperationsTitle = 'لا توجد عمليات بعد';
  static const noOperationsMessage = 'أضف دينًا أو دفعة من الزرين أعلاه.';
  static const loadOperationsError = 'تعذّر تحميل عمليات العميل. حاول مرة أخرى.';
  static const operationSaveFailed = 'تعذّر حفظ العملية';

  // ───────── للتطوير فقط (debug) ─────────
  static String addFakeCustomersTooltip(int n) => 'للتطوير: إضافة $n عميل وهمي';
  static String fakeCustomersAdded(int n) => 'تمت إضافة $n عميل وهمي';
  static const fakeCustomersFailed = 'تعذّرت إضافة العملاء الوهميين';
}