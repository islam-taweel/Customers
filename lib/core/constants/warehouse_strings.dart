import 'app_strings.dart';

/// نصوص قسم «المستودعات» (عربي/إنجليزي). اللغة الحالية من [AppStrings.isArabic].
class WarehouseStrings {
  WarehouseStrings._();

  static String _t(String ar, String en) => AppStrings.isArabic ? ar : en;

  /// كمية بلا أصفار زائدة مع الوحدة: «5 Nos» أو «2.5 Kg»
  static String qty(double v, [String uom = '']) {
    final text = v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
    return uom.isEmpty ? text : '$text $uom';
  }

  static String get section => _t('المستودعات', 'Warehouses');

  // المستودعات
  static String get loadingWarehouses =>
      _t('جارٍ تحميل المستودعات...', 'Loading warehouses...');
  static String get noWarehouses => _t('لا توجد مستودعات', 'No warehouses');
  static String get loadFailed =>
      _t('تعذّر تحميل البيانات', 'Could not load the data');
  static String parent(String p) => _t('ضمن: $p', 'Under: $p');

  // أصناف المستودع
  static String get loadingItems =>
      _t('جارٍ تحميل الأصناف...', 'Loading items...');
  static String get noItems =>
      _t('لا توجد أصناف في هذا المستودع', 'No items in this warehouse');
  static String get searchItems =>
      _t('ابحث باسم الصنف أو رمزه', 'Search by item name or code');
  static String itemsCount(int n) => _t('$n صنف', '$n items');
  static String get actual => _t('الموجود', 'In stock');
  static String get reserved => _t('محجوز', 'Reserved');
  static String get available => _t('المتاح', 'Available');
  static String get transferFromHere =>
      _t('نقل من هذا المستودع', 'Transfer from here');

  // النقل
  static String get newTransfer => _t('نقل أصناف', 'Transfer items');
  static String get from => _t('من مستودع', 'From warehouse');
  static String get to => _t('إلى مستودع', 'To warehouse');
  static String get chooseWarehouse => _t('اختر المستودع', 'Choose a warehouse');
  static String get sameWarehouse => _t(
        'المستودع المصدر والهدف يجب أن يكونا مختلفين',
        'Source and destination must be different',
      );
  static String get chooseSourceFirst => _t(
        'اختر المستودع المصدر لعرض أصنافه',
        'Choose the source warehouse to see its items',
      );
  static String get remarks => _t('سبب النقل (اختياري)', 'Reason (optional)');
  static String get quantity => _t('الكمية', 'Quantity');
  static String get remove => _t('إزالة', 'Remove');
  static String get add => _t('إضافة', 'Add');
  static String get cancel => AppStrings.cancel;
  static String selectedCount(int n) =>
      _t('$n صنف محدد', '$n items selected');
  static String saveDraft(int n) =>
      _t('حفظ النقل مسودة ($n)', 'Save transfer as draft ($n)');
  static String get noLines =>
      _t('اختر صنفًا واحدًا على الأقل', 'Choose at least one item');
  static String savedDraft(String name) => _t(
        'حُفظ النقل $name مسودة. لا يتحرك المخزون إلا بعد الاعتماد',
        'Transfer $name saved as draft. Stock moves only after approval',
      );
  static String get saveFailed =>
      _t('تعذّر حفظ النقل', 'Could not save the transfer');

  // التحقق من الكمية
  static String get qtyPositive =>
      _t('الكمية يجب أن تكون أكبر من صفر', 'Quantity must be above 0');
  static String qtyAboveActual(String max) => _t(
        'الكمية أكبر من الموجود في المستودع ($max)',
        'Quantity is above the stock in the warehouse ($max)',
      );
  static String qtyWhole(String uom) => _t(
        'الوحدة $uom لا تقبل كسورًا',
        'The unit $uom must be a whole number',
      );
  static String qtyReservedWarning(String available) => _t(
        'تنبيه: الكمية أكبر من المتاح ($available)، والفرق محجوز لأوامر بيع',
        'Warning: above the available qty ($available); the rest is promised to sales orders',
      );
  static String get reservedConfirmTitle =>
      _t('كميات محجوزة', 'Reserved stock');
  static String reservedConfirmMessage(String items) => _t(
        'هذه الأصناف ستُنقل من كمية محجوزة لأوامر بيع:\n$items\n\nهل تريد المتابعة؟',
        'These items will use stock promised to sales orders:\n$items\n\nContinue?',
      );
  static String get continueAnyway => _t('متابعة', 'Continue');

  // بانتظار الاعتماد
  static String get pendingTitle =>
      _t('نقل بانتظار الاعتماد', 'Transfers awaiting approval');
  static String get loadingPending =>
      _t('جارٍ تحميل قيود النقل...', 'Loading transfers...');
  static String get noPending =>
      _t('لا يوجد نقل بانتظار الاعتماد', 'No transfers awaiting approval');
  static String get showItems => _t('عرض الأصناف', 'Show items');
  static String get approve => _t('اعتماد', 'Approve');
  static String get reject => _t('رفض', 'Reject');
  static String approveTitle(String name) =>
      _t('اعتماد النقل $name؟', 'Approve transfer $name?');
  static String get approveMessage => _t(
        'سيتحرك المخزون فعليًا بين المستودعين، ولا يمكن التراجع إلا بإلغاء القيد في ERPNext.',
        'Stock will actually move between the warehouses; undoing it needs cancelling the entry in ERPNext.',
      );
  static String rejectTitle(String name) =>
      _t('رفض النقل $name؟', 'Reject transfer $name?');
  static String get rejectMessage =>
      _t('ستُحذف المسودة من ERPNext.', 'The draft will be deleted from ERPNext.');
  static String approved(String name) =>
      _t('اعتُمد النقل $name وتحرك المخزون', 'Transfer $name approved; stock moved');
  static String rejected(String name) =>
      _t('رُفض النقل $name وحُذف', 'Transfer $name rejected and deleted');
  static String get approveFailed =>
      _t('تعذّر اعتماد النقل', 'Could not approve the transfer');
  static String get rejectFailed =>
      _t('تعذّر رفض النقل', 'Could not reject the transfer');
}
