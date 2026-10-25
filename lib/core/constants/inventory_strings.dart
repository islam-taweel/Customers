import 'app_strings.dart';

/// نصوص قسم «الجرد» (عربي/إنجليزي). اللغة الحالية من [AppStrings.isArabic].
class InventoryStrings {
  InventoryStrings._();

  static String _t(String ar, String en) => AppStrings.isArabic ? ar : en;

  static String get section => _t('الجرد', 'Inventory count');

  // حقل الباركود
  static String get barcodeLabel => _t('الباركود', 'Barcode');
  static String get barcodeHint => _t(
        'اكتب الباركود أو امسحه بالكاميرا',
        'Type the barcode or scan it with the camera',
      );
  static String get scanWithCamera =>
      _t('مسح بالكاميرا', 'Scan with camera');
  static String get search => _t('بحث', 'Search');

  // الماسح
  static String get scannerTitle => _t('مسح الباركود', 'Scan barcode');
  static String get scannerHint => _t(
        'وجّه الكاميرا نحو الباركود',
        'Point the camera at the barcode',
      );
  static String get torch => _t('الفلاش', 'Flash');
  static String get switchCamera => _t('تبديل الكاميرا', 'Switch camera');

  // الحالة الأولى والنتيجة
  static String get startTitle => _t('ابدأ الجرد', 'Start counting');
  static String get startMessage => _t(
        'أدخل الباركود أو امسحه بالكاميرا لتظهر بيانات الصنف.',
        'Enter or scan a barcode to see the item.',
      );
  static String notFound(String code) => _t(
        'لا يوجد صنف بهذا الباركود: $code',
        'No item found for barcode: $code',
      );
  static String get lookupFailed =>
      _t('تعذّر البحث عن الصنف', 'Could not look up the item');

  static String get itemCode => _t('رمز الصنف', 'Item code');
  static String get warehouse => _t('المستودع', 'Warehouse');
  static String get currentQty => _t('الكمية الحالية', 'Current quantity');

  // التعديل
  static String get newQty => _t('الكمية الجديدة (الفعلية)', 'New quantity (counted)');
  static String get invalidNumber =>
      _t('أدخل رقمًا صحيحًا', 'Enter a valid number');
  static String get negativeNotAllowed =>
      _t('لا يمكن أن تكون القيمة سالبة', 'The value cannot be negative');
  static String get saveChanges => _t('حفظ الكمية', 'Save quantity');
  static String get nothingChanged =>
      _t('لم تتغير الكمية', 'The quantity did not change');

  // نتائج الحفظ
  static String get savedStockApplied =>
      _t('تم تعديل الكمية', 'Quantity updated');
  static String get savedStockDraft => _t(
        'أُنشئت تسوية مخزون مسودة بانتظار الاعتماد في ERPNext',
        'A draft stock reconciliation was created for approval in ERPNext',
      );
  static String get saveFailed =>
      _t('تعذّر حفظ التعديل', 'Could not save the changes');

  // ───── قائمة الجرد (عدة أصناف) ─────
  static String get listEmptyTitle => _t('القائمة فارغة', 'The list is empty');
  static String get listEmptyMessage => _t(
        'امسح باركود كل صنف لإضافته، ثم عدّل كمية كل صنف على حدة.',
        'Scan each item to add it, then adjust each quantity separately.',
      );
  static String added(String name) => _t('أُضيف: $name', 'Added: $name');
  static String get alreadyInList =>
      _t('الصنف موجود في القائمة، عدّل كميته منها',
          'Item is already in the list; edit its quantity there');
  static String get serialBatchBlocked => _t(
        'صنف برقم تسلسلي/دفعة: لا يدخل في هذه القائمة، أبلغ المسؤول',
        'Serial/batch item: not allowed in this list, tell the manager',
      );
  static String get countedQty => _t('الكمية المعدودة', 'Counted quantity');
  static String get valuationRate =>
      _t('تكلفة الوحدة (مطلوبة)', 'Unit cost (required)');
  static String get rateRequired =>
      _t('الصنف بلا رصيد: أدخل تكلفة الوحدة', 'No stock yet: enter the unit cost');
  static String get remove => _t('حذف من القائمة', 'Remove from list');
  static String get clearAll => _t('تفريغ القائمة', 'Clear list');

  static String get purposeCount => _t('جرد', 'Count');
  static String get purposeOpening => _t('رصيد افتتاحي', 'Opening stock');

  static String approveAndSend(int n) =>
      _t('اعتماد وإرسال ($n)', 'Approve & send ($n)');
  static String get confirmTitle => _t('إرسال القائمة؟', 'Send the list?');
  static String confirmBody(int n) => _t(
        'سيتم إرسال $n صنف إلى ERPNext كمسودة تسوية مخزون.',
        '$n items will be sent to ERPNext as a draft stock reconciliation.',
      );
  static String get cancel => _t('إلغاء', 'Cancel');
  static String get send => _t('إرسال', 'Send');
  static String get fixErrors => _t(
        'صحّح الأخطاء المعلّمة في القائمة قبل الإرسال',
        'Fix the marked errors in the list before sending',
      );
  static String sent(String id) => _t(
        'أُرسلت القائمة: $id (مسودة بانتظار اعتماد المسؤول)',
        'List sent: $id (draft awaiting manager approval)',
      );
}
