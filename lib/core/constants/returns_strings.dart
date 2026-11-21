import 'package:get/get.dart';

/// نصوص قسم «مردود المبيعات» (عربي/إنجليزي). النصوص في lib/app/translations (ar.dart / en.dart) وتُقرأ هنا بـ .tr.
class ReturnsStrings {
  ReturnsStrings._();

  static String get section => 'returns.section'.tr;

  // اختيار العميل
  static String get chooseCustomer => 'returns.chooseCustomer'.tr;
  static String get chooseCustomerHint => 'returns.chooseCustomerHint'.tr;
  static String get searchHint => 'returns.searchHint'.tr;
  static String get loadingCustomers => 'returns.loadingCustomers'.tr;
  static String get noCustomers => 'returns.noCustomers'.tr;
  static String get loadFailed => 'returns.loadFailed'.tr;
  static String invoicesCount(int n) =>
      'returns.invoicesCount'.trParams({'n': '$n'});
  static String lastInvoice(String date) =>
      'returns.lastInvoice'.trParams({'date': date});
  static String savedAt(String time) =>
      'returns.savedAt'.trParams({'time': time});

  // فواتير العميل
  static String get chooseInvoice => 'returns.chooseInvoice'.tr;
  static String get loadingInvoices => 'returns.loadingInvoices'.tr;
  static String get noInvoices => 'returns.noInvoices'.tr;
  static String total(String amount) =>
      'returns.total'.trParams({'amount': amount});
  static String outstanding(String amount) =>
      'returns.outstanding'.trParams({'amount': amount});

  // أصناف الفاتورة
  static String get loadingItems => 'returns.loadingItems'.tr;
  static String get noItems => 'returns.noItems'.tr;
  static String get soldQty => 'returns.soldQty'.tr;
  static String get returnedQty => 'returns.returnedQty'.tr;
  static String get returnableQty => 'returns.returnableQty'.tr;
  static String get returnQty => 'returns.returnQty'.tr;
  static String get fullyReturned => 'returns.fullyReturned'.tr;
  static String get wholeNumberOnly => 'returns.wholeNumberOnly'.tr;
  static String maxReturnable(String qty) =>
      'returns.maxReturnable'.trParams({'qty': qty});
  static String get reasonLabel => 'returns.reasonLabel'.tr;
  static String returnTotal(String amount) =>
      'returns.returnTotal'.trParams({'amount': amount});
  static String get createReturn => 'returns.createReturn'.tr;
  static String get nothingChosen => 'returns.nothingChosen'.tr;
  static String get fixErrors => 'returns.fixErrors'.tr;
  static String get confirmTitle => 'returns.confirmTitle'.tr;
  static String confirmBody(int n, String amount) =>
      'returns.confirmBody'.trParams({'n': '$n', 'amount': amount});
  static String get createFailed => 'returns.createFailed'.tr;
  static String get createdTitle => 'returns.createdTitle'.tr;
  static String creditNoteSaved(String id) =>
      'returns.creditNoteSaved'.trParams({'id': id});
  static String stockReturnSaved(String id) =>
      'returns.stockReturnSaved'.trParams({'id': id});
  static String stockReturnFailed(String dn, String error) =>
      'returns.stockReturnFailed'.trParams({'dn': dn, 'error': error});
  static String get ok => 'returns.ok'.tr;

  // بانتظار الاعتماد
  static String get pendingTitle => 'returns.pendingTitle'.tr;
  static String get creditNotes => 'returns.creditNotes'.tr;
  static String get stockReturns => 'returns.stockReturns'.tr;
  static String get noPending => 'returns.noPending'.tr;
  static String against(String id) => 'returns.against'.trParams({'id': id});
  static String get approve => 'returns.approve'.tr;
  static String get reject => 'returns.reject'.tr;
  static String approveTitle(String id) =>
      'returns.approveTitle'.trParams({'id': id});
  static String rejectTitle(String id) =>
      'returns.rejectTitle'.trParams({'id': id});
  static String get rejectBody => 'returns.rejectBody'.tr;
  static String approved(String id) => 'returns.approved'.trParams({'id': id});
  static String rejected(String id) => 'returns.rejected'.trParams({'id': id});
  static String get actionFailed => 'returns.actionFailed'.tr;

  // رد المال
  static String get refundTitle => 'returns.refundTitle'.tr;
  static String refundAmount(String amount) =>
      'returns.refundAmount'.trParams({'amount': amount});
  static String customerStillOwes(String amount) =>
      'returns.customerStillOwes'.trParams({'amount': amount});
  static String get paymentMode => 'returns.paymentMode'.tr;
  static String get referenceNo => 'returns.referenceNo'.tr;
  static String get referenceDate => 'returns.referenceDate'.tr;
  static String get referenceRequired => 'returns.referenceRequired'.tr;
  static String get saveRefund => 'returns.saveRefund'.tr;
  static String get skipRefund => 'returns.skipRefund'.tr;
  static String refundSaved(String id) =>
      'returns.refundSaved'.trParams({'id': id});
  static String get refundFailed => 'returns.refundFailed'.tr;
  static String get refundNotPay => 'returns.refundNotPay'.tr;
  static String refundNoAccount(String mode) =>
      'returns.refundNoAccount'.trParams({'mode': mode});
  static String get modesFailed => 'returns.modesFailed'.tr;
}
