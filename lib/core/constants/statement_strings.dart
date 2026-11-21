import 'package:get/get.dart';

/// نصوص «كشف حساب العملاء» وشاشة تفاصيل المستند (عربي/إنجليزي).
class StatementStrings {
  StatementStrings._();

  static String get section => 'statement.section'.tr;

  // قائمة العملاء
  static String get searchHint => 'statement.searchHint'.tr;
  static String get loadingCustomers => 'statement.loadingCustomers'.tr;
  static String get noCustomers => 'statement.noCustomers'.tr;
  static String get loadFailed => 'statement.loadFailed'.tr;

  // الكشف
  static String get loadingStatement => 'statement.loadingStatement'.tr;
  static String get allPeriods => 'statement.allPeriods'.tr;
  static String get chooseRange => 'statement.chooseRange'.tr;
  static String get clearRange => 'statement.clearRange'.tr;
  static String get openingBalance => 'statement.openingBalance'.tr;
  static String get totalDebit => 'statement.totalDebit'.tr;
  static String get totalCredit => 'statement.totalCredit'.tr;
  static String get closingBalance => 'statement.closingBalance'.tr;
  static String get balance => 'statement.balance'.tr;
  static String get debit => 'statement.debit'.tr;
  static String get credit => 'statement.credit'.tr;
  static String get owesUs => 'statement.owesUs'.tr;
  static String get inCredit => 'statement.inCredit'.tr;
  static String get settled => 'statement.settled'.tr;
  static String get noEntries => 'statement.noEntries'.tr;
  static String get needsAccountsRole => 'statement.needsAccountsRole'.tr;

  // تفاصيل المستند
  static String get loadingDocument => 'statement.loadingDocument'.tr;
  static String get number => 'statement.number'.tr;
  static String get date => 'statement.date'.tr;
  static String get status => 'statement.status'.tr;
  static String get party => 'statement.party'.tr;
  static String get draft => 'statement.draft'.tr;
  static String get submitted => 'statement.submitted'.tr;
  static String get cancelled => 'statement.cancelled'.tr;
  static String get items => 'statement.items'.tr;
  static String get qty => 'statement.qty'.tr;
  static String get rate => 'statement.rate'.tr;
  static String get amount => 'statement.amount'.tr;
  static String get invoiceTotal => 'statement.invoiceTotal'.tr;
  static String get outstanding => 'statement.outstanding'.tr;
  static String get returnAgainst => 'statement.returnAgainst'.tr;
  static String get creditNote => 'statement.creditNote'.tr;
  static String get modeOfPayment => 'statement.modeOfPayment'.tr;
  static String get received => 'statement.received'.tr;
  static String get creditedToCustomer => 'statement.creditedToCustomer'.tr;
  static String get paidTo => 'statement.paidTo'.tr;
  static String get referenceNo => 'statement.referenceNo'.tr;
  static String get referenceDate => 'statement.referenceDate'.tr;
  static String get allocations => 'statement.allocations'.tr;
  static String get unallocated => 'statement.unallocated'.tr;
  static String get notAllocated => 'statement.notAllocated'.tr;
  static String get remarks => 'statement.remarks'.tr;
  static String get accounts => 'statement.accounts'.tr;
  static String get account => 'statement.account'.tr;

  static String voucherType(String doctype) => switch (doctype) {
    'Sales Invoice' => 'statement.voucherType.Sales_Invoice'.tr,
    'Payment Entry' => 'statement.voucherType.Payment_Entry'.tr,
    'Journal Entry' => 'statement.voucherType.Journal_Entry'.tr,
    'Delivery Note' => 'statement.voucherType.Delivery_Note'.tr,
    _ => doctype,
  };
}
