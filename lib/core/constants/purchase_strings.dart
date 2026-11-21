import 'package:get/get.dart';

/// نصوص قسم «المشتريات» (عربي/إنجليزي). النصوص في lib/app/translations (ar.dart / en.dart) وتُقرأ هنا بـ .tr.
class PurchaseStrings {
  PurchaseStrings._();

  // القائمة والتنقل
  static String get section => 'purchase.section'.tr;
  static String get navOrders => 'purchase.navOrders'.tr;
  static String get navReceipts => 'purchase.navReceipts'.tr;
  static String get navInvoices => 'purchase.navInvoices'.tr;

  // التبويبات
  static String get tabToReceive => 'purchase.tabToReceive'.tr;

  // أوامر الشراء
  static String get newOrder => 'purchase.newOrder'.tr;
  static String get orderDraftsEmptyTitle =>
      'purchase.orderDraftsEmptyTitle'.tr;
  static String get orderDraftsEmptyMessage =>
      'purchase.orderDraftsEmptyMessage'.tr;
  static String get toReceiveEmptyTitle => 'purchase.toReceiveEmptyTitle'.tr;
  static String get toReceiveEmptyMessage =>
      'purchase.toReceiveEmptyMessage'.tr;
  static String get orderToBillEmptyTitle =>
      'purchase.orderToBillEmptyTitle'.tr;
  static String get orderToBillEmptyMessage =>
      'purchase.orderToBillEmptyMessage'.tr;
  static String get orderCompletedEmptyTitle =>
      'purchase.orderCompletedEmptyTitle'.tr;
  static String get orderCompletedEmptyMessage =>
      'purchase.orderCompletedEmptyMessage'.tr;

  static String get approve => 'purchase.approve'.tr;
  static String get approveOrderTitle => 'purchase.approveOrderTitle'.tr;
  static String get approveOrderMessage => 'purchase.approveOrderMessage'.tr;
  static String get orderApproved => 'purchase.orderApproved'.tr;
  static String get approveFailed => 'purchase.approveFailed'.tr;
  static String get deleteOrderTitle => 'purchase.deleteOrderTitle'.tr;
  static String get deleteOrderMessage => 'purchase.deleteOrderMessage'.tr;
  static String get orderDeleted => 'purchase.orderDeleted'.tr;
  static String get deleteFailed => 'purchase.deleteFailed'.tr;
  static String get orderCreateFailed => 'purchase.orderCreateFailed'.tr;

  // الاستلام
  static String get receive => 'purchase.receive'.tr;
  static String get receiveTitle => 'purchase.receiveTitle'.tr;
  static String get receiveMessage => 'purchase.receiveMessage'.tr;
  static String get orderReceived => 'purchase.orderReceived'.tr;
  static String get receiveFailed => 'purchase.receiveFailed'.tr;
  static String get receiptAwaitingApproval =>
      'purchase.receiptAwaitingApproval'.tr;
  static String get receiptDraftStatus => 'purchase.receiptDraftStatus'.tr;

  // الاستلامات
  static String get receiptsDraftEmptyTitle =>
      'purchase.receiptsDraftEmptyTitle'.tr;
  static String get receiptsDraftEmptyMessage =>
      'purchase.receiptsDraftEmptyMessage'.tr;
  static String get receiptsToBillEmptyTitle =>
      'purchase.receiptsToBillEmptyTitle'.tr;
  static String get receiptsToBillEmptyMessage =>
      'purchase.receiptsToBillEmptyMessage'.tr;
  static String get receiptsCompletedEmptyTitle =>
      'purchase.receiptsCompletedEmptyTitle'.tr;
  static String get receiptsCompletedEmptyMessage =>
      'purchase.receiptsCompletedEmptyMessage'.tr;
  static String get receiptNumber => 'purchase.receiptNumber'.tr;

  // الفوترة
  static String get bill => 'purchase.bill'.tr;
  static String get billTitle => 'purchase.billTitle'.tr;
  static String get billMessage => 'purchase.billMessage'.tr;
  static String get billed => 'purchase.billed'.tr;
  static String get billFailed => 'purchase.billFailed'.tr;
  static String get billWaitingApproval => 'purchase.billWaitingApproval'.tr;
  static String get billNoReceipt => 'purchase.billNoReceipt'.tr;

  // الفواتير
  static String get invoicesDraftEmptyTitle =>
      'purchase.invoicesDraftEmptyTitle'.tr;
  static String get invoicesDraftEmptyMessage =>
      'purchase.invoicesDraftEmptyMessage'.tr;
  static String get invoicesUnpaidEmptyTitle =>
      'purchase.invoicesUnpaidEmptyTitle'.tr;
  static String get invoicesUnpaidEmptyMessage =>
      'purchase.invoicesUnpaidEmptyMessage'.tr;
  static String get invoicesPartlyEmptyTitle =>
      'purchase.invoicesPartlyEmptyTitle'.tr;
  static String get invoicesPartlyEmptyMessage =>
      'purchase.invoicesPartlyEmptyMessage'.tr;
  static String get invoicesPaidEmptyTitle =>
      'purchase.invoicesPaidEmptyTitle'.tr;
  static String get invoicesPaidEmptyMessage =>
      'purchase.invoicesPaidEmptyMessage'.tr;
  static String get supplier => 'purchase.supplier'.tr;
  static String get purchaseOrderNumber => 'purchase.purchaseOrderNumber'.tr;
  static String get itemsCount => 'purchase.itemsCount'.tr;
  static String get invoiceWaitingApproval =>
      'purchase.invoiceWaitingApproval'.tr;

  // الدفع للمورد
  static String get payToSupplier => 'purchase.payToSupplier'.tr;
  static String get payToSupplierAction => 'purchase.payToSupplierAction'.tr;
  static String get payAmount => 'purchase.payAmount'.tr;
  static String get payMode => 'purchase.payMode'.tr;
  static String get payModesFailed => 'purchase.payModesFailed'.tr;
  static String get payChooseMode => 'purchase.payChooseMode'.tr;
  static String payExceeds(String due) =>
      'purchase.payExceeds'.trParams({'due': due});
  static String get payZero => 'purchase.payZero'.tr;
  static String get payInvalid => 'purchase.payInvalid'.tr;
  static String get payReference => 'purchase.payReference'.tr;
  static String get payReferenceDate => 'purchase.payReferenceDate'.tr;
  static String get paySave => 'purchase.paySave'.tr;
  static String get paymentSaved => 'purchase.paymentSaved'.tr;
  static String get paymentFailed => 'purchase.paymentFailed'.tr;
  static String paymentPending(String amount) =>
      'purchase.paymentPending'.trParams({'amount': amount});

  // أمر شراء جديد
  static String get newOrderTitle => 'purchase.newOrderTitle'.tr;
  static String get chooseSupplier => 'purchase.chooseSupplier'.tr;
  static String get searchSupplier => 'purchase.searchSupplier'.tr;
  static String get searchItem => 'purchase.searchItem'.tr;
  static String get addItem => 'purchase.addItem'.tr;
  static String get noResults => 'purchase.noResults'.tr;
  static String get qty => 'purchase.qty'.tr;
  static String get unitPrice => 'purchase.unitPrice'.tr;
  static String get requiredBy => 'purchase.requiredBy'.tr;
  static String get itemsTitle => 'purchase.itemsTitle'.tr;
  static String get noItemsYet => 'purchase.noItemsYet'.tr;
  static String get saveDraft => 'purchase.saveDraft'.tr;
  static String get subtotal => 'purchase.subtotal'.tr;
  static String get taxes => 'purchase.taxes'.tr;
  static String get total => 'purchase.total'.tr;
  static String get orderSaved => 'purchase.orderSaved'.tr;
  static String get invalidLine => 'purchase.invalidLine'.tr;

  // تعديل كميات بنود المستند المسودة (المستودع للعرض، بلا سعر)
  static String get editItems => 'purchase.editItems'.tr;
  static String get editItemsTitle => 'purchase.editItemsTitle'.tr;
  static String get qtyLabel => 'purchase.qtyLabel'.tr;
  static String get warehouseLabel => 'purchase.warehouseLabel'.tr;
  static String get saveItems => 'purchase.saveItems'.tr;
  static String get itemsSaved => 'purchase.itemsSaved'.tr;
  static String get itemsSaveFailed => 'purchase.itemsSaveFailed'.tr;
  static String get itemsInvalid => 'purchase.itemsInvalid'.tr;
  static String get totalsFromErp => 'purchase.totalsFromErp'.tr;
}
