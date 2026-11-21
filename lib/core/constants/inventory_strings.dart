import 'package:get/get.dart';

/// نصوص قسم «الجرد» (عربي/إنجليزي). النصوص في lib/app/translations (ar.dart / en.dart) وتُقرأ هنا بـ .tr.
class InventoryStrings {
  InventoryStrings._();

  static String get section => 'inventory.section'.tr;

  // حقل الباركود
  static String get barcodeLabel => 'inventory.barcodeLabel'.tr;
  static String get barcodeHint => 'inventory.barcodeHint'.tr;
  static String get scanWithCamera => 'inventory.scanWithCamera'.tr;
  static String get search => 'inventory.search'.tr;

  // الماسح
  static String get scannerTitle => 'inventory.scannerTitle'.tr;
  static String get scannerHint => 'inventory.scannerHint'.tr;
  static String get torch => 'inventory.torch'.tr;
  static String get switchCamera => 'inventory.switchCamera'.tr;

  // الحالة الأولى والنتيجة
  static String get startTitle => 'inventory.startTitle'.tr;
  static String get startMessage => 'inventory.startMessage'.tr;
  static String notFound(String code) =>
      'inventory.notFound'.trParams({'code': code});
  static String get lookupFailed => 'inventory.lookupFailed'.tr;

  static String get itemCode => 'inventory.itemCode'.tr;
  static String get warehouse => 'inventory.warehouse'.tr;
  static String get currentQty => 'inventory.currentQty'.tr;

  // التعديل
  static String get newQty => 'inventory.newQty'.tr;
  static String get invalidNumber => 'inventory.invalidNumber'.tr;
  static String get negativeNotAllowed => 'inventory.negativeNotAllowed'.tr;
  static String get saveChanges => 'inventory.saveChanges'.tr;
  static String get nothingChanged => 'inventory.nothingChanged'.tr;

  // نتائج الحفظ
  static String get savedStockApplied => 'inventory.savedStockApplied'.tr;
  static String get savedStockDraft => 'inventory.savedStockDraft'.tr;
  static String get saveFailed => 'inventory.saveFailed'.tr;

  // ───── قائمة الجرد (عدة أصناف) ─────
  static String get listEmptyTitle => 'inventory.listEmptyTitle'.tr;
  static String get listEmptyMessage => 'inventory.listEmptyMessage'.tr;
  static String added(String name) =>
      'inventory.added'.trParams({'name': name});
  static String get alreadyInList => 'inventory.alreadyInList'.tr;
  static String get serialBatchBlocked => 'inventory.serialBatchBlocked'.tr;
  static String get countedQty => 'inventory.countedQty'.tr;
  static String get valuationRate => 'inventory.valuationRate'.tr;
  static String get rateRequired => 'inventory.rateRequired'.tr;
  static String get remove => 'inventory.remove'.tr;
  static String get clearAll => 'inventory.clearAll'.tr;

  static String get purposeCount => 'inventory.purposeCount'.tr;
  static String get purposeOpening => 'inventory.purposeOpening'.tr;

  static String approveAndSend(int n) =>
      'inventory.approveAndSend'.trParams({'n': '$n'});
  static String get confirmTitle => 'inventory.confirmTitle'.tr;
  static String confirmBody(int n) =>
      'inventory.confirmBody'.trParams({'n': '$n'});
  static String get cancel => 'inventory.cancel'.tr;
  static String get send => 'inventory.send'.tr;
  static String get fixErrors => 'inventory.fixErrors'.tr;
  static String sent(String id) => 'inventory.sent'.trParams({'id': id});
}
