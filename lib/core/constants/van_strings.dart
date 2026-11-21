import 'package:get/get.dart';

import 'app_strings.dart';

/// نصوص قسم «مبيعات الفان» (عربي/إنجليزي). النصوص في lib/app/translations (ar.dart / en.dart) وتُقرأ هنا بـ .tr.
class VanStrings {
  VanStrings._();

  static String get section => 'van.section'.tr;
  static String get stockTitle => 'van.stockTitle'.tr;
  static String get loading => 'van.loading'.tr;
  static String get loadFailed => 'van.loadFailed'.tr;
  static String get searchHint => 'van.searchHint'.tr;
  static String get scan => 'van.scan'.tr;
  static String get empty => 'van.empty'.tr;
  static String get emptyHint => 'van.emptyHint'.tr;
  static String get noMatch => 'van.noMatch'.tr;
  static String productsCount(int n) =>
      'van.productsCount'.trParams({'n': '$n'});
  static String get available => 'van.available'.tr;
  static String get code => 'van.code'.tr;
  static String scanned(String code) => 'van.scanned'.trParams({'code': code});
  static String notInVan(String code) =>
      'van.notInVan'.trParams({'code': code});
  static String get scanFailed => 'van.scanFailed'.tr;
  static String get clearScan => 'van.clearScan'.tr;

  // الأقسام
  static String get stockDesc => 'van.stockDesc'.tr;
  static String get newSale => 'van.newSale'.tr;
  static String get newSaleDesc => 'van.newSaleDesc'.tr;

  // العميل
  static String get customer => 'van.customer'.tr;
  static String get chooseCustomer => 'van.chooseCustomer'.tr;
  static String get searchCustomer => 'van.searchCustomer'.tr;
  static String get loadingCustomers => 'van.loadingCustomers'.tr;
  static String get noCustomers => 'van.noCustomers'.tr;
  static String get customersFailed => 'van.customersFailed'.tr;

  // المنتجات
  static String get products => 'van.products'.tr;
  static String get addProduct => 'van.addProduct'.tr;
  static String get chooseProduct => 'van.chooseProduct'.tr;
  static String get noLines => 'van.noLines'.tr;
  static String inVan(String qty) => 'van.inVan'.trParams({'qty': qty});
  static String get unit => 'van.unit'.tr;
  static String unitFactor(String uom, String factor, String stockUom) =>
      'van.unitFactor'.trParams({
        'uom': uom,
        'factor': factor,
        'stockUom': stockUom,
      });
  static String get loadingUnits => 'van.loadingUnits'.tr;
  static String get unitsFailed => 'van.unitsFailed'.tr;
  static String get quantity => 'van.quantity'.tr;
  static String get qtyPositive => 'van.qtyPositive'.tr;
  static String qtyWhole(String uom) => 'van.qtyWhole'.trParams({'uom': uom});
  static String qtyAboveStock(String available) =>
      'van.qtyAboveStock'.trParams({'available': available});
  static String get estimatedPrice => 'van.estimatedPrice'.tr;
  static String get noPrice => 'van.noPrice'.tr;
  static String get add => 'van.add'.tr;
  static String get update => 'van.update'.tr;
  static String get remove => 'van.remove'.tr;
  static String get cancel => AppStrings.cancel;
  static String linesCount(int n) => 'van.linesCount'.trParams({'n': '$n'});

  // المراجعة والحفظ
  static String get review => 'van.review'.tr;
  static String get reviewAndSave => 'van.reviewAndSave'.tr;
  static String get saveDraft => 'van.saveDraft'.tr;
  static String get estimatedTotal => 'van.estimatedTotal'.tr;
  static String get reviewNote => 'van.reviewNote'.tr;
  static String get warehouseLabel => 'van.warehouseLabel'.tr;
  static String get needCustomer => 'van.needCustomer'.tr;
  static String get needLines => 'van.needLines'.tr;
  static String saved(String name, String total) =>
      'van.saved'.trParams({'name': name, 'total': total});
  static String get saveFailed => 'van.saveFailed'.tr;
  static String get discardTitle => 'van.discardTitle'.tr;
  static String get discardMessage => 'van.discardMessage'.tr;
  static String get discard => 'van.discard'.tr;

  // إرجاع المنتجات
  static String get returnTitle => 'van.returnTitle'.tr;
  static String get returnDesc => 'van.returnDesc'.tr;
  static String get loadingInvoices => 'van.loadingInvoices'.tr;
  static String get invoicesFailed => 'van.invoicesFailed'.tr;
  static String get noInvoices => 'van.noInvoices'.tr;
  static String get noInvoicesHint => 'van.noInvoicesHint'.tr;
  static String get searchInvoice => 'van.searchInvoice'.tr;
  static String get chooseInvoice => 'van.chooseInvoice'.tr;
  static String invoiceTotal(String v) => 'van.invoiceTotal'.trParams({'v': v});
  static String get loadingItems => 'van.loadingItems'.tr;
  static String get itemsFailed => 'van.itemsFailed'.tr;
  static String get chooseItems => 'van.chooseItems'.tr;
  static String soldQty(String q) => 'van.soldQty'.trParams({'q': q});
  static String returnedQty(String q) => 'van.returnedQty'.trParams({'q': q});
  static String returnableQty(String q) =>
      'van.returnableQty'.trParams({'q': q});
  static String get nothingReturnable => 'van.nothingReturnable'.tr;
  static String get returnQty => 'van.returnQty'.tr;
  static String qtyAboveReturnable(String max) =>
      'van.qtyAboveReturnable'.trParams({'max': max});
  static String get needReturnLines => 'van.needReturnLines'.tr;
  static String selectedForReturn(int n) =>
      'van.selectedForReturn'.trParams({'n': '$n'});
  static String get saveReturn => 'van.saveReturn'.tr;
  static String get returnFailed => 'van.returnFailed'.tr;
  static String get returnSavedTitle => 'van.returnSavedTitle'.tr;
  static String get returnSavedNote => 'van.returnSavedNote'.tr;
  static String get returnAgainst => 'van.returnAgainst'.tr;
  static String get returnValue => 'van.returnValue'.tr;
  static String get netTotal => 'van.netTotal'.tr;
  static String get taxes => 'van.taxes'.tr;
  static String get grandTotal => 'van.grandTotal'.tr;
  static String get done => 'van.done'.tr;

  // رصيد العميل
  static String get creditTitle => 'van.creditTitle'.tr;
  static String get creditDesc => 'van.creditDesc'.tr;
  static String get loadingCredit => 'van.loadingCredit'.tr;
  static String get creditFailed => 'van.creditFailed'.tr;
  static String get chooseCustomerHint => 'van.chooseCustomerHint'.tr;
  static String get creditLimit => 'van.creditLimit'.tr;
  static String get currentBalance => 'van.currentBalance'.tr;
  static String get currentBalanceHint => 'van.currentBalanceHint'.tr;
  static String get availableCredit => 'van.availableCredit'.tr;
  static String get noCreditLimit => 'van.noCreditLimit'.tr;
  static String get limitFromCustomer => 'van.limitFromCustomer'.tr;
  static String limitFromGroup(String g) =>
      'van.limitFromGroup'.trParams({'g': g});
  static String get overLimit => 'van.overLimit'.tr;
  static String get customerGroup => 'van.customerGroup'.tr;
  static String get phone => 'van.phone'.tr;
  static String get customerId => 'van.customerId'.tr;
  static String usedPercent(String p) => 'van.usedPercent'.trParams({'p': p});
  static String get creditNote => 'van.creditNote'.tr;

  // تحذير الحد في الفاتورة الجديدة
  static String get creditCheck => 'van.creditCheck'.tr;
  static String afterInvoice(String v) => 'van.afterInvoice'.trParams({'v': v});
  static String exceedsLimit(String over) =>
      'van.exceedsLimit'.trParams({'over': over});
  static String get withinLimit => 'van.withinLimit'.tr;
  static String get cannotCheckLimit => 'van.cannotCheckLimit'.tr;
  static String get exceedsTitle => 'van.exceedsTitle'.tr;
  static String get saveAnyway => 'van.saveAnyway'.tr;

  // نهاية اليوم
  static String get eodTitle => 'van.eodTitle'.tr;
  static String get eodDesc => 'van.eodDesc'.tr;
  static String get stockCountTab => 'van.stockCountTab'.tr;
  static String get daySalesTab => 'van.daySalesTab'.tr;
  static String get systemQty => 'van.systemQty'.tr;
  static String get physicalQty => 'van.physicalQty'.tr;
  static String get difference => 'van.difference'.tr;
  static String get onlyDifferences => 'van.onlyDifferences'.tr;
  static String differencesCount(int n) => n == 0
      ? 'van.differencesCount'.tr
      : 'van.differencesCount_2'.trParams({'n': '$n'});
  static String get countHint => 'van.countHint'.tr;
  static String get qtyNotNegative => 'van.qtyNotNegative'.tr;
  static String get createReconciliation => 'van.createReconciliation'.tr;
  static String get noDifferences => 'van.noDifferences'.tr;
  static String get reconcileTitle => 'van.reconcileTitle'.tr;
  static String reconcileMessage(int n) =>
      'van.reconcileMessage'.trParams({'n': '$n'});
  static String reconcileSaved(String name) =>
      'van.reconcileSaved'.trParams({'name': name});
  static String get reconcileFailed => 'van.reconcileFailed'.tr;
  static String get loadingDaySales => 'van.loadingDaySales'.tr;
  static String get daySalesFailed => 'van.daySalesFailed'.tr;
  static String get totalSales => 'van.totalSales'.tr;
  static String get totalReturns => 'van.totalReturns'.tr;
  static String get netSales => 'van.netSales'.tr;
  static String invoicesCount(int n) =>
      'van.invoicesCount'.trParams({'n': '$n'});
  static String returnsCount(int n) => 'van.returnsCount'.trParams({'n': '$n'});
  static String draftsPending(int n, String total) =>
      'van.draftsPending'.trParams({'n': '$n', 'total': total});
  static String get noDaySales => 'van.noDaySales'.tr;
  static String get dayTotalsNote => 'van.dayTotalsNote'.tr;
  static String get draftLabel => 'van.draftLabel'.tr;
  static String get returnLabel => 'van.returnLabel'.tr;

  // طلب تزويد الفان
  static String get refillTitle => 'van.refillTitle'.tr;
  static String get refillDesc => 'van.refillDesc'.tr;
  static String get refillHint => 'van.refillHint'.tr;
  static String get requestedQty => 'van.requestedQty'.tr;
  static String requestedCount(int n) =>
      'van.requestedCount'.trParams({'n': '$n'});
  static String get from => 'van.from'.tr;
  static String get to => 'van.to'.tr;
  static String get saveRequest => 'van.saveRequest'.tr;
  static String get needRequestLines => 'van.needRequestLines'.tr;
  static String get requestFailed => 'van.requestFailed'.tr;
  static String get requestSavedTitle => 'van.requestSavedTitle'.tr;
  static String get requestSavedNote => 'van.requestSavedNote'.tr;
  static String get requestNo => 'van.requestNo'.tr;
  static String get requestStatus => 'van.requestStatus'.tr;
  static String get requestDate => 'van.requestDate'.tr;
  static String get requiredBy => 'van.requiredBy'.tr;
}
