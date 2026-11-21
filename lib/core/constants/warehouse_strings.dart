import 'package:get/get.dart';

import 'app_strings.dart';

/// نصوص قسم «المستودعات» (عربي/إنجليزي). النصوص في lib/app/translations (ar.dart / en.dart) وتُقرأ هنا بـ .tr.
class WarehouseStrings {
  WarehouseStrings._();

  /// كمية بلا أصفار زائدة مع الوحدة: «5 Nos» أو «2.5 Kg»
  static String qty(double v, [String uom = '']) {
    final text = v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
    return uom.isEmpty ? text : '$text $uom';
  }

  static String get section => 'warehouse.section'.tr;

  // المستودعات
  static String get loadingWarehouses => 'warehouse.loadingWarehouses'.tr;
  static String get noWarehouses => 'warehouse.noWarehouses'.tr;
  static String get loadFailed => 'warehouse.loadFailed'.tr;
  static String parent(String p) => 'warehouse.parent'.trParams({'p': p});

  // أصناف المستودع
  static String get loadingItems => 'warehouse.loadingItems'.tr;
  static String get noItems => 'warehouse.noItems'.tr;
  static String get searchItems => 'warehouse.searchItems'.tr;
  static String itemsCount(int n) =>
      'warehouse.itemsCount'.trParams({'n': '$n'});
  static String get actual => 'warehouse.actual'.tr;
  static String get reserved => 'warehouse.reserved'.tr;
  static String get available => 'warehouse.available'.tr;
  static String get transferFromHere => 'warehouse.transferFromHere'.tr;

  // النقل
  static String get newTransfer => 'warehouse.newTransfer'.tr;
  static String get from => 'warehouse.from'.tr;
  static String get to => 'warehouse.to'.tr;
  static String get chooseWarehouse => 'warehouse.chooseWarehouse'.tr;
  static String get sameWarehouse => 'warehouse.sameWarehouse'.tr;
  static String get chooseSourceFirst => 'warehouse.chooseSourceFirst'.tr;
  static String get remarks => 'warehouse.remarks'.tr;
  static String get quantity => 'warehouse.quantity'.tr;
  static String get remove => 'warehouse.remove'.tr;
  static String get add => 'warehouse.add'.tr;
  static String get cancel => AppStrings.cancel;
  static String selectedCount(int n) =>
      'warehouse.selectedCount'.trParams({'n': '$n'});
  static String saveDraft(int n) => 'warehouse.saveDraft'.trParams({'n': '$n'});
  static String get noLines => 'warehouse.noLines'.tr;
  static String savedDraft(String name) =>
      'warehouse.savedDraft'.trParams({'name': name});
  static String get saveFailed => 'warehouse.saveFailed'.tr;

  // التحقق من الكمية
  static String get qtyPositive => 'warehouse.qtyPositive'.tr;
  static String qtyAboveActual(String max) =>
      'warehouse.qtyAboveActual'.trParams({'max': max});
  static String qtyWhole(String uom) =>
      'warehouse.qtyWhole'.trParams({'uom': uom});
  static String qtyReservedWarning(String available) =>
      'warehouse.qtyReservedWarning'.trParams({'available': available});
  static String get reservedConfirmTitle => 'warehouse.reservedConfirmTitle'.tr;
  static String reservedConfirmMessage(String items) =>
      'warehouse.reservedConfirmMessage'.trParams({'items': items});
  static String get continueAnyway => 'warehouse.continueAnyway'.tr;

  // بانتظار الاعتماد
  static String get pendingTitle => 'warehouse.pendingTitle'.tr;
  static String get loadingPending => 'warehouse.loadingPending'.tr;
  static String get noPending => 'warehouse.noPending'.tr;
  static String get showItems => 'warehouse.showItems'.tr;
  static String get approve => 'warehouse.approve'.tr;
  static String get reject => 'warehouse.reject'.tr;
  static String approveTitle(String name) =>
      'warehouse.approveTitle'.trParams({'name': name});
  static String get approveMessage => 'warehouse.approveMessage'.tr;
  static String rejectTitle(String name) =>
      'warehouse.rejectTitle'.trParams({'name': name});
  static String get rejectMessage => 'warehouse.rejectMessage'.tr;
  static String approved(String name) =>
      'warehouse.approved'.trParams({'name': name});
  static String rejected(String name) =>
      'warehouse.rejected'.trParams({'name': name});
  static String get approveFailed => 'warehouse.approveFailed'.tr;
  static String get rejectFailed => 'warehouse.rejectFailed'.tr;
}
