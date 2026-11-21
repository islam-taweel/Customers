import 'package:get/get.dart';

import '../../app/translations/ar.dart';
import '../../data/models/sync_models.dart';

/// كل النصوص الظاهرة للمستخدم في مكان واحد، بالعربية والإنجليزية.
/// النصوص نفسها في lib/app/translations (ar.dart / en.dart)، وتُقرأ هنا بـ .tr.
/// اللغة الحالية يضبطها [LanguageController] عبر Get.locale.
class AppStrings {
  AppStrings._();

  /// true = العربية (الافتراضية)، false = الإنجليزية. تتبع لغة GetX الحالية.
  static bool get isArabic => (Get.locale?.languageCode ?? 'ar') == 'ar';

  // ───────── عام ─────────
  static String get appName => 'app.appName'.tr;
  static String get save => 'app.save'.tr;
  static String get cancel => 'app.cancel'.tr;
  static String get retry => 'app.retry'.tr;
  static String get errorTitle => 'app.errorTitle'.tr;

  // ───────── القائمة الجانبية ─────────
  static String get dashboard => 'app.dashboard'.tr;
  static String get customerOrders => 'app.customerOrders'.tr;

  // ───────── قسم الطلبات: الطلبيات / التسليمات / الفواتير ─────────
  static String get ordersSection => 'app.ordersSection'.tr;
  static String get navOrders => 'app.navOrders'.tr;
  static String get navDeliveries => 'app.navDeliveries'.tr;
  static String get navInvoices => 'app.navInvoices'.tr;
  static String get tabToDeliver => 'app.tabToDeliver'.tr;
  static String get tabToBill => 'app.tabToBill'.tr;
  static String get tabCompleted => 'app.tabCompleted'.tr;
  static String get addNewOrder => 'app.addNewOrder'.tr;
  static String get ordersRefresh => 'app.ordersRefresh'.tr;
  static String get ordersDraftsEmptyMessage =>
      'app.ordersDraftsEmptyMessage'.tr;
  static String get toDeliverEmptyTitle => 'app.toDeliverEmptyTitle'.tr;
  static String get toDeliverEmptyMessage => 'app.toDeliverEmptyMessage'.tr;
  static String get toBillEmptyTitle => 'app.toBillEmptyTitle'.tr;
  static String get toBillEmptyMessage => 'app.toBillEmptyMessage'.tr;
  static String get completedEmptyTitle => 'app.completedEmptyTitle'.tr;
  static String get completedEmptyMessage => 'app.completedEmptyMessage'.tr;
  static String get deliver => 'app.deliver'.tr;
  static String get deliverTitle => 'app.deliverTitle'.tr;
  static String get deliverMessage => 'app.deliverMessage'.tr;
  static String get orderDelivered => 'app.orderDelivered'.tr;
  static String get deliverFailed => 'app.deliverFailed'.tr;
  // إرجاع طلبية معتمدة إلى مسودة (إلغاء ثم تعديل في ERPNext)
  static String get reopenOrder => 'app.reopenOrder'.tr;
  static String get reopenTitle => 'app.reopenTitle'.tr;
  static String get reopenMessage => 'app.reopenMessage'.tr;
  static String orderReopened(String id) =>
      'app.orderReopened'.trParams({'id': id});
  static String amountKeptOnAccount(String amount) =>
      'app.amountKeptOnAccount'.trParams({'amount': amount});
  static String get reopenFailed => 'app.reopenFailed'.tr;
  static String reopenHasDraftPayments(String docs) =>
      'app.reopenHasDraftPayments'.trParams({'docs': docs});
  static String get reopenNeedsUnlinkSetting =>
      'app.reopenNeedsUnlinkSetting'.tr;
  static String reopenNoOrder(String invoice) =>
      'app.reopenNoOrder'.trParams({'invoice': invoice});
  static String get ordersRefreshFailed => 'app.ordersRefreshFailed'.tr;
  // ───────── قسم الفواتير ─────────
  static String get tabUnpaid => 'app.tabUnpaid'.tr;
  static String get tabPartlyPaid => 'app.tabPartlyPaid'.tr;
  static String get tabPaid => 'app.tabPaid'.tr;
  static String get invoicesDraftEmptyTitle => 'app.invoicesDraftEmptyTitle'.tr;
  static String get invoicesDraftEmptyMessage =>
      'app.invoicesDraftEmptyMessage'.tr;
  static String get invoicesUnpaidEmptyTitle =>
      'app.invoicesUnpaidEmptyTitle'.tr;
  static String get invoicesUnpaidEmptyMessage =>
      'app.invoicesUnpaidEmptyMessage'.tr;
  static String get invoicesPartlyEmptyTitle =>
      'app.invoicesPartlyEmptyTitle'.tr;
  static String get invoicesPartlyEmptyMessage =>
      'app.invoicesPartlyEmptyMessage'.tr;
  static String get invoicesPaidEmptyTitle => 'app.invoicesPaidEmptyTitle'.tr;
  static String get invoicesPaidEmptyMessage =>
      'app.invoicesPaidEmptyMessage'.tr;
  static String get amountDue => 'app.amountDue'.tr;
  static String get payAction => 'app.payAction'.tr;
  static String get payInvoiceTitle => 'app.payInvoiceTitle'.tr;
  static String get payAmountLabel => 'app.payAmountLabel'.tr;
  static String get payNoteLabel => 'app.payNoteLabel'.tr;
  static String get payAmountRequired => 'app.payAmountRequired'.tr;
  static String get payAmountPositive => 'app.payAmountPositive'.tr;
  static String payAmountExceeds(String due) =>
      'app.payAmountExceeds'.trParams({'due': due});
  static String get paySave => 'app.paySave'.tr;
  static String get paymentSavedPending => 'app.paymentSavedPending'.tr;
  static String get paymentSaveFailed => 'app.paymentSaveFailed'.tr;
  static String paymentPending(String amount) =>
      'app.paymentPending'.trParams({'amount': amount});

  // ───────── قسم التسليمات ─────────
  static String get deliveriesDraftEmptyTitle =>
      'app.deliveriesDraftEmptyTitle'.tr;
  static String get deliveriesDraftEmptyMessage =>
      'app.deliveriesDraftEmptyMessage'.tr;
  static String get deliveriesToBillEmptyTitle =>
      'app.deliveriesToBillEmptyTitle'.tr;
  static String get deliveriesToBillEmptyMessage =>
      'app.deliveriesToBillEmptyMessage'.tr;
  static String get deliveriesCompletedEmptyTitle =>
      'app.deliveriesCompletedEmptyTitle'.tr;
  static String get deliveriesCompletedEmptyMessage =>
      'app.deliveriesCompletedEmptyMessage'.tr;
  static String get deliveryDraftStatus => 'app.deliveryDraftStatus'.tr;
  static String get bill => 'app.bill'.tr;
  static String get billTitle => 'app.billTitle'.tr;
  static String get billMessage => 'app.billMessage'.tr;
  static String get orderBilled => 'app.orderBilled'.tr;
  static String get invoiceAwaitingApproval => 'app.invoiceAwaitingApproval'.tr;
  static String get billNoDeliveryNote => 'app.billNoDeliveryNote'.tr;
  static String paymentNoAccountForMode(String mode) =>
      'app.paymentNoAccountForMode'.trParams({'mode': mode});
  static String get payWaitingInvoiceApproval =>
      'app.payWaitingInvoiceApproval'.tr;
  static String get payFieldRequired => 'app.payFieldRequired'.tr;
  static String get payRefCheque => 'app.payRefCheque'.tr;
  static String get payDateCheque => 'app.payDateCheque'.tr;
  static String get payChequeBank => 'app.payChequeBank'.tr;
  static String get payDrawerName => 'app.payDrawerName'.tr;
  static String get payRefCard => 'app.payRefCard'.tr;
  static String get payDateCard => 'app.payDateCard'.tr;
  static String get payCardLast4 => 'app.payCardLast4'.tr;
  static String get payCardLast4Helper => 'app.payCardLast4Helper'.tr;
  static String get payCardLast4Invalid => 'app.payCardLast4Invalid'.tr;
  static String get payCardBrand => 'app.payCardBrand'.tr;
  static String get payRefTransfer => 'app.payRefTransfer'.tr;
  static String get payDateTransfer => 'app.payDateTransfer'.tr;
  static String get paySenderBank => 'app.paySenderBank'.tr;
  static String get payRefGeneric => 'app.payRefGeneric'.tr;
  static String get payDateGeneric => 'app.payDateGeneric'.tr;
  static String get billFailed => 'app.billFailed'.tr;
  static String get billWaitingApproval => 'app.billWaitingApproval'.tr;
  static String get comingSoon => 'app.comingSoon'.tr;
  static String get comingSoonMessage => 'app.comingSoonMessage'.tr;
  static String get settings => 'app.settings'.tr;

  // ───────── المظهر (الثيم) ─────────
  static String get appearanceTitle => 'app.appearanceTitle'.tr;
  static String get appearanceDesc => 'app.appearanceDesc'.tr;
  static String get themeDark => 'app.themeDark'.tr;
  static String get themeLight => 'app.themeLight'.tr;
  static String get themeCustom => 'app.themeCustom'.tr;
  static String get themeChooseColor => 'app.themeChooseColor'.tr;
  static String themeColorName(String name) => switch (name) {
    'green' => 'app.themeColorName.green'.tr,
    'teal' => 'app.themeColorName.teal'.tr,
    'sky' => 'app.themeColorName.sky'.tr,
    'blue' => 'app.themeColorName.blue'.tr,
    'indigo' => 'app.themeColorName.indigo'.tr,
    'violet' => 'app.themeColorName.violet'.tr,
    'rose' => 'app.themeColorName.rose'.tr,
    'red' => 'app.themeColorName.red'.tr,
    'orange' => 'app.themeColorName.orange'.tr,
    'gold' => 'app.themeColorName.gold'.tr,
    _ => name,
  };

  // ───────── شاشة العملاء ─────────
  static String get customers => 'app.customers'.tr;
  static String get addCustomer => 'app.addCustomer'.tr;
  static String get addCustomerTitle => 'app.addCustomerTitle'.tr;
  static String get addFirstCustomer => 'app.addFirstCustomer'.tr;
  static String get searchHint => 'app.searchHint'.tr;
  static String get loadingCustomers => 'app.loadingCustomers'.tr;
  static String get noCustomersTitle => 'app.noCustomersTitle'.tr;
  static String get noCustomersMessage => 'app.noCustomersMessage'.tr;
  static String get noSearchResultsTitle => 'app.noSearchResultsTitle'.tr;
  static String get noSearchResultsMessage => 'app.noSearchResultsMessage'.tr;
  static String get customerAdded => 'app.customerAdded'.tr;
  static String get customerSavedLocalOnly => 'app.customerSavedLocalOnly'.tr;
  static String get customerPhoneNotSaved => 'app.customerPhoneNotSaved'.tr;
  static String get customerType => 'app.customerType'.tr;
  static String get customerTypeCompany => 'app.customerTypeCompany'.tr;
  static String get customerTypeIndividual => 'app.customerTypeIndividual'.tr;
  static String get customerGroup => 'app.customerGroup'.tr;
  static String get customerGroupRequired => 'app.customerGroupRequired'.tr;
  static String get territory => 'app.territory'.tr;
  static String get territoryRequired => 'app.territoryRequired'.tr;
  static String get customerSaveFailed => 'app.customerSaveFailed'.tr;
  static String get totalDebts => 'app.totalDebts'.tr;
  static String get loadCustomersError => 'app.loadCustomersError'.tr;
  static String get loadMoreCustomersError => 'app.loadMoreCustomersError'.tr;
  static String get unknownInitial => 'app.unknownInitial'.tr;

  // ───────── الفرز ─────────
  static String get sortTooltip => 'app.sortTooltip'.tr;
  static String get sortByName => 'app.sortByName'.tr;
  static String get sortNewest => 'app.sortNewest'.tr;
  static String get sortHighestDebt => 'app.sortHighestDebt'.tr;

  // ───────── الحقول والتحقق ─────────
  static String get name => 'app.name'.tr;
  static String get phone => 'app.phone'.tr;
  static String get nameRequired => 'app.nameRequired'.tr;
  static String get phoneRequired => 'app.phoneRequired'.tr;
  static String get amount => 'app.amount'.tr;
  static String get noteOptional => 'app.noteOptional'.tr;
  static String get amountInvalid => 'app.amountInvalid'.tr;
  static String get amountMustBePositive => 'app.amountMustBePositive'.tr;

  // ───────── تعديل العميل ─────────
  static String get editCustomer => 'app.editCustomer'.tr;
  static String get editCustomerTitle => 'app.editCustomerTitle'.tr;
  static String get saveChanges => 'app.saveChanges'.tr;
  static String get phoneInvalid => 'app.phoneInvalid'.tr;
  static String get phoneHint => '05XXXXXXXX';
  static String get customerUpdated => 'app.customerUpdated'.tr;
  static String get customerUpdateFailed => 'app.customerUpdateFailed'.tr;

  // ───────── حذف العميل ─────────
  static String get delete => 'app.delete'.tr;
  static String get undo => 'app.undo'.tr;
  static String get deleteCustomerTitle => 'app.deleteCustomerTitle'.tr;
  static String get deleteCustomerMessage => 'app.deleteCustomerMessage'.tr;
  static String get customerDeleteFailed => 'app.customerDeleteFailed'.tr;
  static String get customerRestored => 'app.customerRestored'.tr;
  static String get customerRestoreFailed => 'app.customerRestoreFailed'.tr;
  static String customerDeleted(String name) =>
      'app.customerDeleted'.trParams({'name': name});

  // ───────── واتساب ─────────
  static String get whatsappButton => 'app.whatsappButton'.tr;
  static String get whatsappNotInstalled => 'app.whatsappNotInstalled'.tr;
  static String get whatsappInvalidPhone => 'app.whatsappInvalidPhone'.tr;
  static String get whatsappNoDebt => 'app.whatsappNoDebt'.tr;
  static String get whatsappFailed => 'app.whatsappFailed'.tr;

  /// رابط بين عناصر قائمة قصيرة: «100 ₪ و 30 USD»
  static String get andJoiner => 'app.andJoiner'.tr;

  /// اسم اللغة بلغتها نفسها (لا يتغير بتغيّر لغة التطبيق)
  static String get languageArabic => 'app.languageArabic'.tr;
  static String get languageEnglish => 'app.languageEnglish'.tr;

  /// نص الرسالة الجاهزة المرسلة للعميل. يبقى بالعربية دائمًا (عملاؤك عرب)،
  /// ولا يتبع لغة التطبيق، لذلك يُقرأ من الترجمة العربية مباشرة (ar.dart).
  static String whatsappDebtMessage(String name, String amount) =>
      (arTranslations['app.whatsappDebtMessage'] ?? '')
          .replaceAll('@name', name)
          .replaceAll('@amount', amount);

  // ───────── حالة الرصيد ─────────
  static String get owed => 'app.owed'.tr;
  static String get hasCredit => 'app.hasCredit'.tr;
  static String get settled => 'app.settled'.tr;
  static String get balanceOwedLong => 'app.balanceOwedLong'.tr;
  static String get balanceCreditLong => 'app.balanceCreditLong'.tr;
  static String get balanceSettledLong => 'app.balanceSettledLong'.tr;
  static String get balancesPerCurrencyNote => 'app.balancesPerCurrencyNote'.tr;

  // ───────── العمليات (شاشة التفاصيل) ─────────
  static String get addDebt => 'app.addDebt'.tr;
  static String get addPayment => 'app.addPayment'.tr;

  // ───────── دفعات ERPNext: تبويبا «مسودة» و«معتمدة» ─────────
  static String paymentsDraftTab(int n) =>
      'app.paymentsDraftTab'.trParams({'n': '$n'});
  static String paymentsApprovedTab(int n) =>
      'app.paymentsApprovedTab'.trParams({'n': '$n'});
  static String get paymentsDraftEmpty => 'app.paymentsDraftEmpty'.tr;
  static String get paymentsApprovedEmpty => 'app.paymentsApprovedEmpty'.tr;
  static String get paymentsLoadFailed => 'app.paymentsLoadFailed'.tr;
  static String get paymentStatusDraft => 'app.paymentStatusDraft'.tr;
  static String get paymentStatusApproved => 'app.paymentStatusApproved'.tr;
  static String get paymentApprove => 'app.paymentApprove'.tr;
  static String get paymentCancel => 'app.paymentCancel'.tr;
  static String get paymentDetails => 'app.paymentDetails'.tr;
  static String paymentApproveTitle(String id) =>
      'app.paymentApproveTitle'.trParams({'id': id});
  static String get paymentApproveMessage => 'app.paymentApproveMessage'.tr;
  static String paymentCancelTitle(String id) =>
      'app.paymentCancelTitle'.trParams({'id': id});
  static String get paymentCancelMessage => 'app.paymentCancelMessage'.tr;
  static String get paymentApproved => 'app.paymentApproved'.tr;
  static String get paymentCancelled => 'app.paymentCancelled'.tr;
  static String get paymentApproveFailed => 'app.paymentApproveFailed'.tr;
  static String get paymentCancelFailed => 'app.paymentCancelFailed'.tr;
  static String get paymentSavedDraft => 'app.paymentSavedDraft'.tr;
  static String paymentCredited(String amount) =>
      'app.paymentCredited'.trParams({'amount': amount});
  static String get debt => 'app.debt'.tr;
  static String get payment => 'app.payment'.tr;
  static String get debtAdded => 'app.debtAdded'.tr;
  static String get paymentAdded => 'app.paymentAdded'.tr;
  static String get operationsLog => 'app.operationsLog'.tr;
  static String get noOperationsTitle => 'app.noOperationsTitle'.tr;
  static String get noOperationsMessage => 'app.noOperationsMessage'.tr;
  static String get loadOperationsError => 'app.loadOperationsError'.tr;
  static String get operationSaveFailed => 'app.operationSaveFailed'.tr;

  // ───────── العملة وطريقة الدفع (Payment Entry) ─────────
  static String get currency => 'app.currency'.tr;
  static String get modeOfPayment => 'app.modeOfPayment'.tr;
  static String get currencyRequired => 'app.currencyRequired'.tr;
  static String get accountCurrency => 'app.accountCurrency'.tr;
  static String get accountCurrencyHelper => 'app.accountCurrencyHelper'.tr;
  static String get accountCurrencyAuto => 'app.accountCurrencyAuto'.tr;
  static String get modeOfPaymentRequired => 'app.modeOfPaymentRequired'.tr;
  static String get modesOfPaymentUnavailable =>
      'app.modesOfPaymentUnavailable'.tr;
  static String get paymentCustomerAccountMissing =>
      'app.paymentCustomerAccountMissing'.tr;
  static String paymentModeAccountMissing(String mode) =>
      'app.paymentModeAccountMissing'.trParams({'mode': mode});
  static String exchangeRateMissing(String from, String to) =>
      'app.exchangeRateMissing'.trParams({'from': from, 'to': to});
  static String paymentNoAccountForCurrency(String currency) =>
      'app.paymentNoAccountForCurrency'.trParams({'currency': currency});
  static String get invoicesOutstandingTitle =>
      'app.invoicesOutstandingTitle'.tr;
  static String get accountBalance => 'app.accountBalance'.tr;
  static String get noInvoiceOutstanding => 'app.noInvoiceOutstanding'.tr;
  static String get accountBalanceHint => 'app.accountBalanceHint'.tr;
  static String conversionNote(String to) =>
      'app.conversionNote'.trParams({'to': to});
  static String conversionResult(
    String converted,
    String from,
    String rate,
    String to,
  ) => 'app.conversionResult'.trParams({
    'converted': converted,
    'from': from,
    'rate': rate,
    'to': to,
  });
  static String get loadingRate => 'app.loadingRate'.tr;
  static String settledAs(String amount, String rate) =>
      'app.settledAs'.trParams({'amount': amount, 'rate': rate});
  static String paymentEntryRef(String name) =>
      'app.paymentEntryRef'.trParams({'name': name});

  // ───────── الفاتورة ─────────
  static String get tabOperations => 'app.tabOperations'.tr;
  static String get tabInvoice => 'app.tabInvoice'.tr;

  // ───────── شاشتا العمليات والفواتير (من تفاصيل العميل) ─────────
  static String get invoicesTitle => 'app.invoicesTitle'.tr;
  static String get invoicesButtonHint => 'app.invoicesButtonHint'.tr;
  static String operationsCount(int n) =>
      'app.operationsCount'.trParams({'n': '$n'});
  static String get tabDraft => 'app.tabDraft'.tr;
  static String get tabSubmitted => 'app.tabSubmitted'.tr;
  static String get draftsEmptyTitle => 'app.draftsEmptyTitle'.tr;
  static String get draftsEmptyMessage => 'app.draftsEmptyMessage'.tr;
  static String get draftEdit => 'app.draftEdit'.tr;
  static String get draftApprove => 'app.draftApprove'.tr;
  static String get draftSubmit => 'app.draftSubmit'.tr;
  static String get editDraftTitle => 'app.editDraftTitle'.tr;
  static String get draftNeedsUploadNote => 'app.draftNeedsUploadNote'.tr;
  static String get draftDeleteTitle => 'app.draftDeleteTitle'.tr;
  static String get draftDeleteMessage => 'app.draftDeleteMessage'.tr;
  static String get draftSubmitTitle => 'app.draftSubmitTitle'.tr;
  static String get draftSubmitMessage => 'app.draftSubmitMessage'.tr;
  static String get draftDeleted => 'app.draftDeleted'.tr;
  static String get draftSubmitted => 'app.draftSubmitted'.tr;
  static String get draftUpdated => 'app.draftUpdated'.tr;
  static String get draftNeedsConnection => 'app.draftNeedsConnection'.tr;
  static String get draftSaveFailed => 'app.draftSaveFailed'.tr;
  static String get draftDeleteFailed => 'app.draftDeleteFailed'.tr;
  static String get draftSubmitFailed => 'app.draftSubmitFailed'.tr;
  static String get draftStateChanged => 'app.draftStateChanged'.tr;
  static String get draftNoItems => 'app.draftNoItems'.tr;
  static String get printInvoice => 'app.printInvoice'.tr;
  static String get invoiceTitle => 'app.invoiceTitle'.tr;
  static String get invoiceNumber => 'app.invoiceNumber'.tr;
  static String get invoiceCustomer => 'app.invoiceCustomer'.tr;
  static String get invoiceAmount => 'app.invoiceAmount'.tr;
  static String get viewInvoicePdf => 'app.viewInvoicePdf'.tr;

  // ───────── القيود المحاسبية (GL Entries) ─────────
  static String get glEntriesTitle => 'app.glEntriesTitle'.tr;
  static String get glEntriesLoading => 'app.glEntriesLoading'.tr;
  static String get glEntriesLoadFailed => 'app.glEntriesLoadFailed'.tr;
  static String get glEntriesEmptyTitle => 'app.glEntriesEmptyTitle'.tr;
  static String get glEntriesEmptyMessage => 'app.glEntriesEmptyMessage'.tr;
  static String get glDescription => 'app.glDescription'.tr;
  static String get glDebit => 'app.glDebit'.tr;
  static String get glCredit => 'app.glCredit'.tr;
  static String get glTotalDebit => 'app.glTotalDebit'.tr;
  static String get glTotalCredit => 'app.glTotalCredit'.tr;
  static String get glBalanced => 'app.glBalanced'.tr;
  static String glDraftsPending(String docs) =>
      'app.glDraftsPending'.trParams({'docs': docs});
  static String glOverpaid(String diff) =>
      'app.glOverpaid'.trParams({'diff': diff});
  static String voucherTypeLabel(String doctype) => switch (doctype) {
    'Sales Invoice' => 'app.voucherTypeLabel.Sales_Invoice'.tr,
    'Delivery Note' => 'app.voucherTypeLabel.Delivery_Note'.tr,
    'Payment Entry' => 'app.voucherTypeLabel.Payment_Entry'.tr,
    'Journal Entry' => 'app.voucherTypeLabel.Journal_Entry'.tr,
    _ => doctype,
  };

  // قيمة الفاتورة والمسدد منها والمتبقي
  static String get invoiceTotalValue => 'app.invoiceTotalValue'.tr;
  static String get invoicePaidFromCredit => 'app.invoicePaidFromCredit'.tr;
  static String get invoicePaid => 'app.invoicePaid'.tr;
  static String glUnbalanced(String diff) =>
      'app.glUnbalanced'.trParams({'diff': diff});
  static String get invoicePdfFailed => 'app.invoicePdfFailed'.tr;

  // ───────── ERPNext (الفواتير فقط) ─────────
  static String get erpSessionExpired => 'app.erpSessionExpired'.tr;
  static String get erpForbidden => 'app.erpForbidden'.tr;
  static String get erpNetworkError => 'app.erpNetworkError'.tr;
  static String get erpServerError => 'app.erpServerError'.tr;
  static String get offlineNoCache => 'app.offlineNoCache'.tr;
  static String offlineNotice(String when) =>
      'app.offlineNotice'.trParams({'when': when});
  static String staleNotice(String reason, String when) =>
      'app.staleNotice'.trParams({'reason': reason, 'when': when});
  static String get erpNotFound => 'app.erpNotFound'.tr;

  static String get loadInvoicesError => 'app.loadInvoicesError'.tr;
  static String get loadInvoiceError => 'app.loadInvoiceError'.tr;
  static String get invoicesNoMatchTitle => 'app.invoicesNoMatchTitle'.tr;
  static String get invoicesNoMatchMessage => 'app.invoicesNoMatchMessage'.tr;
  static String get noInvoicesTitle => 'app.noInvoicesTitle'.tr;
  static String get noInvoicesMessage => 'app.noInvoicesMessage'.tr;
  static String get invoiceRemaining => 'app.invoiceRemaining'.tr;
  static String get invoicePostingDate => 'app.invoicePostingDate'.tr;
  static String get invoiceDueDate => 'app.invoiceDueDate'.tr;
  static String get invoiceStatusLabel => 'app.invoiceStatusLabel'.tr;
  static String get invoiceItems => 'app.invoiceItems'.tr;
  static String get invoiceTaxes => 'app.invoiceTaxes'.tr;
  static String get invoiceOutstanding => 'app.invoiceOutstanding'.tr;

  /// حالة الفاتورة في ERPNext بلغة التطبيق (الحالة غير المعروفة تُعرض كما هي)
  static String invoiceStatus(String status) => switch (status) {
    'Draft' => 'app.invoiceStatus.Draft'.tr,
    'Paid' => 'app.invoiceStatus.Paid'.tr,
    'Unpaid' => 'app.invoiceStatus.Unpaid'.tr,
    'Overdue' => 'app.invoiceStatus.Overdue'.tr,
    'Partly Paid' => 'app.invoiceStatus.Partly_Paid'.tr,
    'Return' => 'app.invoiceStatus.Return'.tr,
    'Credit Note Issued' => 'app.invoiceStatus.Credit_Note_Issued'.tr,
    'Pending Upload' => 'app.invoiceStatus.Pending_Upload'.tr,
    'Submitted' => 'app.invoiceStatus.Submitted'.tr,
    'To Deliver' => 'app.invoiceStatus.To_Deliver'.tr,
    'To Bill' => 'app.invoiceStatus.To_Bill'.tr,
    'Completed' => 'app.invoiceStatus.Completed'.tr,
    _ => status,
  };

  // ───────── طلبيات العملاء ─────────
  static String get newOrderTitle => 'app.newOrderTitle'.tr;
  static String get stepCustomer => 'app.stepCustomer'.tr;
  static String get stepItems => 'app.stepItems'.tr;
  static String get stepInvoice => 'app.stepInvoice'.tr;
  static String get next => 'app.next'.tr;
  static String get back => 'app.back'.tr;
  static String get chooseCustomer => 'app.chooseCustomer'.tr;
  static String get chooseCustomerHint => 'app.chooseCustomerHint'.tr;
  static String get orderCustomersEmpty => 'app.orderCustomersEmpty'.tr;
  static String orderFor(String name) =>
      'app.orderFor'.trParams({'name': name});
  static String get chooseGroupHint => 'app.chooseGroupHint'.tr;
  static String get loadingGroups => 'app.loadingGroups'.tr;
  static String get loadingItems => 'app.loadingItems'.tr;
  static String get loadGroupsError => 'app.loadGroupsError'.tr;
  static String get loadItemsError => 'app.loadItemsError'.tr;
  static String get noGroupsTitle => 'app.noGroupsTitle'.tr;
  static String get noItemsTitle => 'app.noItemsTitle'.tr;
  static String get noItemsMessage => 'app.noItemsMessage'.tr;
  static String get itemPrice => 'app.itemPrice'.tr;
  static String get itemStock => 'app.itemStock'.tr;
  static String get quantity => 'app.quantity'.tr;
  static String get lineTotal => 'app.lineTotal'.tr;
  static String get loadingPricing => 'app.loadingPricing'.tr;
  static String get loadPricingError => 'app.loadPricingError'.tr;
  static String get noPriceTitle => 'app.noPriceTitle'.tr;
  static String get noPriceMessage => 'app.noPriceMessage'.tr;
  static String get outOfStock => 'app.outOfStock'.tr;
  static String get outOfStockMessage => 'app.outOfStockMessage'.tr;
  static String afterOrder(String qty) =>
      'app.afterOrder'.trParams({'qty': qty});
  static String maxAvailable(String qty) =>
      'app.maxAvailable'.trParams({'qty': qty});
  static String selectedItemsCount(int n) =>
      'app.selectedItemsCount'.trParams({'n': '$n'});
  static String get orderTotal => 'app.orderTotal'.tr;
  static String get invoiceHeading => 'app.invoiceHeading'.tr;
  static String get invoiceLinesEmpty => 'app.invoiceLinesEmpty'.tr;
  static String get unitPrice => 'app.unitPrice'.tr;
  static String get removeItem => 'app.removeItem'.tr;
  static String get deliveryDate => 'app.deliveryDate'.tr;
  static String get orderDate => 'app.orderDate'.tr;
  static String get orderNotes => 'app.orderNotes'.tr;
  static String get orderNotesHint => 'app.orderNotesHint'.tr;
  static String get savedAsDraft => 'app.savedAsDraft'.tr;
  static String get submitOrder => 'app.submitOrder'.tr;
  static String get submittingOrder => 'app.submittingOrder'.tr;
  static String get orderCreateFailed => 'app.orderCreateFailed'.tr;
  static String get orderCreatedTitle => 'app.orderCreatedTitle'.tr;
  static String get orderNumber => 'app.orderNumber'.tr;
  static String get orderCreatedNote => 'app.orderCreatedNote'.tr;
  static String get invoiceSavedNote => 'app.invoiceSavedNote'.tr;
  static String get invoiceNotSavedNote => 'app.invoiceNotSavedNote'.tr;
  static String get newOrderAgain => 'app.newOrderAgain'.tr;
  static String get close => 'app.close'.tr;
  static String get copied => 'app.copied'.tr;
  static String get leaveOrderTitle => 'app.leaveOrderTitle'.tr;
  static String get leaveOrderMessage => 'app.leaveOrderMessage'.tr;
  static String get keepEditing => 'app.keepEditing'.tr;
  static String get discard => 'app.discard'.tr;

  /// أسماء مجموعات الأصناف بلغة التطبيق (غير المعروفة تُعرض كما هي)
  static String itemGroupName(String group) => switch (group) {
    'Consumable' => 'app.itemGroupName.Consumable'.tr,
    'Electrical' => 'app.itemGroupName.Electrical'.tr,
    'Hand Tools' => 'app.itemGroupName.Hand_Tools'.tr,
    'Plumbing' => 'app.itemGroupName.Plumbing'.tr,
    'Power Tools' => 'app.itemGroupName.Power_Tools'.tr,
    'Products' => 'app.itemGroupName.Products'.tr,
    'Raw Material' => 'app.itemGroupName.Raw_Material'.tr,
    'Services' => 'app.itemGroupName.Services'.tr,
    'Sub Assemblies' => 'app.itemGroupName.Sub_Assemblies'.tr,
    _ => group,
  };

  // ───────── عملة الطلبية ─────────
  static String get orderRateLoading => 'app.orderRateLoading'.tr;
  static String get orderRateNeedsConnection =>
      'app.orderRateNeedsConnection'.tr;
  static String get orderRateFailed => 'app.orderRateFailed'.tr;
  static String orderCurrencyInfo(String currency, double rate) {
    final text = rate
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return 'app.orderCurrencyInfo'.trParams({
      'currency': currency,
      'text': text,
    });
  }

  static String get orderOfflineNeedsConnection =>
      'app.orderOfflineNeedsConnection'.tr;

  // ───────── طلبية دون اتصال ─────────
  static String get orderSavedOfflineTitle => 'app.orderSavedOfflineTitle'.tr;
  static String get orderWaitingUpload => 'app.orderWaitingUpload'.tr;
  static String get orderSavedOfflineNote => 'app.orderSavedOfflineNote'.tr;
  static String get orderOfflineSaveFailed => 'app.orderOfflineSaveFailed'.tr;

  // ───────── الإعدادات والمزامنة ─────────
  static String get syncCustomersTitle => 'app.syncCustomersTitle'.tr;
  static String get syncCustomersDesc => 'app.syncCustomersDesc'.tr;
  static String get syncItemsTitle => 'app.syncItemsTitle'.tr;
  static String get syncItemsDesc => 'app.syncItemsDesc'.tr;
  static String get syncInvoicesTitle => 'app.syncInvoicesTitle'.tr;
  static String get syncInvoicesDesc => 'app.syncInvoicesDesc'.tr;
  static String get autoSyncRunning => 'app.autoSyncRunning'.tr;
  static String get autoSyncOnline => 'app.autoSyncOnline'.tr;
  static String get autoSyncOffline => 'app.autoSyncOffline'.tr;
  static String get syncRunning => 'app.syncRunning'.tr;
  static String get neverSynced => 'app.neverSynced'.tr;
  static String lastSynced(String when) =>
      'app.lastSynced'.trParams({'when': when});
  static String syncedCustomers(int n) =>
      'app.syncedCustomers'.trParams({'n': '$n'});
  static String syncedItems(int items, int groups) =>
      'app.syncedItems'.trParams({'items': '$items', 'groups': '$groups'});
  static String syncedInvoices(int n) =>
      'app.syncedInvoices'.trParams({'n': '$n'});
  static String get syncFailed => 'app.syncFailed'.tr;
  static String get syncCustomersFirst => 'app.syncCustomersFirst'.tr;
  static String get autoUploadNote => 'app.autoUploadNote'.tr;
  static String pendingOrdersCount(int n) =>
      'app.pendingOrdersCount'.trParams({'n': '$n'});
  static String failedOrdersCount(int n) =>
      'app.failedOrdersCount'.trParams({'n': '$n'});

  static String syncStep(SyncStep step) => switch (step) {
    SyncStep.customers => 'app.syncStep.SyncStep_customers'.tr,
    SyncStep.groups => 'app.syncStep.SyncStep_groups'.tr,
    SyncStep.items => 'app.syncStep.SyncStep_items'.tr,
    SyncStep.prices => 'app.syncStep.SyncStep_prices'.tr,
    SyncStep.stock => 'app.syncStep.SyncStep_stock'.tr,
    SyncStep.saving => 'app.syncStep.SyncStep_saving'.tr,
    SyncStep.uploadingOrders => 'app.syncStep.SyncStep_uploadingOrders'.tr,
    SyncStep.invoicesList => 'app.syncStep.SyncStep_invoicesList'.tr,
    SyncStep.invoiceDetails => 'app.syncStep.SyncStep_invoiceDetails'.tr,
  };

  // ───────── تسجيل الدخول ─────────
  static String get loginTitle => 'app.loginTitle'.tr;
  static String get loginSubtitle => 'app.loginSubtitle'.tr;
  static String get emailLabel => 'app.emailLabel'.tr;
  static String get siteLabel => 'app.siteLabel'.tr;
  static String get siteHelper => 'app.siteHelper'.tr;
  static String get siteInvalid => 'app.siteInvalid'.tr;
  static String get passwordLabel => 'app.passwordLabel'.tr;
  static String get emailRequired => 'app.emailRequired'.tr;
  static String get passwordRequired => 'app.passwordRequired'.tr;
  static String get loginButton => 'app.loginButton'.tr;
  static String get loggingIn => 'app.loggingIn'.tr;
  static String get loginInvalid => 'app.loginInvalid'.tr;
  static String get loginNetworkError => 'app.loginNetworkError'.tr;
  static String get loginServerError => 'app.loginServerError'.tr;
  static String get loginLockWarning => 'app.loginLockWarning'.tr;
  static String get sessionExpiredNotice => 'app.sessionExpiredNotice'.tr;
  static String get showPassword => 'app.showPassword'.tr;
  static String get hidePassword => 'app.hidePassword'.tr;
  static String get logout => 'app.logout'.tr;
  static String get logoutConfirmTitle => 'app.logoutConfirmTitle'.tr;
  static String get logoutConfirmMessage => 'app.logoutConfirmMessage'.tr;

  // ───────── الوقت ─────────
  static String get am => 'app.am'.tr;
  static String get pm => 'app.pm'.tr;

  // ───────── للتطوير فقط (debug) ─────────
  static String addFakeCustomersTooltip(int n) =>
      'app.addFakeCustomersTooltip'.trParams({'n': '$n'});
  static String fakeCustomersAdded(int n) =>
      'app.fakeCustomersAdded'.trParams({'n': '$n'});
  static String get fakeCustomersFailed => 'app.fakeCustomersFailed'.tr;
}
