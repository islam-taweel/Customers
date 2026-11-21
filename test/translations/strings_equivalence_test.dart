// مُولَّد بـ gen_strings_eq.py: تكافؤ كل النصوص قبل الترجمة وبعدها.
// ignore_for_file: type=lint
import 'package:customer/app/translations/app_translations.dart';
import 'package:customer/data/models/sync_models.dart';
import 'package:customer/core/constants/app_strings.dart';
import 'package:customer/core/constants/ess_strings.dart';
import 'package:customer/core/constants/inventory_strings.dart';
import 'package:customer/core/constants/purchase_strings.dart';
import 'package:customer/core/constants/returns_strings.dart';
import 'package:customer/core/constants/statement_strings.dart';
import 'package:customer/core/constants/van_strings.dart';
import 'package:customer/core/constants/visit_strings.dart';
import 'package:customer/core/constants/warehouse_strings.dart';

import 'legacy/app_strings.dart';
import 'legacy/ess_strings.dart';
import 'legacy/inventory_strings.dart';
import 'legacy/purchase_strings.dart';
import 'legacy/returns_strings.dart';
import 'legacy/statement_strings.dart';
import 'legacy/van_strings.dart';
import 'legacy/visit_strings.dart';
import 'legacy/warehouse_strings.dart';
import 'legacy/legacy_lang.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUpAll(() => Get.addTranslations(AppTranslations().keys));
  for (final lang in ['ar', 'en']) {
    test('كل النصوص متطابقة مع ما قبل R7 ($lang): 1447 حالة', () {
      LegacyLang.isArabic = lang == 'ar';
      Get.locale = Locale(lang);
      final diffs = <String>[];
      void eq(String id, String Function() before, String Function() after) {
        String run(String Function() f) {
          try {
            return f();
          } catch (e) {
            return 'THROWS ${e.runtimeType}';
          }
        }

        final a = run(before), b = run(after);
        if (a != b) diffs.add('$id\n   before: $a\n   after:  $b');
      }

      eq(
        'AppStrings.syncStep(customers)',
        () => LegacyAppStrings.syncStep(SyncStep.customers),
        () => AppStrings.syncStep(SyncStep.customers),
      );
      eq(
        'AppStrings.syncStep(groups)',
        () => LegacyAppStrings.syncStep(SyncStep.groups),
        () => AppStrings.syncStep(SyncStep.groups),
      );
      eq(
        'AppStrings.syncStep(items)',
        () => LegacyAppStrings.syncStep(SyncStep.items),
        () => AppStrings.syncStep(SyncStep.items),
      );
      eq(
        'AppStrings.syncStep(prices)',
        () => LegacyAppStrings.syncStep(SyncStep.prices),
        () => AppStrings.syncStep(SyncStep.prices),
      );
      eq(
        'AppStrings.syncStep(stock)',
        () => LegacyAppStrings.syncStep(SyncStep.stock),
        () => AppStrings.syncStep(SyncStep.stock),
      );
      eq(
        'AppStrings.syncStep(saving)',
        () => LegacyAppStrings.syncStep(SyncStep.saving),
        () => AppStrings.syncStep(SyncStep.saving),
      );
      eq(
        'AppStrings.syncStep(uploadingOrders)',
        () => LegacyAppStrings.syncStep(SyncStep.uploadingOrders),
        () => AppStrings.syncStep(SyncStep.uploadingOrders),
      );
      eq(
        'AppStrings.syncStep(invoicesList)',
        () => LegacyAppStrings.syncStep(SyncStep.invoicesList),
        () => AppStrings.syncStep(SyncStep.invoicesList),
      );
      eq(
        'AppStrings.syncStep(invoiceDetails)',
        () => LegacyAppStrings.syncStep(SyncStep.invoiceDetails),
        () => AppStrings.syncStep(SyncStep.invoiceDetails),
      );
      eq(
        'WarehouseStrings.qty(2.5, \'kg\')',
        () => LegacyWarehouseStrings.qty(2.5, 'kg'),
        () => WarehouseStrings.qty(2.5, 'kg'),
      );
      eq(
        'WarehouseStrings.qty(3)',
        () => LegacyWarehouseStrings.qty(3),
        () => WarehouseStrings.qty(3),
      );
      eq(
        'WarehouseStrings.qty(1.25)',
        () => LegacyWarehouseStrings.qty(1.25),
        () => WarehouseStrings.qty(1.25),
      );
      eq(
        'WarehouseStrings.qty(0.125, \'m\')',
        () => LegacyWarehouseStrings.qty(0.125, 'm'),
        () => WarehouseStrings.qty(0.125, 'm'),
      );
      eq(
        'WarehouseStrings.qty(10.0)',
        () => LegacyWarehouseStrings.qty(10.0),
        () => WarehouseStrings.qty(10.0),
      );
      eq(
        'AppStrings.appName',
        () => LegacyAppStrings.appName,
        () => AppStrings.appName,
      );
      eq('AppStrings.save', () => LegacyAppStrings.save, () => AppStrings.save);
      eq(
        'AppStrings.cancel',
        () => LegacyAppStrings.cancel,
        () => AppStrings.cancel,
      );
      eq(
        'AppStrings.retry',
        () => LegacyAppStrings.retry,
        () => AppStrings.retry,
      );
      eq(
        'AppStrings.errorTitle',
        () => LegacyAppStrings.errorTitle,
        () => AppStrings.errorTitle,
      );
      eq(
        'AppStrings.dashboard',
        () => LegacyAppStrings.dashboard,
        () => AppStrings.dashboard,
      );
      eq(
        'AppStrings.customerOrders',
        () => LegacyAppStrings.customerOrders,
        () => AppStrings.customerOrders,
      );
      eq(
        'AppStrings.ordersSection',
        () => LegacyAppStrings.ordersSection,
        () => AppStrings.ordersSection,
      );
      eq(
        'AppStrings.navOrders',
        () => LegacyAppStrings.navOrders,
        () => AppStrings.navOrders,
      );
      eq(
        'AppStrings.navDeliveries',
        () => LegacyAppStrings.navDeliveries,
        () => AppStrings.navDeliveries,
      );
      eq(
        'AppStrings.navInvoices',
        () => LegacyAppStrings.navInvoices,
        () => AppStrings.navInvoices,
      );
      eq(
        'AppStrings.tabToDeliver',
        () => LegacyAppStrings.tabToDeliver,
        () => AppStrings.tabToDeliver,
      );
      eq(
        'AppStrings.tabToBill',
        () => LegacyAppStrings.tabToBill,
        () => AppStrings.tabToBill,
      );
      eq(
        'AppStrings.tabCompleted',
        () => LegacyAppStrings.tabCompleted,
        () => AppStrings.tabCompleted,
      );
      eq(
        'AppStrings.addNewOrder',
        () => LegacyAppStrings.addNewOrder,
        () => AppStrings.addNewOrder,
      );
      eq(
        'AppStrings.ordersRefresh',
        () => LegacyAppStrings.ordersRefresh,
        () => AppStrings.ordersRefresh,
      );
      eq(
        'AppStrings.ordersDraftsEmptyMessage',
        () => LegacyAppStrings.ordersDraftsEmptyMessage,
        () => AppStrings.ordersDraftsEmptyMessage,
      );
      eq(
        'AppStrings.toDeliverEmptyTitle',
        () => LegacyAppStrings.toDeliverEmptyTitle,
        () => AppStrings.toDeliverEmptyTitle,
      );
      eq(
        'AppStrings.toDeliverEmptyMessage',
        () => LegacyAppStrings.toDeliverEmptyMessage,
        () => AppStrings.toDeliverEmptyMessage,
      );
      eq(
        'AppStrings.toBillEmptyTitle',
        () => LegacyAppStrings.toBillEmptyTitle,
        () => AppStrings.toBillEmptyTitle,
      );
      eq(
        'AppStrings.toBillEmptyMessage',
        () => LegacyAppStrings.toBillEmptyMessage,
        () => AppStrings.toBillEmptyMessage,
      );
      eq(
        'AppStrings.completedEmptyTitle',
        () => LegacyAppStrings.completedEmptyTitle,
        () => AppStrings.completedEmptyTitle,
      );
      eq(
        'AppStrings.completedEmptyMessage',
        () => LegacyAppStrings.completedEmptyMessage,
        () => AppStrings.completedEmptyMessage,
      );
      eq(
        'AppStrings.deliver',
        () => LegacyAppStrings.deliver,
        () => AppStrings.deliver,
      );
      eq(
        'AppStrings.deliverTitle',
        () => LegacyAppStrings.deliverTitle,
        () => AppStrings.deliverTitle,
      );
      eq(
        'AppStrings.deliverMessage',
        () => LegacyAppStrings.deliverMessage,
        () => AppStrings.deliverMessage,
      );
      eq(
        'AppStrings.orderDelivered',
        () => LegacyAppStrings.orderDelivered,
        () => AppStrings.orderDelivered,
      );
      eq(
        'AppStrings.deliverFailed',
        () => LegacyAppStrings.deliverFailed,
        () => AppStrings.deliverFailed,
      );
      eq(
        'AppStrings.reopenOrder',
        () => LegacyAppStrings.reopenOrder,
        () => AppStrings.reopenOrder,
      );
      eq(
        'AppStrings.reopenTitle',
        () => LegacyAppStrings.reopenTitle,
        () => AppStrings.reopenTitle,
      );
      eq(
        'AppStrings.reopenMessage',
        () => LegacyAppStrings.reopenMessage,
        () => AppStrings.reopenMessage,
      );
      eq(
        'AppStrings.reopenFailed',
        () => LegacyAppStrings.reopenFailed,
        () => AppStrings.reopenFailed,
      );
      eq(
        'AppStrings.reopenNeedsUnlinkSetting',
        () => LegacyAppStrings.reopenNeedsUnlinkSetting,
        () => AppStrings.reopenNeedsUnlinkSetting,
      );
      eq(
        'AppStrings.ordersRefreshFailed',
        () => LegacyAppStrings.ordersRefreshFailed,
        () => AppStrings.ordersRefreshFailed,
      );
      eq(
        'AppStrings.tabUnpaid',
        () => LegacyAppStrings.tabUnpaid,
        () => AppStrings.tabUnpaid,
      );
      eq(
        'AppStrings.tabPartlyPaid',
        () => LegacyAppStrings.tabPartlyPaid,
        () => AppStrings.tabPartlyPaid,
      );
      eq(
        'AppStrings.tabPaid',
        () => LegacyAppStrings.tabPaid,
        () => AppStrings.tabPaid,
      );
      eq(
        'AppStrings.invoicesDraftEmptyTitle',
        () => LegacyAppStrings.invoicesDraftEmptyTitle,
        () => AppStrings.invoicesDraftEmptyTitle,
      );
      eq(
        'AppStrings.invoicesDraftEmptyMessage',
        () => LegacyAppStrings.invoicesDraftEmptyMessage,
        () => AppStrings.invoicesDraftEmptyMessage,
      );
      eq(
        'AppStrings.invoicesUnpaidEmptyTitle',
        () => LegacyAppStrings.invoicesUnpaidEmptyTitle,
        () => AppStrings.invoicesUnpaidEmptyTitle,
      );
      eq(
        'AppStrings.invoicesUnpaidEmptyMessage',
        () => LegacyAppStrings.invoicesUnpaidEmptyMessage,
        () => AppStrings.invoicesUnpaidEmptyMessage,
      );
      eq(
        'AppStrings.invoicesPartlyEmptyTitle',
        () => LegacyAppStrings.invoicesPartlyEmptyTitle,
        () => AppStrings.invoicesPartlyEmptyTitle,
      );
      eq(
        'AppStrings.invoicesPartlyEmptyMessage',
        () => LegacyAppStrings.invoicesPartlyEmptyMessage,
        () => AppStrings.invoicesPartlyEmptyMessage,
      );
      eq(
        'AppStrings.invoicesPaidEmptyTitle',
        () => LegacyAppStrings.invoicesPaidEmptyTitle,
        () => AppStrings.invoicesPaidEmptyTitle,
      );
      eq(
        'AppStrings.invoicesPaidEmptyMessage',
        () => LegacyAppStrings.invoicesPaidEmptyMessage,
        () => AppStrings.invoicesPaidEmptyMessage,
      );
      eq(
        'AppStrings.amountDue',
        () => LegacyAppStrings.amountDue,
        () => AppStrings.amountDue,
      );
      eq(
        'AppStrings.payAction',
        () => LegacyAppStrings.payAction,
        () => AppStrings.payAction,
      );
      eq(
        'AppStrings.payInvoiceTitle',
        () => LegacyAppStrings.payInvoiceTitle,
        () => AppStrings.payInvoiceTitle,
      );
      eq(
        'AppStrings.payAmountLabel',
        () => LegacyAppStrings.payAmountLabel,
        () => AppStrings.payAmountLabel,
      );
      eq(
        'AppStrings.payNoteLabel',
        () => LegacyAppStrings.payNoteLabel,
        () => AppStrings.payNoteLabel,
      );
      eq(
        'AppStrings.payAmountRequired',
        () => LegacyAppStrings.payAmountRequired,
        () => AppStrings.payAmountRequired,
      );
      eq(
        'AppStrings.payAmountPositive',
        () => LegacyAppStrings.payAmountPositive,
        () => AppStrings.payAmountPositive,
      );
      eq(
        'AppStrings.paySave',
        () => LegacyAppStrings.paySave,
        () => AppStrings.paySave,
      );
      eq(
        'AppStrings.paymentSavedPending',
        () => LegacyAppStrings.paymentSavedPending,
        () => AppStrings.paymentSavedPending,
      );
      eq(
        'AppStrings.paymentSaveFailed',
        () => LegacyAppStrings.paymentSaveFailed,
        () => AppStrings.paymentSaveFailed,
      );
      eq(
        'AppStrings.deliveriesDraftEmptyTitle',
        () => LegacyAppStrings.deliveriesDraftEmptyTitle,
        () => AppStrings.deliveriesDraftEmptyTitle,
      );
      eq(
        'AppStrings.deliveriesDraftEmptyMessage',
        () => LegacyAppStrings.deliveriesDraftEmptyMessage,
        () => AppStrings.deliveriesDraftEmptyMessage,
      );
      eq(
        'AppStrings.deliveriesToBillEmptyTitle',
        () => LegacyAppStrings.deliveriesToBillEmptyTitle,
        () => AppStrings.deliveriesToBillEmptyTitle,
      );
      eq(
        'AppStrings.deliveriesToBillEmptyMessage',
        () => LegacyAppStrings.deliveriesToBillEmptyMessage,
        () => AppStrings.deliveriesToBillEmptyMessage,
      );
      eq(
        'AppStrings.deliveriesCompletedEmptyTitle',
        () => LegacyAppStrings.deliveriesCompletedEmptyTitle,
        () => AppStrings.deliveriesCompletedEmptyTitle,
      );
      eq(
        'AppStrings.deliveriesCompletedEmptyMessage',
        () => LegacyAppStrings.deliveriesCompletedEmptyMessage,
        () => AppStrings.deliveriesCompletedEmptyMessage,
      );
      eq(
        'AppStrings.deliveryDraftStatus',
        () => LegacyAppStrings.deliveryDraftStatus,
        () => AppStrings.deliveryDraftStatus,
      );
      eq('AppStrings.bill', () => LegacyAppStrings.bill, () => AppStrings.bill);
      eq(
        'AppStrings.billTitle',
        () => LegacyAppStrings.billTitle,
        () => AppStrings.billTitle,
      );
      eq(
        'AppStrings.billMessage',
        () => LegacyAppStrings.billMessage,
        () => AppStrings.billMessage,
      );
      eq(
        'AppStrings.orderBilled',
        () => LegacyAppStrings.orderBilled,
        () => AppStrings.orderBilled,
      );
      eq(
        'AppStrings.invoiceAwaitingApproval',
        () => LegacyAppStrings.invoiceAwaitingApproval,
        () => AppStrings.invoiceAwaitingApproval,
      );
      eq(
        'AppStrings.billNoDeliveryNote',
        () => LegacyAppStrings.billNoDeliveryNote,
        () => AppStrings.billNoDeliveryNote,
      );
      eq(
        'AppStrings.payWaitingInvoiceApproval',
        () => LegacyAppStrings.payWaitingInvoiceApproval,
        () => AppStrings.payWaitingInvoiceApproval,
      );
      eq(
        'AppStrings.payFieldRequired',
        () => LegacyAppStrings.payFieldRequired,
        () => AppStrings.payFieldRequired,
      );
      eq(
        'AppStrings.payRefCheque',
        () => LegacyAppStrings.payRefCheque,
        () => AppStrings.payRefCheque,
      );
      eq(
        'AppStrings.payDateCheque',
        () => LegacyAppStrings.payDateCheque,
        () => AppStrings.payDateCheque,
      );
      eq(
        'AppStrings.payChequeBank',
        () => LegacyAppStrings.payChequeBank,
        () => AppStrings.payChequeBank,
      );
      eq(
        'AppStrings.payDrawerName',
        () => LegacyAppStrings.payDrawerName,
        () => AppStrings.payDrawerName,
      );
      eq(
        'AppStrings.payRefCard',
        () => LegacyAppStrings.payRefCard,
        () => AppStrings.payRefCard,
      );
      eq(
        'AppStrings.payDateCard',
        () => LegacyAppStrings.payDateCard,
        () => AppStrings.payDateCard,
      );
      eq(
        'AppStrings.payCardLast4',
        () => LegacyAppStrings.payCardLast4,
        () => AppStrings.payCardLast4,
      );
      eq(
        'AppStrings.payCardLast4Helper',
        () => LegacyAppStrings.payCardLast4Helper,
        () => AppStrings.payCardLast4Helper,
      );
      eq(
        'AppStrings.payCardLast4Invalid',
        () => LegacyAppStrings.payCardLast4Invalid,
        () => AppStrings.payCardLast4Invalid,
      );
      eq(
        'AppStrings.payCardBrand',
        () => LegacyAppStrings.payCardBrand,
        () => AppStrings.payCardBrand,
      );
      eq(
        'AppStrings.payRefTransfer',
        () => LegacyAppStrings.payRefTransfer,
        () => AppStrings.payRefTransfer,
      );
      eq(
        'AppStrings.payDateTransfer',
        () => LegacyAppStrings.payDateTransfer,
        () => AppStrings.payDateTransfer,
      );
      eq(
        'AppStrings.paySenderBank',
        () => LegacyAppStrings.paySenderBank,
        () => AppStrings.paySenderBank,
      );
      eq(
        'AppStrings.payRefGeneric',
        () => LegacyAppStrings.payRefGeneric,
        () => AppStrings.payRefGeneric,
      );
      eq(
        'AppStrings.payDateGeneric',
        () => LegacyAppStrings.payDateGeneric,
        () => AppStrings.payDateGeneric,
      );
      eq(
        'AppStrings.billFailed',
        () => LegacyAppStrings.billFailed,
        () => AppStrings.billFailed,
      );
      eq(
        'AppStrings.billWaitingApproval',
        () => LegacyAppStrings.billWaitingApproval,
        () => AppStrings.billWaitingApproval,
      );
      eq(
        'AppStrings.comingSoon',
        () => LegacyAppStrings.comingSoon,
        () => AppStrings.comingSoon,
      );
      eq(
        'AppStrings.comingSoonMessage',
        () => LegacyAppStrings.comingSoonMessage,
        () => AppStrings.comingSoonMessage,
      );
      eq(
        'AppStrings.settings',
        () => LegacyAppStrings.settings,
        () => AppStrings.settings,
      );
      eq(
        'AppStrings.appearanceTitle',
        () => LegacyAppStrings.appearanceTitle,
        () => AppStrings.appearanceTitle,
      );
      eq(
        'AppStrings.appearanceDesc',
        () => LegacyAppStrings.appearanceDesc,
        () => AppStrings.appearanceDesc,
      );
      eq(
        'AppStrings.themeDark',
        () => LegacyAppStrings.themeDark,
        () => AppStrings.themeDark,
      );
      eq(
        'AppStrings.themeLight',
        () => LegacyAppStrings.themeLight,
        () => AppStrings.themeLight,
      );
      eq(
        'AppStrings.themeCustom',
        () => LegacyAppStrings.themeCustom,
        () => AppStrings.themeCustom,
      );
      eq(
        'AppStrings.themeChooseColor',
        () => LegacyAppStrings.themeChooseColor,
        () => AppStrings.themeChooseColor,
      );
      eq(
        'AppStrings.customers',
        () => LegacyAppStrings.customers,
        () => AppStrings.customers,
      );
      eq(
        'AppStrings.addCustomer',
        () => LegacyAppStrings.addCustomer,
        () => AppStrings.addCustomer,
      );
      eq(
        'AppStrings.addCustomerTitle',
        () => LegacyAppStrings.addCustomerTitle,
        () => AppStrings.addCustomerTitle,
      );
      eq(
        'AppStrings.addFirstCustomer',
        () => LegacyAppStrings.addFirstCustomer,
        () => AppStrings.addFirstCustomer,
      );
      eq(
        'AppStrings.searchHint',
        () => LegacyAppStrings.searchHint,
        () => AppStrings.searchHint,
      );
      eq(
        'AppStrings.loadingCustomers',
        () => LegacyAppStrings.loadingCustomers,
        () => AppStrings.loadingCustomers,
      );
      eq(
        'AppStrings.noCustomersTitle',
        () => LegacyAppStrings.noCustomersTitle,
        () => AppStrings.noCustomersTitle,
      );
      eq(
        'AppStrings.noCustomersMessage',
        () => LegacyAppStrings.noCustomersMessage,
        () => AppStrings.noCustomersMessage,
      );
      eq(
        'AppStrings.noSearchResultsTitle',
        () => LegacyAppStrings.noSearchResultsTitle,
        () => AppStrings.noSearchResultsTitle,
      );
      eq(
        'AppStrings.noSearchResultsMessage',
        () => LegacyAppStrings.noSearchResultsMessage,
        () => AppStrings.noSearchResultsMessage,
      );
      eq(
        'AppStrings.customerAdded',
        () => LegacyAppStrings.customerAdded,
        () => AppStrings.customerAdded,
      );
      eq(
        'AppStrings.customerSavedLocalOnly',
        () => LegacyAppStrings.customerSavedLocalOnly,
        () => AppStrings.customerSavedLocalOnly,
      );
      eq(
        'AppStrings.customerPhoneNotSaved',
        () => LegacyAppStrings.customerPhoneNotSaved,
        () => AppStrings.customerPhoneNotSaved,
      );
      eq(
        'AppStrings.customerType',
        () => LegacyAppStrings.customerType,
        () => AppStrings.customerType,
      );
      eq(
        'AppStrings.customerTypeCompany',
        () => LegacyAppStrings.customerTypeCompany,
        () => AppStrings.customerTypeCompany,
      );
      eq(
        'AppStrings.customerTypeIndividual',
        () => LegacyAppStrings.customerTypeIndividual,
        () => AppStrings.customerTypeIndividual,
      );
      eq(
        'AppStrings.customerGroup',
        () => LegacyAppStrings.customerGroup,
        () => AppStrings.customerGroup,
      );
      eq(
        'AppStrings.customerGroupRequired',
        () => LegacyAppStrings.customerGroupRequired,
        () => AppStrings.customerGroupRequired,
      );
      eq(
        'AppStrings.territory',
        () => LegacyAppStrings.territory,
        () => AppStrings.territory,
      );
      eq(
        'AppStrings.territoryRequired',
        () => LegacyAppStrings.territoryRequired,
        () => AppStrings.territoryRequired,
      );
      eq(
        'AppStrings.customerSaveFailed',
        () => LegacyAppStrings.customerSaveFailed,
        () => AppStrings.customerSaveFailed,
      );
      eq(
        'AppStrings.totalDebts',
        () => LegacyAppStrings.totalDebts,
        () => AppStrings.totalDebts,
      );
      eq(
        'AppStrings.loadCustomersError',
        () => LegacyAppStrings.loadCustomersError,
        () => AppStrings.loadCustomersError,
      );
      eq(
        'AppStrings.loadMoreCustomersError',
        () => LegacyAppStrings.loadMoreCustomersError,
        () => AppStrings.loadMoreCustomersError,
      );
      eq(
        'AppStrings.unknownInitial',
        () => LegacyAppStrings.unknownInitial,
        () => AppStrings.unknownInitial,
      );
      eq(
        'AppStrings.sortTooltip',
        () => LegacyAppStrings.sortTooltip,
        () => AppStrings.sortTooltip,
      );
      eq(
        'AppStrings.sortByName',
        () => LegacyAppStrings.sortByName,
        () => AppStrings.sortByName,
      );
      eq(
        'AppStrings.sortNewest',
        () => LegacyAppStrings.sortNewest,
        () => AppStrings.sortNewest,
      );
      eq(
        'AppStrings.sortHighestDebt',
        () => LegacyAppStrings.sortHighestDebt,
        () => AppStrings.sortHighestDebt,
      );
      eq('AppStrings.name', () => LegacyAppStrings.name, () => AppStrings.name);
      eq(
        'AppStrings.phone',
        () => LegacyAppStrings.phone,
        () => AppStrings.phone,
      );
      eq(
        'AppStrings.nameRequired',
        () => LegacyAppStrings.nameRequired,
        () => AppStrings.nameRequired,
      );
      eq(
        'AppStrings.phoneRequired',
        () => LegacyAppStrings.phoneRequired,
        () => AppStrings.phoneRequired,
      );
      eq(
        'AppStrings.amount',
        () => LegacyAppStrings.amount,
        () => AppStrings.amount,
      );
      eq(
        'AppStrings.noteOptional',
        () => LegacyAppStrings.noteOptional,
        () => AppStrings.noteOptional,
      );
      eq(
        'AppStrings.amountInvalid',
        () => LegacyAppStrings.amountInvalid,
        () => AppStrings.amountInvalid,
      );
      eq(
        'AppStrings.amountMustBePositive',
        () => LegacyAppStrings.amountMustBePositive,
        () => AppStrings.amountMustBePositive,
      );
      eq(
        'AppStrings.editCustomer',
        () => LegacyAppStrings.editCustomer,
        () => AppStrings.editCustomer,
      );
      eq(
        'AppStrings.editCustomerTitle',
        () => LegacyAppStrings.editCustomerTitle,
        () => AppStrings.editCustomerTitle,
      );
      eq(
        'AppStrings.saveChanges',
        () => LegacyAppStrings.saveChanges,
        () => AppStrings.saveChanges,
      );
      eq(
        'AppStrings.phoneInvalid',
        () => LegacyAppStrings.phoneInvalid,
        () => AppStrings.phoneInvalid,
      );
      eq(
        'AppStrings.phoneHint',
        () => LegacyAppStrings.phoneHint,
        () => AppStrings.phoneHint,
      );
      eq(
        'AppStrings.customerUpdated',
        () => LegacyAppStrings.customerUpdated,
        () => AppStrings.customerUpdated,
      );
      eq(
        'AppStrings.customerUpdateFailed',
        () => LegacyAppStrings.customerUpdateFailed,
        () => AppStrings.customerUpdateFailed,
      );
      eq(
        'AppStrings.delete',
        () => LegacyAppStrings.delete,
        () => AppStrings.delete,
      );
      eq('AppStrings.undo', () => LegacyAppStrings.undo, () => AppStrings.undo);
      eq(
        'AppStrings.deleteCustomerTitle',
        () => LegacyAppStrings.deleteCustomerTitle,
        () => AppStrings.deleteCustomerTitle,
      );
      eq(
        'AppStrings.deleteCustomerMessage',
        () => LegacyAppStrings.deleteCustomerMessage,
        () => AppStrings.deleteCustomerMessage,
      );
      eq(
        'AppStrings.customerDeleteFailed',
        () => LegacyAppStrings.customerDeleteFailed,
        () => AppStrings.customerDeleteFailed,
      );
      eq(
        'AppStrings.customerRestored',
        () => LegacyAppStrings.customerRestored,
        () => AppStrings.customerRestored,
      );
      eq(
        'AppStrings.customerRestoreFailed',
        () => LegacyAppStrings.customerRestoreFailed,
        () => AppStrings.customerRestoreFailed,
      );
      eq(
        'AppStrings.whatsappButton',
        () => LegacyAppStrings.whatsappButton,
        () => AppStrings.whatsappButton,
      );
      eq(
        'AppStrings.whatsappNotInstalled',
        () => LegacyAppStrings.whatsappNotInstalled,
        () => AppStrings.whatsappNotInstalled,
      );
      eq(
        'AppStrings.whatsappInvalidPhone',
        () => LegacyAppStrings.whatsappInvalidPhone,
        () => AppStrings.whatsappInvalidPhone,
      );
      eq(
        'AppStrings.whatsappNoDebt',
        () => LegacyAppStrings.whatsappNoDebt,
        () => AppStrings.whatsappNoDebt,
      );
      eq(
        'AppStrings.whatsappFailed',
        () => LegacyAppStrings.whatsappFailed,
        () => AppStrings.whatsappFailed,
      );
      eq('AppStrings.owed', () => LegacyAppStrings.owed, () => AppStrings.owed);
      eq(
        'AppStrings.hasCredit',
        () => LegacyAppStrings.hasCredit,
        () => AppStrings.hasCredit,
      );
      eq(
        'AppStrings.settled',
        () => LegacyAppStrings.settled,
        () => AppStrings.settled,
      );
      eq(
        'AppStrings.balanceOwedLong',
        () => LegacyAppStrings.balanceOwedLong,
        () => AppStrings.balanceOwedLong,
      );
      eq(
        'AppStrings.balanceCreditLong',
        () => LegacyAppStrings.balanceCreditLong,
        () => AppStrings.balanceCreditLong,
      );
      eq(
        'AppStrings.balanceSettledLong',
        () => LegacyAppStrings.balanceSettledLong,
        () => AppStrings.balanceSettledLong,
      );
      eq(
        'AppStrings.balancesPerCurrencyNote',
        () => LegacyAppStrings.balancesPerCurrencyNote,
        () => AppStrings.balancesPerCurrencyNote,
      );
      eq(
        'AppStrings.addDebt',
        () => LegacyAppStrings.addDebt,
        () => AppStrings.addDebt,
      );
      eq(
        'AppStrings.addPayment',
        () => LegacyAppStrings.addPayment,
        () => AppStrings.addPayment,
      );
      eq(
        'AppStrings.paymentsDraftEmpty',
        () => LegacyAppStrings.paymentsDraftEmpty,
        () => AppStrings.paymentsDraftEmpty,
      );
      eq(
        'AppStrings.paymentsApprovedEmpty',
        () => LegacyAppStrings.paymentsApprovedEmpty,
        () => AppStrings.paymentsApprovedEmpty,
      );
      eq(
        'AppStrings.paymentsLoadFailed',
        () => LegacyAppStrings.paymentsLoadFailed,
        () => AppStrings.paymentsLoadFailed,
      );
      eq(
        'AppStrings.paymentStatusDraft',
        () => LegacyAppStrings.paymentStatusDraft,
        () => AppStrings.paymentStatusDraft,
      );
      eq(
        'AppStrings.paymentStatusApproved',
        () => LegacyAppStrings.paymentStatusApproved,
        () => AppStrings.paymentStatusApproved,
      );
      eq(
        'AppStrings.paymentApprove',
        () => LegacyAppStrings.paymentApprove,
        () => AppStrings.paymentApprove,
      );
      eq(
        'AppStrings.paymentCancel',
        () => LegacyAppStrings.paymentCancel,
        () => AppStrings.paymentCancel,
      );
      eq(
        'AppStrings.paymentDetails',
        () => LegacyAppStrings.paymentDetails,
        () => AppStrings.paymentDetails,
      );
      eq(
        'AppStrings.paymentApproveMessage',
        () => LegacyAppStrings.paymentApproveMessage,
        () => AppStrings.paymentApproveMessage,
      );
      eq(
        'AppStrings.paymentCancelMessage',
        () => LegacyAppStrings.paymentCancelMessage,
        () => AppStrings.paymentCancelMessage,
      );
      eq(
        'AppStrings.paymentApproved',
        () => LegacyAppStrings.paymentApproved,
        () => AppStrings.paymentApproved,
      );
      eq(
        'AppStrings.paymentCancelled',
        () => LegacyAppStrings.paymentCancelled,
        () => AppStrings.paymentCancelled,
      );
      eq(
        'AppStrings.paymentApproveFailed',
        () => LegacyAppStrings.paymentApproveFailed,
        () => AppStrings.paymentApproveFailed,
      );
      eq(
        'AppStrings.paymentCancelFailed',
        () => LegacyAppStrings.paymentCancelFailed,
        () => AppStrings.paymentCancelFailed,
      );
      eq(
        'AppStrings.paymentSavedDraft',
        () => LegacyAppStrings.paymentSavedDraft,
        () => AppStrings.paymentSavedDraft,
      );
      eq('AppStrings.debt', () => LegacyAppStrings.debt, () => AppStrings.debt);
      eq(
        'AppStrings.payment',
        () => LegacyAppStrings.payment,
        () => AppStrings.payment,
      );
      eq(
        'AppStrings.debtAdded',
        () => LegacyAppStrings.debtAdded,
        () => AppStrings.debtAdded,
      );
      eq(
        'AppStrings.paymentAdded',
        () => LegacyAppStrings.paymentAdded,
        () => AppStrings.paymentAdded,
      );
      eq(
        'AppStrings.operationsLog',
        () => LegacyAppStrings.operationsLog,
        () => AppStrings.operationsLog,
      );
      eq(
        'AppStrings.noOperationsTitle',
        () => LegacyAppStrings.noOperationsTitle,
        () => AppStrings.noOperationsTitle,
      );
      eq(
        'AppStrings.noOperationsMessage',
        () => LegacyAppStrings.noOperationsMessage,
        () => AppStrings.noOperationsMessage,
      );
      eq(
        'AppStrings.loadOperationsError',
        () => LegacyAppStrings.loadOperationsError,
        () => AppStrings.loadOperationsError,
      );
      eq(
        'AppStrings.operationSaveFailed',
        () => LegacyAppStrings.operationSaveFailed,
        () => AppStrings.operationSaveFailed,
      );
      eq(
        'AppStrings.currency',
        () => LegacyAppStrings.currency,
        () => AppStrings.currency,
      );
      eq(
        'AppStrings.modeOfPayment',
        () => LegacyAppStrings.modeOfPayment,
        () => AppStrings.modeOfPayment,
      );
      eq(
        'AppStrings.currencyRequired',
        () => LegacyAppStrings.currencyRequired,
        () => AppStrings.currencyRequired,
      );
      eq(
        'AppStrings.accountCurrency',
        () => LegacyAppStrings.accountCurrency,
        () => AppStrings.accountCurrency,
      );
      eq(
        'AppStrings.accountCurrencyHelper',
        () => LegacyAppStrings.accountCurrencyHelper,
        () => AppStrings.accountCurrencyHelper,
      );
      eq(
        'AppStrings.accountCurrencyAuto',
        () => LegacyAppStrings.accountCurrencyAuto,
        () => AppStrings.accountCurrencyAuto,
      );
      eq(
        'AppStrings.modeOfPaymentRequired',
        () => LegacyAppStrings.modeOfPaymentRequired,
        () => AppStrings.modeOfPaymentRequired,
      );
      eq(
        'AppStrings.modesOfPaymentUnavailable',
        () => LegacyAppStrings.modesOfPaymentUnavailable,
        () => AppStrings.modesOfPaymentUnavailable,
      );
      eq(
        'AppStrings.paymentCustomerAccountMissing',
        () => LegacyAppStrings.paymentCustomerAccountMissing,
        () => AppStrings.paymentCustomerAccountMissing,
      );
      eq(
        'AppStrings.invoicesOutstandingTitle',
        () => LegacyAppStrings.invoicesOutstandingTitle,
        () => AppStrings.invoicesOutstandingTitle,
      );
      eq(
        'AppStrings.accountBalance',
        () => LegacyAppStrings.accountBalance,
        () => AppStrings.accountBalance,
      );
      eq(
        'AppStrings.noInvoiceOutstanding',
        () => LegacyAppStrings.noInvoiceOutstanding,
        () => AppStrings.noInvoiceOutstanding,
      );
      eq(
        'AppStrings.accountBalanceHint',
        () => LegacyAppStrings.accountBalanceHint,
        () => AppStrings.accountBalanceHint,
      );
      eq(
        'AppStrings.loadingRate',
        () => LegacyAppStrings.loadingRate,
        () => AppStrings.loadingRate,
      );
      eq(
        'AppStrings.tabOperations',
        () => LegacyAppStrings.tabOperations,
        () => AppStrings.tabOperations,
      );
      eq(
        'AppStrings.tabInvoice',
        () => LegacyAppStrings.tabInvoice,
        () => AppStrings.tabInvoice,
      );
      eq(
        'AppStrings.invoicesTitle',
        () => LegacyAppStrings.invoicesTitle,
        () => AppStrings.invoicesTitle,
      );
      eq(
        'AppStrings.invoicesButtonHint',
        () => LegacyAppStrings.invoicesButtonHint,
        () => AppStrings.invoicesButtonHint,
      );
      eq(
        'AppStrings.tabDraft',
        () => LegacyAppStrings.tabDraft,
        () => AppStrings.tabDraft,
      );
      eq(
        'AppStrings.tabSubmitted',
        () => LegacyAppStrings.tabSubmitted,
        () => AppStrings.tabSubmitted,
      );
      eq(
        'AppStrings.draftsEmptyTitle',
        () => LegacyAppStrings.draftsEmptyTitle,
        () => AppStrings.draftsEmptyTitle,
      );
      eq(
        'AppStrings.draftsEmptyMessage',
        () => LegacyAppStrings.draftsEmptyMessage,
        () => AppStrings.draftsEmptyMessage,
      );
      eq(
        'AppStrings.draftEdit',
        () => LegacyAppStrings.draftEdit,
        () => AppStrings.draftEdit,
      );
      eq(
        'AppStrings.draftApprove',
        () => LegacyAppStrings.draftApprove,
        () => AppStrings.draftApprove,
      );
      eq(
        'AppStrings.draftSubmit',
        () => LegacyAppStrings.draftSubmit,
        () => AppStrings.draftSubmit,
      );
      eq(
        'AppStrings.editDraftTitle',
        () => LegacyAppStrings.editDraftTitle,
        () => AppStrings.editDraftTitle,
      );
      eq(
        'AppStrings.draftNeedsUploadNote',
        () => LegacyAppStrings.draftNeedsUploadNote,
        () => AppStrings.draftNeedsUploadNote,
      );
      eq(
        'AppStrings.draftDeleteTitle',
        () => LegacyAppStrings.draftDeleteTitle,
        () => AppStrings.draftDeleteTitle,
      );
      eq(
        'AppStrings.draftDeleteMessage',
        () => LegacyAppStrings.draftDeleteMessage,
        () => AppStrings.draftDeleteMessage,
      );
      eq(
        'AppStrings.draftSubmitTitle',
        () => LegacyAppStrings.draftSubmitTitle,
        () => AppStrings.draftSubmitTitle,
      );
      eq(
        'AppStrings.draftSubmitMessage',
        () => LegacyAppStrings.draftSubmitMessage,
        () => AppStrings.draftSubmitMessage,
      );
      eq(
        'AppStrings.draftDeleted',
        () => LegacyAppStrings.draftDeleted,
        () => AppStrings.draftDeleted,
      );
      eq(
        'AppStrings.draftSubmitted',
        () => LegacyAppStrings.draftSubmitted,
        () => AppStrings.draftSubmitted,
      );
      eq(
        'AppStrings.draftUpdated',
        () => LegacyAppStrings.draftUpdated,
        () => AppStrings.draftUpdated,
      );
      eq(
        'AppStrings.draftNeedsConnection',
        () => LegacyAppStrings.draftNeedsConnection,
        () => AppStrings.draftNeedsConnection,
      );
      eq(
        'AppStrings.draftSaveFailed',
        () => LegacyAppStrings.draftSaveFailed,
        () => AppStrings.draftSaveFailed,
      );
      eq(
        'AppStrings.draftDeleteFailed',
        () => LegacyAppStrings.draftDeleteFailed,
        () => AppStrings.draftDeleteFailed,
      );
      eq(
        'AppStrings.draftSubmitFailed',
        () => LegacyAppStrings.draftSubmitFailed,
        () => AppStrings.draftSubmitFailed,
      );
      eq(
        'AppStrings.draftStateChanged',
        () => LegacyAppStrings.draftStateChanged,
        () => AppStrings.draftStateChanged,
      );
      eq(
        'AppStrings.draftNoItems',
        () => LegacyAppStrings.draftNoItems,
        () => AppStrings.draftNoItems,
      );
      eq(
        'AppStrings.printInvoice',
        () => LegacyAppStrings.printInvoice,
        () => AppStrings.printInvoice,
      );
      eq(
        'AppStrings.invoiceTitle',
        () => LegacyAppStrings.invoiceTitle,
        () => AppStrings.invoiceTitle,
      );
      eq(
        'AppStrings.invoiceNumber',
        () => LegacyAppStrings.invoiceNumber,
        () => AppStrings.invoiceNumber,
      );
      eq(
        'AppStrings.invoiceCustomer',
        () => LegacyAppStrings.invoiceCustomer,
        () => AppStrings.invoiceCustomer,
      );
      eq(
        'AppStrings.invoiceAmount',
        () => LegacyAppStrings.invoiceAmount,
        () => AppStrings.invoiceAmount,
      );
      eq(
        'AppStrings.viewInvoicePdf',
        () => LegacyAppStrings.viewInvoicePdf,
        () => AppStrings.viewInvoicePdf,
      );
      eq(
        'AppStrings.glEntriesTitle',
        () => LegacyAppStrings.glEntriesTitle,
        () => AppStrings.glEntriesTitle,
      );
      eq(
        'AppStrings.glEntriesLoading',
        () => LegacyAppStrings.glEntriesLoading,
        () => AppStrings.glEntriesLoading,
      );
      eq(
        'AppStrings.glEntriesLoadFailed',
        () => LegacyAppStrings.glEntriesLoadFailed,
        () => AppStrings.glEntriesLoadFailed,
      );
      eq(
        'AppStrings.glEntriesEmptyTitle',
        () => LegacyAppStrings.glEntriesEmptyTitle,
        () => AppStrings.glEntriesEmptyTitle,
      );
      eq(
        'AppStrings.glEntriesEmptyMessage',
        () => LegacyAppStrings.glEntriesEmptyMessage,
        () => AppStrings.glEntriesEmptyMessage,
      );
      eq(
        'AppStrings.glDescription',
        () => LegacyAppStrings.glDescription,
        () => AppStrings.glDescription,
      );
      eq(
        'AppStrings.glDebit',
        () => LegacyAppStrings.glDebit,
        () => AppStrings.glDebit,
      );
      eq(
        'AppStrings.glCredit',
        () => LegacyAppStrings.glCredit,
        () => AppStrings.glCredit,
      );
      eq(
        'AppStrings.glTotalDebit',
        () => LegacyAppStrings.glTotalDebit,
        () => AppStrings.glTotalDebit,
      );
      eq(
        'AppStrings.glTotalCredit',
        () => LegacyAppStrings.glTotalCredit,
        () => AppStrings.glTotalCredit,
      );
      eq(
        'AppStrings.glBalanced',
        () => LegacyAppStrings.glBalanced,
        () => AppStrings.glBalanced,
      );
      eq(
        'AppStrings.invoiceTotalValue',
        () => LegacyAppStrings.invoiceTotalValue,
        () => AppStrings.invoiceTotalValue,
      );
      eq(
        'AppStrings.invoicePaidFromCredit',
        () => LegacyAppStrings.invoicePaidFromCredit,
        () => AppStrings.invoicePaidFromCredit,
      );
      eq(
        'AppStrings.invoicePaid',
        () => LegacyAppStrings.invoicePaid,
        () => AppStrings.invoicePaid,
      );
      eq(
        'AppStrings.invoicePdfFailed',
        () => LegacyAppStrings.invoicePdfFailed,
        () => AppStrings.invoicePdfFailed,
      );
      eq(
        'AppStrings.erpSessionExpired',
        () => LegacyAppStrings.erpSessionExpired,
        () => AppStrings.erpSessionExpired,
      );
      eq(
        'AppStrings.erpForbidden',
        () => LegacyAppStrings.erpForbidden,
        () => AppStrings.erpForbidden,
      );
      eq(
        'AppStrings.erpNetworkError',
        () => LegacyAppStrings.erpNetworkError,
        () => AppStrings.erpNetworkError,
      );
      eq(
        'AppStrings.erpServerError',
        () => LegacyAppStrings.erpServerError,
        () => AppStrings.erpServerError,
      );
      eq(
        'AppStrings.offlineNoCache',
        () => LegacyAppStrings.offlineNoCache,
        () => AppStrings.offlineNoCache,
      );
      eq(
        'AppStrings.erpNotFound',
        () => LegacyAppStrings.erpNotFound,
        () => AppStrings.erpNotFound,
      );
      eq(
        'AppStrings.loadInvoicesError',
        () => LegacyAppStrings.loadInvoicesError,
        () => AppStrings.loadInvoicesError,
      );
      eq(
        'AppStrings.loadInvoiceError',
        () => LegacyAppStrings.loadInvoiceError,
        () => AppStrings.loadInvoiceError,
      );
      eq(
        'AppStrings.invoicesNoMatchTitle',
        () => LegacyAppStrings.invoicesNoMatchTitle,
        () => AppStrings.invoicesNoMatchTitle,
      );
      eq(
        'AppStrings.invoicesNoMatchMessage',
        () => LegacyAppStrings.invoicesNoMatchMessage,
        () => AppStrings.invoicesNoMatchMessage,
      );
      eq(
        'AppStrings.noInvoicesTitle',
        () => LegacyAppStrings.noInvoicesTitle,
        () => AppStrings.noInvoicesTitle,
      );
      eq(
        'AppStrings.noInvoicesMessage',
        () => LegacyAppStrings.noInvoicesMessage,
        () => AppStrings.noInvoicesMessage,
      );
      eq(
        'AppStrings.invoiceRemaining',
        () => LegacyAppStrings.invoiceRemaining,
        () => AppStrings.invoiceRemaining,
      );
      eq(
        'AppStrings.invoicePostingDate',
        () => LegacyAppStrings.invoicePostingDate,
        () => AppStrings.invoicePostingDate,
      );
      eq(
        'AppStrings.invoiceDueDate',
        () => LegacyAppStrings.invoiceDueDate,
        () => AppStrings.invoiceDueDate,
      );
      eq(
        'AppStrings.invoiceStatusLabel',
        () => LegacyAppStrings.invoiceStatusLabel,
        () => AppStrings.invoiceStatusLabel,
      );
      eq(
        'AppStrings.invoiceItems',
        () => LegacyAppStrings.invoiceItems,
        () => AppStrings.invoiceItems,
      );
      eq(
        'AppStrings.invoiceTaxes',
        () => LegacyAppStrings.invoiceTaxes,
        () => AppStrings.invoiceTaxes,
      );
      eq(
        'AppStrings.invoiceOutstanding',
        () => LegacyAppStrings.invoiceOutstanding,
        () => AppStrings.invoiceOutstanding,
      );
      eq(
        'AppStrings.newOrderTitle',
        () => LegacyAppStrings.newOrderTitle,
        () => AppStrings.newOrderTitle,
      );
      eq(
        'AppStrings.stepCustomer',
        () => LegacyAppStrings.stepCustomer,
        () => AppStrings.stepCustomer,
      );
      eq(
        'AppStrings.stepItems',
        () => LegacyAppStrings.stepItems,
        () => AppStrings.stepItems,
      );
      eq(
        'AppStrings.stepInvoice',
        () => LegacyAppStrings.stepInvoice,
        () => AppStrings.stepInvoice,
      );
      eq('AppStrings.next', () => LegacyAppStrings.next, () => AppStrings.next);
      eq('AppStrings.back', () => LegacyAppStrings.back, () => AppStrings.back);
      eq(
        'AppStrings.chooseCustomer',
        () => LegacyAppStrings.chooseCustomer,
        () => AppStrings.chooseCustomer,
      );
      eq(
        'AppStrings.chooseCustomerHint',
        () => LegacyAppStrings.chooseCustomerHint,
        () => AppStrings.chooseCustomerHint,
      );
      eq(
        'AppStrings.orderCustomersEmpty',
        () => LegacyAppStrings.orderCustomersEmpty,
        () => AppStrings.orderCustomersEmpty,
      );
      eq(
        'AppStrings.chooseGroupHint',
        () => LegacyAppStrings.chooseGroupHint,
        () => AppStrings.chooseGroupHint,
      );
      eq(
        'AppStrings.loadingGroups',
        () => LegacyAppStrings.loadingGroups,
        () => AppStrings.loadingGroups,
      );
      eq(
        'AppStrings.loadingItems',
        () => LegacyAppStrings.loadingItems,
        () => AppStrings.loadingItems,
      );
      eq(
        'AppStrings.loadGroupsError',
        () => LegacyAppStrings.loadGroupsError,
        () => AppStrings.loadGroupsError,
      );
      eq(
        'AppStrings.loadItemsError',
        () => LegacyAppStrings.loadItemsError,
        () => AppStrings.loadItemsError,
      );
      eq(
        'AppStrings.noGroupsTitle',
        () => LegacyAppStrings.noGroupsTitle,
        () => AppStrings.noGroupsTitle,
      );
      eq(
        'AppStrings.noItemsTitle',
        () => LegacyAppStrings.noItemsTitle,
        () => AppStrings.noItemsTitle,
      );
      eq(
        'AppStrings.noItemsMessage',
        () => LegacyAppStrings.noItemsMessage,
        () => AppStrings.noItemsMessage,
      );
      eq(
        'AppStrings.itemPrice',
        () => LegacyAppStrings.itemPrice,
        () => AppStrings.itemPrice,
      );
      eq(
        'AppStrings.itemStock',
        () => LegacyAppStrings.itemStock,
        () => AppStrings.itemStock,
      );
      eq(
        'AppStrings.quantity',
        () => LegacyAppStrings.quantity,
        () => AppStrings.quantity,
      );
      eq(
        'AppStrings.lineTotal',
        () => LegacyAppStrings.lineTotal,
        () => AppStrings.lineTotal,
      );
      eq(
        'AppStrings.loadingPricing',
        () => LegacyAppStrings.loadingPricing,
        () => AppStrings.loadingPricing,
      );
      eq(
        'AppStrings.loadPricingError',
        () => LegacyAppStrings.loadPricingError,
        () => AppStrings.loadPricingError,
      );
      eq(
        'AppStrings.noPriceTitle',
        () => LegacyAppStrings.noPriceTitle,
        () => AppStrings.noPriceTitle,
      );
      eq(
        'AppStrings.noPriceMessage',
        () => LegacyAppStrings.noPriceMessage,
        () => AppStrings.noPriceMessage,
      );
      eq(
        'AppStrings.outOfStock',
        () => LegacyAppStrings.outOfStock,
        () => AppStrings.outOfStock,
      );
      eq(
        'AppStrings.outOfStockMessage',
        () => LegacyAppStrings.outOfStockMessage,
        () => AppStrings.outOfStockMessage,
      );
      eq(
        'AppStrings.orderTotal',
        () => LegacyAppStrings.orderTotal,
        () => AppStrings.orderTotal,
      );
      eq(
        'AppStrings.invoiceHeading',
        () => LegacyAppStrings.invoiceHeading,
        () => AppStrings.invoiceHeading,
      );
      eq(
        'AppStrings.invoiceLinesEmpty',
        () => LegacyAppStrings.invoiceLinesEmpty,
        () => AppStrings.invoiceLinesEmpty,
      );
      eq(
        'AppStrings.unitPrice',
        () => LegacyAppStrings.unitPrice,
        () => AppStrings.unitPrice,
      );
      eq(
        'AppStrings.removeItem',
        () => LegacyAppStrings.removeItem,
        () => AppStrings.removeItem,
      );
      eq(
        'AppStrings.deliveryDate',
        () => LegacyAppStrings.deliveryDate,
        () => AppStrings.deliveryDate,
      );
      eq(
        'AppStrings.orderDate',
        () => LegacyAppStrings.orderDate,
        () => AppStrings.orderDate,
      );
      eq(
        'AppStrings.orderNotes',
        () => LegacyAppStrings.orderNotes,
        () => AppStrings.orderNotes,
      );
      eq(
        'AppStrings.orderNotesHint',
        () => LegacyAppStrings.orderNotesHint,
        () => AppStrings.orderNotesHint,
      );
      eq(
        'AppStrings.savedAsDraft',
        () => LegacyAppStrings.savedAsDraft,
        () => AppStrings.savedAsDraft,
      );
      eq(
        'AppStrings.submitOrder',
        () => LegacyAppStrings.submitOrder,
        () => AppStrings.submitOrder,
      );
      eq(
        'AppStrings.submittingOrder',
        () => LegacyAppStrings.submittingOrder,
        () => AppStrings.submittingOrder,
      );
      eq(
        'AppStrings.orderCreateFailed',
        () => LegacyAppStrings.orderCreateFailed,
        () => AppStrings.orderCreateFailed,
      );
      eq(
        'AppStrings.orderCreatedTitle',
        () => LegacyAppStrings.orderCreatedTitle,
        () => AppStrings.orderCreatedTitle,
      );
      eq(
        'AppStrings.orderNumber',
        () => LegacyAppStrings.orderNumber,
        () => AppStrings.orderNumber,
      );
      eq(
        'AppStrings.orderCreatedNote',
        () => LegacyAppStrings.orderCreatedNote,
        () => AppStrings.orderCreatedNote,
      );
      eq(
        'AppStrings.invoiceSavedNote',
        () => LegacyAppStrings.invoiceSavedNote,
        () => AppStrings.invoiceSavedNote,
      );
      eq(
        'AppStrings.invoiceNotSavedNote',
        () => LegacyAppStrings.invoiceNotSavedNote,
        () => AppStrings.invoiceNotSavedNote,
      );
      eq(
        'AppStrings.newOrderAgain',
        () => LegacyAppStrings.newOrderAgain,
        () => AppStrings.newOrderAgain,
      );
      eq(
        'AppStrings.close',
        () => LegacyAppStrings.close,
        () => AppStrings.close,
      );
      eq(
        'AppStrings.copied',
        () => LegacyAppStrings.copied,
        () => AppStrings.copied,
      );
      eq(
        'AppStrings.leaveOrderTitle',
        () => LegacyAppStrings.leaveOrderTitle,
        () => AppStrings.leaveOrderTitle,
      );
      eq(
        'AppStrings.leaveOrderMessage',
        () => LegacyAppStrings.leaveOrderMessage,
        () => AppStrings.leaveOrderMessage,
      );
      eq(
        'AppStrings.keepEditing',
        () => LegacyAppStrings.keepEditing,
        () => AppStrings.keepEditing,
      );
      eq(
        'AppStrings.discard',
        () => LegacyAppStrings.discard,
        () => AppStrings.discard,
      );
      eq(
        'AppStrings.orderRateLoading',
        () => LegacyAppStrings.orderRateLoading,
        () => AppStrings.orderRateLoading,
      );
      eq(
        'AppStrings.orderRateNeedsConnection',
        () => LegacyAppStrings.orderRateNeedsConnection,
        () => AppStrings.orderRateNeedsConnection,
      );
      eq(
        'AppStrings.orderRateFailed',
        () => LegacyAppStrings.orderRateFailed,
        () => AppStrings.orderRateFailed,
      );
      eq(
        'AppStrings.orderOfflineNeedsConnection',
        () => LegacyAppStrings.orderOfflineNeedsConnection,
        () => AppStrings.orderOfflineNeedsConnection,
      );
      eq(
        'AppStrings.orderSavedOfflineTitle',
        () => LegacyAppStrings.orderSavedOfflineTitle,
        () => AppStrings.orderSavedOfflineTitle,
      );
      eq(
        'AppStrings.orderWaitingUpload',
        () => LegacyAppStrings.orderWaitingUpload,
        () => AppStrings.orderWaitingUpload,
      );
      eq(
        'AppStrings.orderSavedOfflineNote',
        () => LegacyAppStrings.orderSavedOfflineNote,
        () => AppStrings.orderSavedOfflineNote,
      );
      eq(
        'AppStrings.orderOfflineSaveFailed',
        () => LegacyAppStrings.orderOfflineSaveFailed,
        () => AppStrings.orderOfflineSaveFailed,
      );
      eq(
        'AppStrings.syncCustomersTitle',
        () => LegacyAppStrings.syncCustomersTitle,
        () => AppStrings.syncCustomersTitle,
      );
      eq(
        'AppStrings.syncCustomersDesc',
        () => LegacyAppStrings.syncCustomersDesc,
        () => AppStrings.syncCustomersDesc,
      );
      eq(
        'AppStrings.syncItemsTitle',
        () => LegacyAppStrings.syncItemsTitle,
        () => AppStrings.syncItemsTitle,
      );
      eq(
        'AppStrings.syncItemsDesc',
        () => LegacyAppStrings.syncItemsDesc,
        () => AppStrings.syncItemsDesc,
      );
      eq(
        'AppStrings.syncInvoicesTitle',
        () => LegacyAppStrings.syncInvoicesTitle,
        () => AppStrings.syncInvoicesTitle,
      );
      eq(
        'AppStrings.syncInvoicesDesc',
        () => LegacyAppStrings.syncInvoicesDesc,
        () => AppStrings.syncInvoicesDesc,
      );
      eq(
        'AppStrings.autoSyncRunning',
        () => LegacyAppStrings.autoSyncRunning,
        () => AppStrings.autoSyncRunning,
      );
      eq(
        'AppStrings.autoSyncOnline',
        () => LegacyAppStrings.autoSyncOnline,
        () => AppStrings.autoSyncOnline,
      );
      eq(
        'AppStrings.autoSyncOffline',
        () => LegacyAppStrings.autoSyncOffline,
        () => AppStrings.autoSyncOffline,
      );
      eq(
        'AppStrings.syncRunning',
        () => LegacyAppStrings.syncRunning,
        () => AppStrings.syncRunning,
      );
      eq(
        'AppStrings.neverSynced',
        () => LegacyAppStrings.neverSynced,
        () => AppStrings.neverSynced,
      );
      eq(
        'AppStrings.syncFailed',
        () => LegacyAppStrings.syncFailed,
        () => AppStrings.syncFailed,
      );
      eq(
        'AppStrings.syncCustomersFirst',
        () => LegacyAppStrings.syncCustomersFirst,
        () => AppStrings.syncCustomersFirst,
      );
      eq(
        'AppStrings.autoUploadNote',
        () => LegacyAppStrings.autoUploadNote,
        () => AppStrings.autoUploadNote,
      );
      eq(
        'AppStrings.loginTitle',
        () => LegacyAppStrings.loginTitle,
        () => AppStrings.loginTitle,
      );
      eq(
        'AppStrings.loginSubtitle',
        () => LegacyAppStrings.loginSubtitle,
        () => AppStrings.loginSubtitle,
      );
      eq(
        'AppStrings.emailLabel',
        () => LegacyAppStrings.emailLabel,
        () => AppStrings.emailLabel,
      );
      eq(
        'AppStrings.siteLabel',
        () => LegacyAppStrings.siteLabel,
        () => AppStrings.siteLabel,
      );
      eq(
        'AppStrings.siteHelper',
        () => LegacyAppStrings.siteHelper,
        () => AppStrings.siteHelper,
      );
      eq(
        'AppStrings.siteInvalid',
        () => LegacyAppStrings.siteInvalid,
        () => AppStrings.siteInvalid,
      );
      eq(
        'AppStrings.passwordLabel',
        () => LegacyAppStrings.passwordLabel,
        () => AppStrings.passwordLabel,
      );
      eq(
        'AppStrings.emailRequired',
        () => LegacyAppStrings.emailRequired,
        () => AppStrings.emailRequired,
      );
      eq(
        'AppStrings.passwordRequired',
        () => LegacyAppStrings.passwordRequired,
        () => AppStrings.passwordRequired,
      );
      eq(
        'AppStrings.loginButton',
        () => LegacyAppStrings.loginButton,
        () => AppStrings.loginButton,
      );
      eq(
        'AppStrings.loggingIn',
        () => LegacyAppStrings.loggingIn,
        () => AppStrings.loggingIn,
      );
      eq(
        'AppStrings.loginInvalid',
        () => LegacyAppStrings.loginInvalid,
        () => AppStrings.loginInvalid,
      );
      eq(
        'AppStrings.loginNetworkError',
        () => LegacyAppStrings.loginNetworkError,
        () => AppStrings.loginNetworkError,
      );
      eq(
        'AppStrings.loginServerError',
        () => LegacyAppStrings.loginServerError,
        () => AppStrings.loginServerError,
      );
      eq(
        'AppStrings.loginLockWarning',
        () => LegacyAppStrings.loginLockWarning,
        () => AppStrings.loginLockWarning,
      );
      eq(
        'AppStrings.sessionExpiredNotice',
        () => LegacyAppStrings.sessionExpiredNotice,
        () => AppStrings.sessionExpiredNotice,
      );
      eq(
        'AppStrings.showPassword',
        () => LegacyAppStrings.showPassword,
        () => AppStrings.showPassword,
      );
      eq(
        'AppStrings.hidePassword',
        () => LegacyAppStrings.hidePassword,
        () => AppStrings.hidePassword,
      );
      eq(
        'AppStrings.logout',
        () => LegacyAppStrings.logout,
        () => AppStrings.logout,
      );
      eq(
        'AppStrings.logoutConfirmTitle',
        () => LegacyAppStrings.logoutConfirmTitle,
        () => AppStrings.logoutConfirmTitle,
      );
      eq(
        'AppStrings.logoutConfirmMessage',
        () => LegacyAppStrings.logoutConfirmMessage,
        () => AppStrings.logoutConfirmMessage,
      );
      eq('AppStrings.am', () => LegacyAppStrings.am, () => AppStrings.am);
      eq('AppStrings.pm', () => LegacyAppStrings.pm, () => AppStrings.pm);
      eq(
        'AppStrings.fakeCustomersFailed',
        () => LegacyAppStrings.fakeCustomersFailed,
        () => AppStrings.fakeCustomersFailed,
      );
      eq(
        'AppStrings.orderReopened',
        () => LegacyAppStrings.orderReopened('X1'),
        () => AppStrings.orderReopened('X1'),
      );
      eq(
        'AppStrings.amountKeptOnAccount',
        () => LegacyAppStrings.amountKeptOnAccount('X1'),
        () => AppStrings.amountKeptOnAccount('X1'),
      );
      eq(
        'AppStrings.reopenHasDraftPayments',
        () => LegacyAppStrings.reopenHasDraftPayments('X1'),
        () => AppStrings.reopenHasDraftPayments('X1'),
      );
      eq(
        'AppStrings.reopenNoOrder',
        () => LegacyAppStrings.reopenNoOrder('X1'),
        () => AppStrings.reopenNoOrder('X1'),
      );
      eq(
        'AppStrings.payAmountExceeds',
        () => LegacyAppStrings.payAmountExceeds('X1'),
        () => AppStrings.payAmountExceeds('X1'),
      );
      eq(
        'AppStrings.paymentPending',
        () => LegacyAppStrings.paymentPending('X1'),
        () => AppStrings.paymentPending('X1'),
      );
      eq(
        'AppStrings.paymentNoAccountForMode',
        () => LegacyAppStrings.paymentNoAccountForMode('X1'),
        () => AppStrings.paymentNoAccountForMode('X1'),
      );
      eq(
        'AppStrings.themeColorName',
        () => LegacyAppStrings.themeColorName('X1'),
        () => AppStrings.themeColorName('X1'),
      );
      eq(
        'AppStrings.customerDeleted',
        () => LegacyAppStrings.customerDeleted('X1'),
        () => AppStrings.customerDeleted('X1'),
      );
      eq(
        'AppStrings.whatsappDebtMessage',
        () => LegacyAppStrings.whatsappDebtMessage('X1', 'X1'),
        () => AppStrings.whatsappDebtMessage('X1', 'X1'),
      );
      eq(
        'AppStrings.paymentsDraftTab',
        () => LegacyAppStrings.paymentsDraftTab(7),
        () => AppStrings.paymentsDraftTab(7),
      );
      eq(
        'AppStrings.paymentsDraftTab[\'0\']',
        () => LegacyAppStrings.paymentsDraftTab(0),
        () => AppStrings.paymentsDraftTab(0),
      );
      eq(
        'AppStrings.paymentsDraftTab[\'1\']',
        () => LegacyAppStrings.paymentsDraftTab(1),
        () => AppStrings.paymentsDraftTab(1),
      );
      eq(
        'AppStrings.paymentsDraftTab[\'2\']',
        () => LegacyAppStrings.paymentsDraftTab(2),
        () => AppStrings.paymentsDraftTab(2),
      );
      eq(
        'AppStrings.paymentsDraftTab[\'11\']',
        () => LegacyAppStrings.paymentsDraftTab(11),
        () => AppStrings.paymentsDraftTab(11),
      );
      eq(
        'AppStrings.paymentsDraftTab[\'100\']',
        () => LegacyAppStrings.paymentsDraftTab(100),
        () => AppStrings.paymentsDraftTab(100),
      );
      eq(
        'AppStrings.paymentsApprovedTab',
        () => LegacyAppStrings.paymentsApprovedTab(7),
        () => AppStrings.paymentsApprovedTab(7),
      );
      eq(
        'AppStrings.paymentsApprovedTab[\'0\']',
        () => LegacyAppStrings.paymentsApprovedTab(0),
        () => AppStrings.paymentsApprovedTab(0),
      );
      eq(
        'AppStrings.paymentsApprovedTab[\'1\']',
        () => LegacyAppStrings.paymentsApprovedTab(1),
        () => AppStrings.paymentsApprovedTab(1),
      );
      eq(
        'AppStrings.paymentsApprovedTab[\'2\']',
        () => LegacyAppStrings.paymentsApprovedTab(2),
        () => AppStrings.paymentsApprovedTab(2),
      );
      eq(
        'AppStrings.paymentsApprovedTab[\'11\']',
        () => LegacyAppStrings.paymentsApprovedTab(11),
        () => AppStrings.paymentsApprovedTab(11),
      );
      eq(
        'AppStrings.paymentsApprovedTab[\'100\']',
        () => LegacyAppStrings.paymentsApprovedTab(100),
        () => AppStrings.paymentsApprovedTab(100),
      );
      eq(
        'AppStrings.paymentApproveTitle',
        () => LegacyAppStrings.paymentApproveTitle('X1'),
        () => AppStrings.paymentApproveTitle('X1'),
      );
      eq(
        'AppStrings.paymentCancelTitle',
        () => LegacyAppStrings.paymentCancelTitle('X1'),
        () => AppStrings.paymentCancelTitle('X1'),
      );
      eq(
        'AppStrings.paymentCredited',
        () => LegacyAppStrings.paymentCredited('X1'),
        () => AppStrings.paymentCredited('X1'),
      );
      eq(
        'AppStrings.paymentModeAccountMissing',
        () => LegacyAppStrings.paymentModeAccountMissing('X1'),
        () => AppStrings.paymentModeAccountMissing('X1'),
      );
      eq(
        'AppStrings.exchangeRateMissing',
        () => LegacyAppStrings.exchangeRateMissing('X1', 'X1'),
        () => AppStrings.exchangeRateMissing('X1', 'X1'),
      );
      eq(
        'AppStrings.paymentNoAccountForCurrency',
        () => LegacyAppStrings.paymentNoAccountForCurrency('X1'),
        () => AppStrings.paymentNoAccountForCurrency('X1'),
      );
      eq(
        'AppStrings.conversionNote',
        () => LegacyAppStrings.conversionNote('X1'),
        () => AppStrings.conversionNote('X1'),
      );
      eq(
        'AppStrings.conversionResult',
        () => LegacyAppStrings.conversionResult('X1', 'X1', 'X1', 'X1'),
        () => AppStrings.conversionResult('X1', 'X1', 'X1', 'X1'),
      );
      eq(
        'AppStrings.settledAs',
        () => LegacyAppStrings.settledAs('X1', 'X1'),
        () => AppStrings.settledAs('X1', 'X1'),
      );
      eq(
        'AppStrings.paymentEntryRef',
        () => LegacyAppStrings.paymentEntryRef('X1'),
        () => AppStrings.paymentEntryRef('X1'),
      );
      eq(
        'AppStrings.operationsCount',
        () => LegacyAppStrings.operationsCount(7),
        () => AppStrings.operationsCount(7),
      );
      eq(
        'AppStrings.operationsCount[\'0\']',
        () => LegacyAppStrings.operationsCount(0),
        () => AppStrings.operationsCount(0),
      );
      eq(
        'AppStrings.operationsCount[\'1\']',
        () => LegacyAppStrings.operationsCount(1),
        () => AppStrings.operationsCount(1),
      );
      eq(
        'AppStrings.operationsCount[\'2\']',
        () => LegacyAppStrings.operationsCount(2),
        () => AppStrings.operationsCount(2),
      );
      eq(
        'AppStrings.operationsCount[\'11\']',
        () => LegacyAppStrings.operationsCount(11),
        () => AppStrings.operationsCount(11),
      );
      eq(
        'AppStrings.operationsCount[\'100\']',
        () => LegacyAppStrings.operationsCount(100),
        () => AppStrings.operationsCount(100),
      );
      eq(
        'AppStrings.glDraftsPending',
        () => LegacyAppStrings.glDraftsPending('X1'),
        () => AppStrings.glDraftsPending('X1'),
      );
      eq(
        'AppStrings.glOverpaid',
        () => LegacyAppStrings.glOverpaid('X1'),
        () => AppStrings.glOverpaid('X1'),
      );
      eq(
        'AppStrings.voucherTypeLabel',
        () => LegacyAppStrings.voucherTypeLabel('X1'),
        () => AppStrings.voucherTypeLabel('X1'),
      );
      eq(
        'AppStrings.glUnbalanced',
        () => LegacyAppStrings.glUnbalanced('X1'),
        () => AppStrings.glUnbalanced('X1'),
      );
      eq(
        'AppStrings.offlineNotice',
        () => LegacyAppStrings.offlineNotice('X1'),
        () => AppStrings.offlineNotice('X1'),
      );
      eq(
        'AppStrings.staleNotice',
        () => LegacyAppStrings.staleNotice('X1', 'X1'),
        () => AppStrings.staleNotice('X1', 'X1'),
      );
      eq(
        'AppStrings.invoiceStatus',
        () => LegacyAppStrings.invoiceStatus('X1'),
        () => AppStrings.invoiceStatus('X1'),
      );
      eq(
        'AppStrings.orderFor',
        () => LegacyAppStrings.orderFor('X1'),
        () => AppStrings.orderFor('X1'),
      );
      eq(
        'AppStrings.afterOrder',
        () => LegacyAppStrings.afterOrder('X1'),
        () => AppStrings.afterOrder('X1'),
      );
      eq(
        'AppStrings.maxAvailable',
        () => LegacyAppStrings.maxAvailable('X1'),
        () => AppStrings.maxAvailable('X1'),
      );
      eq(
        'AppStrings.selectedItemsCount',
        () => LegacyAppStrings.selectedItemsCount(7),
        () => AppStrings.selectedItemsCount(7),
      );
      eq(
        'AppStrings.selectedItemsCount[\'0\']',
        () => LegacyAppStrings.selectedItemsCount(0),
        () => AppStrings.selectedItemsCount(0),
      );
      eq(
        'AppStrings.selectedItemsCount[\'1\']',
        () => LegacyAppStrings.selectedItemsCount(1),
        () => AppStrings.selectedItemsCount(1),
      );
      eq(
        'AppStrings.selectedItemsCount[\'2\']',
        () => LegacyAppStrings.selectedItemsCount(2),
        () => AppStrings.selectedItemsCount(2),
      );
      eq(
        'AppStrings.selectedItemsCount[\'11\']',
        () => LegacyAppStrings.selectedItemsCount(11),
        () => AppStrings.selectedItemsCount(11),
      );
      eq(
        'AppStrings.selectedItemsCount[\'100\']',
        () => LegacyAppStrings.selectedItemsCount(100),
        () => AppStrings.selectedItemsCount(100),
      );
      eq(
        'AppStrings.itemGroupName',
        () => LegacyAppStrings.itemGroupName('X1'),
        () => AppStrings.itemGroupName('X1'),
      );
      eq(
        'AppStrings.orderCurrencyInfo',
        () => LegacyAppStrings.orderCurrencyInfo('X1', 2.5),
        () => AppStrings.orderCurrencyInfo('X1', 2.5),
      );
      eq(
        'AppStrings.orderCurrencyInfo["\'X1\'", \'0\']',
        () => LegacyAppStrings.orderCurrencyInfo('X1', 0),
        () => AppStrings.orderCurrencyInfo('X1', 0),
      );
      eq(
        'AppStrings.orderCurrencyInfo["\'X1\'", \'1\']',
        () => LegacyAppStrings.orderCurrencyInfo('X1', 1),
        () => AppStrings.orderCurrencyInfo('X1', 1),
      );
      eq(
        'AppStrings.orderCurrencyInfo["\'X1\'", \'1.5\']',
        () => LegacyAppStrings.orderCurrencyInfo('X1', 1.5),
        () => AppStrings.orderCurrencyInfo('X1', 1.5),
      );
      eq(
        'AppStrings.lastSynced',
        () => LegacyAppStrings.lastSynced('X1'),
        () => AppStrings.lastSynced('X1'),
      );
      eq(
        'AppStrings.syncedCustomers',
        () => LegacyAppStrings.syncedCustomers(7),
        () => AppStrings.syncedCustomers(7),
      );
      eq(
        'AppStrings.syncedCustomers[\'0\']',
        () => LegacyAppStrings.syncedCustomers(0),
        () => AppStrings.syncedCustomers(0),
      );
      eq(
        'AppStrings.syncedCustomers[\'1\']',
        () => LegacyAppStrings.syncedCustomers(1),
        () => AppStrings.syncedCustomers(1),
      );
      eq(
        'AppStrings.syncedCustomers[\'2\']',
        () => LegacyAppStrings.syncedCustomers(2),
        () => AppStrings.syncedCustomers(2),
      );
      eq(
        'AppStrings.syncedCustomers[\'11\']',
        () => LegacyAppStrings.syncedCustomers(11),
        () => AppStrings.syncedCustomers(11),
      );
      eq(
        'AppStrings.syncedCustomers[\'100\']',
        () => LegacyAppStrings.syncedCustomers(100),
        () => AppStrings.syncedCustomers(100),
      );
      eq(
        'AppStrings.syncedItems',
        () => LegacyAppStrings.syncedItems(7, 7),
        () => AppStrings.syncedItems(7, 7),
      );
      eq(
        'AppStrings.syncedItems[\'0\', \'7\']',
        () => LegacyAppStrings.syncedItems(0, 7),
        () => AppStrings.syncedItems(0, 7),
      );
      eq(
        'AppStrings.syncedItems[\'1\', \'7\']',
        () => LegacyAppStrings.syncedItems(1, 7),
        () => AppStrings.syncedItems(1, 7),
      );
      eq(
        'AppStrings.syncedItems[\'2\', \'7\']',
        () => LegacyAppStrings.syncedItems(2, 7),
        () => AppStrings.syncedItems(2, 7),
      );
      eq(
        'AppStrings.syncedItems[\'11\', \'7\']',
        () => LegacyAppStrings.syncedItems(11, 7),
        () => AppStrings.syncedItems(11, 7),
      );
      eq(
        'AppStrings.syncedItems[\'100\', \'7\']',
        () => LegacyAppStrings.syncedItems(100, 7),
        () => AppStrings.syncedItems(100, 7),
      );
      eq(
        'AppStrings.syncedItems[\'7\', \'0\']',
        () => LegacyAppStrings.syncedItems(7, 0),
        () => AppStrings.syncedItems(7, 0),
      );
      eq(
        'AppStrings.syncedItems[\'7\', \'1\']',
        () => LegacyAppStrings.syncedItems(7, 1),
        () => AppStrings.syncedItems(7, 1),
      );
      eq(
        'AppStrings.syncedItems[\'7\', \'2\']',
        () => LegacyAppStrings.syncedItems(7, 2),
        () => AppStrings.syncedItems(7, 2),
      );
      eq(
        'AppStrings.syncedItems[\'7\', \'11\']',
        () => LegacyAppStrings.syncedItems(7, 11),
        () => AppStrings.syncedItems(7, 11),
      );
      eq(
        'AppStrings.syncedItems[\'7\', \'100\']',
        () => LegacyAppStrings.syncedItems(7, 100),
        () => AppStrings.syncedItems(7, 100),
      );
      eq(
        'AppStrings.syncedInvoices',
        () => LegacyAppStrings.syncedInvoices(7),
        () => AppStrings.syncedInvoices(7),
      );
      eq(
        'AppStrings.syncedInvoices[\'0\']',
        () => LegacyAppStrings.syncedInvoices(0),
        () => AppStrings.syncedInvoices(0),
      );
      eq(
        'AppStrings.syncedInvoices[\'1\']',
        () => LegacyAppStrings.syncedInvoices(1),
        () => AppStrings.syncedInvoices(1),
      );
      eq(
        'AppStrings.syncedInvoices[\'2\']',
        () => LegacyAppStrings.syncedInvoices(2),
        () => AppStrings.syncedInvoices(2),
      );
      eq(
        'AppStrings.syncedInvoices[\'11\']',
        () => LegacyAppStrings.syncedInvoices(11),
        () => AppStrings.syncedInvoices(11),
      );
      eq(
        'AppStrings.syncedInvoices[\'100\']',
        () => LegacyAppStrings.syncedInvoices(100),
        () => AppStrings.syncedInvoices(100),
      );
      eq(
        'AppStrings.pendingOrdersCount',
        () => LegacyAppStrings.pendingOrdersCount(7),
        () => AppStrings.pendingOrdersCount(7),
      );
      eq(
        'AppStrings.pendingOrdersCount[\'0\']',
        () => LegacyAppStrings.pendingOrdersCount(0),
        () => AppStrings.pendingOrdersCount(0),
      );
      eq(
        'AppStrings.pendingOrdersCount[\'1\']',
        () => LegacyAppStrings.pendingOrdersCount(1),
        () => AppStrings.pendingOrdersCount(1),
      );
      eq(
        'AppStrings.pendingOrdersCount[\'2\']',
        () => LegacyAppStrings.pendingOrdersCount(2),
        () => AppStrings.pendingOrdersCount(2),
      );
      eq(
        'AppStrings.pendingOrdersCount[\'11\']',
        () => LegacyAppStrings.pendingOrdersCount(11),
        () => AppStrings.pendingOrdersCount(11),
      );
      eq(
        'AppStrings.pendingOrdersCount[\'100\']',
        () => LegacyAppStrings.pendingOrdersCount(100),
        () => AppStrings.pendingOrdersCount(100),
      );
      eq(
        'AppStrings.failedOrdersCount',
        () => LegacyAppStrings.failedOrdersCount(7),
        () => AppStrings.failedOrdersCount(7),
      );
      eq(
        'AppStrings.failedOrdersCount[\'0\']',
        () => LegacyAppStrings.failedOrdersCount(0),
        () => AppStrings.failedOrdersCount(0),
      );
      eq(
        'AppStrings.failedOrdersCount[\'1\']',
        () => LegacyAppStrings.failedOrdersCount(1),
        () => AppStrings.failedOrdersCount(1),
      );
      eq(
        'AppStrings.failedOrdersCount[\'2\']',
        () => LegacyAppStrings.failedOrdersCount(2),
        () => AppStrings.failedOrdersCount(2),
      );
      eq(
        'AppStrings.failedOrdersCount[\'11\']',
        () => LegacyAppStrings.failedOrdersCount(11),
        () => AppStrings.failedOrdersCount(11),
      );
      eq(
        'AppStrings.failedOrdersCount[\'100\']',
        () => LegacyAppStrings.failedOrdersCount(100),
        () => AppStrings.failedOrdersCount(100),
      );
      eq(
        'AppStrings.addFakeCustomersTooltip',
        () => LegacyAppStrings.addFakeCustomersTooltip(7),
        () => AppStrings.addFakeCustomersTooltip(7),
      );
      eq(
        'AppStrings.addFakeCustomersTooltip[\'0\']',
        () => LegacyAppStrings.addFakeCustomersTooltip(0),
        () => AppStrings.addFakeCustomersTooltip(0),
      );
      eq(
        'AppStrings.addFakeCustomersTooltip[\'1\']',
        () => LegacyAppStrings.addFakeCustomersTooltip(1),
        () => AppStrings.addFakeCustomersTooltip(1),
      );
      eq(
        'AppStrings.addFakeCustomersTooltip[\'2\']',
        () => LegacyAppStrings.addFakeCustomersTooltip(2),
        () => AppStrings.addFakeCustomersTooltip(2),
      );
      eq(
        'AppStrings.addFakeCustomersTooltip[\'11\']',
        () => LegacyAppStrings.addFakeCustomersTooltip(11),
        () => AppStrings.addFakeCustomersTooltip(11),
      );
      eq(
        'AppStrings.addFakeCustomersTooltip[\'100\']',
        () => LegacyAppStrings.addFakeCustomersTooltip(100),
        () => AppStrings.addFakeCustomersTooltip(100),
      );
      eq(
        'AppStrings.fakeCustomersAdded',
        () => LegacyAppStrings.fakeCustomersAdded(7),
        () => AppStrings.fakeCustomersAdded(7),
      );
      eq(
        'AppStrings.fakeCustomersAdded[\'0\']',
        () => LegacyAppStrings.fakeCustomersAdded(0),
        () => AppStrings.fakeCustomersAdded(0),
      );
      eq(
        'AppStrings.fakeCustomersAdded[\'1\']',
        () => LegacyAppStrings.fakeCustomersAdded(1),
        () => AppStrings.fakeCustomersAdded(1),
      );
      eq(
        'AppStrings.fakeCustomersAdded[\'2\']',
        () => LegacyAppStrings.fakeCustomersAdded(2),
        () => AppStrings.fakeCustomersAdded(2),
      );
      eq(
        'AppStrings.fakeCustomersAdded[\'11\']',
        () => LegacyAppStrings.fakeCustomersAdded(11),
        () => AppStrings.fakeCustomersAdded(11),
      );
      eq(
        'AppStrings.fakeCustomersAdded[\'100\']',
        () => LegacyAppStrings.fakeCustomersAdded(100),
        () => AppStrings.fakeCustomersAdded(100),
      );
      eq(
        'EssStrings.section',
        () => LegacyEssStrings.section,
        () => EssStrings.section,
      );
      eq(
        'EssStrings.intro',
        () => LegacyEssStrings.intro,
        () => EssStrings.intro,
      );
      eq(
        'EssStrings.profile',
        () => LegacyEssStrings.profile,
        () => EssStrings.profile,
      );
      eq(
        'EssStrings.profileDesc',
        () => LegacyEssStrings.profileDesc,
        () => EssStrings.profileDesc,
      );
      eq(
        'EssStrings.checkin',
        () => LegacyEssStrings.checkin,
        () => EssStrings.checkin,
      );
      eq(
        'EssStrings.checkinDesc',
        () => LegacyEssStrings.checkinDesc,
        () => EssStrings.checkinDesc,
      );
      eq(
        'EssStrings.attendance',
        () => LegacyEssStrings.attendance,
        () => EssStrings.attendance,
      );
      eq(
        'EssStrings.attendanceDesc',
        () => LegacyEssStrings.attendanceDesc,
        () => EssStrings.attendanceDesc,
      );
      eq(
        'EssStrings.correction',
        () => LegacyEssStrings.correction,
        () => EssStrings.correction,
      );
      eq(
        'EssStrings.correctionDesc',
        () => LegacyEssStrings.correctionDesc,
        () => EssStrings.correctionDesc,
      );
      eq(
        'EssStrings.leaves',
        () => LegacyEssStrings.leaves,
        () => EssStrings.leaves,
      );
      eq(
        'EssStrings.leavesDesc',
        () => LegacyEssStrings.leavesDesc,
        () => EssStrings.leavesDesc,
      );
      eq(
        'EssStrings.overtime',
        () => LegacyEssStrings.overtime,
        () => EssStrings.overtime,
      );
      eq(
        'EssStrings.overtimeDesc',
        () => LegacyEssStrings.overtimeDesc,
        () => EssStrings.overtimeDesc,
      );
      eq(
        'EssStrings.loadingProfile',
        () => LegacyEssStrings.loadingProfile,
        () => EssStrings.loadingProfile,
      );
      eq(
        'EssStrings.profileLoadFailed',
        () => LegacyEssStrings.profileLoadFailed,
        () => EssStrings.profileLoadFailed,
      );
      eq(
        'EssStrings.notLinked',
        () => LegacyEssStrings.notLinked,
        () => EssStrings.notLinked,
      );
      eq(
        'EssStrings.noPermission',
        () => LegacyEssStrings.noPermission,
        () => EssStrings.noPermission,
      );
      eq(
        'EssStrings.employeeId',
        () => LegacyEssStrings.employeeId,
        () => EssStrings.employeeId,
      );
      eq(
        'EssStrings.department',
        () => LegacyEssStrings.department,
        () => EssStrings.department,
      );
      eq(
        'EssStrings.designation',
        () => LegacyEssStrings.designation,
        () => EssStrings.designation,
      );
      eq(
        'EssStrings.email',
        () => LegacyEssStrings.email,
        () => EssStrings.email,
      );
      eq(
        'EssStrings.phone',
        () => LegacyEssStrings.phone,
        () => EssStrings.phone,
      );
      eq(
        'EssStrings.jobInfo',
        () => LegacyEssStrings.jobInfo,
        () => EssStrings.jobInfo,
      );
      eq(
        'EssStrings.contactInfo',
        () => LegacyEssStrings.contactInfo,
        () => EssStrings.contactInfo,
      );
      eq(
        'EssStrings.shiftInfo',
        () => LegacyEssStrings.shiftInfo,
        () => EssStrings.shiftInfo,
      );
      eq(
        'EssStrings.shiftName',
        () => LegacyEssStrings.shiftName,
        () => EssStrings.shiftName,
      );
      eq(
        'EssStrings.shiftStart',
        () => LegacyEssStrings.shiftStart,
        () => EssStrings.shiftStart,
      );
      eq(
        'EssStrings.shiftEnd',
        () => LegacyEssStrings.shiftEnd,
        () => EssStrings.shiftEnd,
      );
      eq(
        'EssStrings.noShift',
        () => LegacyEssStrings.noShift,
        () => EssStrings.noShift,
      );
      eq(
        'EssStrings.notSet',
        () => LegacyEssStrings.notSet,
        () => EssStrings.notSet,
      );
      eq(
        'EssStrings.statusNotCheckedIn',
        () => LegacyEssStrings.statusNotCheckedIn,
        () => EssStrings.statusNotCheckedIn,
      );
      eq(
        'EssStrings.statusOnDuty',
        () => LegacyEssStrings.statusOnDuty,
        () => EssStrings.statusOnDuty,
      );
      eq(
        'EssStrings.statusFinished',
        () => LegacyEssStrings.statusFinished,
        () => EssStrings.statusFinished,
      );
      eq(
        'EssStrings.checkIn',
        () => LegacyEssStrings.checkIn,
        () => EssStrings.checkIn,
      );
      eq(
        'EssStrings.checkOut',
        () => LegacyEssStrings.checkOut,
        () => EssStrings.checkOut,
      );
      eq(
        'EssStrings.inLabel',
        () => LegacyEssStrings.inLabel,
        () => EssStrings.inLabel,
      );
      eq(
        'EssStrings.outLabel',
        () => LegacyEssStrings.outLabel,
        () => EssStrings.outLabel,
      );
      eq(
        'EssStrings.checkInTime',
        () => LegacyEssStrings.checkInTime,
        () => EssStrings.checkInTime,
      );
      eq(
        'EssStrings.checkOutTime',
        () => LegacyEssStrings.checkOutTime,
        () => EssStrings.checkOutTime,
      );
      eq(
        'EssStrings.workedTime',
        () => LegacyEssStrings.workedTime,
        () => EssStrings.workedTime,
      );
      eq(
        'EssStrings.checkedIn',
        () => LegacyEssStrings.checkedIn,
        () => EssStrings.checkedIn,
      );
      eq(
        'EssStrings.checkedOut',
        () => LegacyEssStrings.checkedOut,
        () => EssStrings.checkedOut,
      );
      eq(
        'EssStrings.location',
        () => LegacyEssStrings.location,
        () => EssStrings.location,
      );
      eq(
        'EssStrings.locationPlaceholder',
        () => LegacyEssStrings.locationPlaceholder,
        () => EssStrings.locationPlaceholder,
      );
      eq(
        'EssStrings.locationNote',
        () => LegacyEssStrings.locationNote,
        () => EssStrings.locationNote,
      );
      eq(
        'EssStrings.loadingAttendance',
        () => LegacyEssStrings.loadingAttendance,
        () => EssStrings.loadingAttendance,
      );
      eq(
        'EssStrings.attendanceLoadFailed',
        () => LegacyEssStrings.attendanceLoadFailed,
        () => EssStrings.attendanceLoadFailed,
      );
      eq(
        'EssStrings.month',
        () => LegacyEssStrings.month,
        () => EssStrings.month,
      );
      eq('EssStrings.year', () => LegacyEssStrings.year, () => EssStrings.year);
      eq(
        'EssStrings.presentDays',
        () => LegacyEssStrings.presentDays,
        () => EssStrings.presentDays,
      );
      eq(
        'EssStrings.absentDays',
        () => LegacyEssStrings.absentDays,
        () => EssStrings.absentDays,
      );
      eq(
        'EssStrings.lateDays',
        () => LegacyEssStrings.lateDays,
        () => EssStrings.lateDays,
      );
      eq(
        'EssStrings.workHours',
        () => LegacyEssStrings.workHours,
        () => EssStrings.workHours,
      );
      eq(
        'EssStrings.noAttendance',
        () => LegacyEssStrings.noAttendance,
        () => EssStrings.noAttendance,
      );
      eq(
        'EssStrings.noAttendanceHint',
        () => LegacyEssStrings.noAttendanceHint,
        () => EssStrings.noAttendanceHint,
      );
      eq(
        'EssStrings.statusPresent',
        () => LegacyEssStrings.statusPresent,
        () => EssStrings.statusPresent,
      );
      eq(
        'EssStrings.statusAbsent',
        () => LegacyEssStrings.statusAbsent,
        () => EssStrings.statusAbsent,
      );
      eq(
        'EssStrings.statusHalfDay',
        () => LegacyEssStrings.statusHalfDay,
        () => EssStrings.statusHalfDay,
      );
      eq(
        'EssStrings.statusOnLeave',
        () => LegacyEssStrings.statusOnLeave,
        () => EssStrings.statusOnLeave,
      );
      eq(
        'EssStrings.inTime',
        () => LegacyEssStrings.inTime,
        () => EssStrings.inTime,
      );
      eq(
        'EssStrings.outTime',
        () => LegacyEssStrings.outTime,
        () => EssStrings.outTime,
      );
      eq(
        'EssStrings.hours',
        () => LegacyEssStrings.hours,
        () => EssStrings.hours,
      );
      eq(
        'EssStrings.newRequest',
        () => LegacyEssStrings.newRequest,
        () => EssStrings.newRequest,
      );
      eq(
        'EssStrings.requestDate',
        () => LegacyEssStrings.requestDate,
        () => EssStrings.requestDate,
      );
      eq(
        'EssStrings.correctionType',
        () => LegacyEssStrings.correctionType,
        () => EssStrings.correctionType,
      );
      eq(
        'EssStrings.forgotCheckIn',
        () => LegacyEssStrings.forgotCheckIn,
        () => EssStrings.forgotCheckIn,
      );
      eq(
        'EssStrings.forgotCheckOut',
        () => LegacyEssStrings.forgotCheckOut,
        () => EssStrings.forgotCheckOut,
      );
      eq(
        'EssStrings.correctInTime',
        () => LegacyEssStrings.correctInTime,
        () => EssStrings.correctInTime,
      );
      eq(
        'EssStrings.correctOutTime',
        () => LegacyEssStrings.correctOutTime,
        () => EssStrings.correctOutTime,
      );
      eq(
        'EssStrings.reason',
        () => LegacyEssStrings.reason,
        () => EssStrings.reason,
      );
      eq(
        'EssStrings.extraNotes',
        () => LegacyEssStrings.extraNotes,
        () => EssStrings.extraNotes,
      );
      eq(
        'EssStrings.submitRequest',
        () => LegacyEssStrings.submitRequest,
        () => EssStrings.submitRequest,
      );
      eq(
        'EssStrings.requiredField',
        () => LegacyEssStrings.requiredField,
        () => EssStrings.requiredField,
      );
      eq(
        'EssStrings.chooseDate',
        () => LegacyEssStrings.chooseDate,
        () => EssStrings.chooseDate,
      );
      eq(
        'EssStrings.chooseTime',
        () => LegacyEssStrings.chooseTime,
        () => EssStrings.chooseTime,
      );
      eq(
        'EssStrings.reasonTooShort',
        () => LegacyEssStrings.reasonTooShort,
        () => EssStrings.reasonTooShort,
      );
      eq(
        'EssStrings.requestSent',
        () => LegacyEssStrings.requestSent,
        () => EssStrings.requestSent,
      );
      eq(
        'EssStrings.previousRequests',
        () => LegacyEssStrings.previousRequests,
        () => EssStrings.previousRequests,
      );
      eq(
        'EssStrings.noRequests',
        () => LegacyEssStrings.noRequests,
        () => EssStrings.noRequests,
      );
      eq(
        'EssStrings.statusPending',
        () => LegacyEssStrings.statusPending,
        () => EssStrings.statusPending,
      );
      eq(
        'EssStrings.statusApproved',
        () => LegacyEssStrings.statusApproved,
        () => EssStrings.statusApproved,
      );
      eq(
        'EssStrings.statusRejected',
        () => LegacyEssStrings.statusRejected,
        () => EssStrings.statusRejected,
      );
      eq(
        'EssStrings.loadingLeaves',
        () => LegacyEssStrings.loadingLeaves,
        () => EssStrings.loadingLeaves,
      );
      eq(
        'EssStrings.leavesLoadFailed',
        () => LegacyEssStrings.leavesLoadFailed,
        () => EssStrings.leavesLoadFailed,
      );
      eq(
        'EssStrings.balances',
        () => LegacyEssStrings.balances,
        () => EssStrings.balances,
      );
      eq(
        'EssStrings.noBalances',
        () => LegacyEssStrings.noBalances,
        () => EssStrings.noBalances,
      );
      eq(
        'EssStrings.remaining',
        () => LegacyEssStrings.remaining,
        () => EssStrings.remaining,
      );
      eq(
        'EssStrings.withoutPay',
        () => LegacyEssStrings.withoutPay,
        () => EssStrings.withoutPay,
      );
      eq(
        'EssStrings.noBalanceLimit',
        () => LegacyEssStrings.noBalanceLimit,
        () => EssStrings.noBalanceLimit,
      );
      eq(
        'EssStrings.newLeave',
        () => LegacyEssStrings.newLeave,
        () => EssStrings.newLeave,
      );
      eq(
        'EssStrings.leaveType',
        () => LegacyEssStrings.leaveType,
        () => EssStrings.leaveType,
      );
      eq(
        'EssStrings.chooseLeaveType',
        () => LegacyEssStrings.chooseLeaveType,
        () => EssStrings.chooseLeaveType,
      );
      eq(
        'EssStrings.fromDate',
        () => LegacyEssStrings.fromDate,
        () => EssStrings.fromDate,
      );
      eq(
        'EssStrings.toDate',
        () => LegacyEssStrings.toDate,
        () => EssStrings.toDate,
      );
      eq(
        'EssStrings.daysCount',
        () => LegacyEssStrings.daysCount,
        () => EssStrings.daysCount,
      );
      eq(
        'EssStrings.daysByErp',
        () => LegacyEssStrings.daysByErp,
        () => EssStrings.daysByErp,
      );
      eq(
        'EssStrings.leaveReason',
        () => LegacyEssStrings.leaveReason,
        () => EssStrings.leaveReason,
      );
      eq(
        'EssStrings.endBeforeStart',
        () => LegacyEssStrings.endBeforeStart,
        () => EssStrings.endBeforeStart,
      );
      eq(
        'EssStrings.salaryWarning',
        () => LegacyEssStrings.salaryWarning,
        () => EssStrings.salaryWarning,
      );
      eq(
        'EssStrings.salaryWarningLwp',
        () => LegacyEssStrings.salaryWarningLwp,
        () => EssStrings.salaryWarningLwp,
      );
      eq(
        'EssStrings.leaveSent',
        () => LegacyEssStrings.leaveSent,
        () => EssStrings.leaveSent,
      );
      eq(
        'EssStrings.leaveSendFailed',
        () => LegacyEssStrings.leaveSendFailed,
        () => EssStrings.leaveSendFailed,
      );
      eq(
        'EssStrings.leaveHistory',
        () => LegacyEssStrings.leaveHistory,
        () => EssStrings.leaveHistory,
      );
      eq(
        'EssStrings.noLeaveRequests',
        () => LegacyEssStrings.noLeaveRequests,
        () => EssStrings.noLeaveRequests,
      );
      eq(
        'EssStrings.loadingOvertime',
        () => LegacyEssStrings.loadingOvertime,
        () => EssStrings.loadingOvertime,
      );
      eq(
        'EssStrings.overtimeDays',
        () => LegacyEssStrings.overtimeDays,
        () => EssStrings.overtimeDays,
      );
      eq(
        'EssStrings.overtimeAmount',
        () => LegacyEssStrings.overtimeAmount,
        () => EssStrings.overtimeAmount,
      );
      eq(
        'EssStrings.overtimeLog',
        () => LegacyEssStrings.overtimeLog,
        () => EssStrings.overtimeLog,
      );
      eq(
        'EssStrings.otApproved',
        () => LegacyEssStrings.otApproved,
        () => EssStrings.otApproved,
      );
      eq(
        'EssStrings.punchNote',
        () => LegacyEssStrings.punchNote,
        () => EssStrings.punchNote,
      );
      eq(
        'EssStrings.loadingPunches',
        () => LegacyEssStrings.loadingPunches,
        () => EssStrings.loadingPunches,
      );
      eq(
        'EssStrings.punchesLoadFailed',
        () => LegacyEssStrings.punchesLoadFailed,
        () => EssStrings.punchesLoadFailed,
      );
      eq(
        'EssStrings.punchFailed',
        () => LegacyEssStrings.punchFailed,
        () => EssStrings.punchFailed,
      );
      eq(
        'EssStrings.todayPunches',
        () => LegacyEssStrings.todayPunches,
        () => EssStrings.todayPunches,
      );
      eq(
        'EssStrings.noPunchesToday',
        () => LegacyEssStrings.noPunchesToday,
        () => EssStrings.noPunchesToday,
      );
      eq(
        'EssStrings.requestKind',
        () => LegacyEssStrings.requestKind,
        () => EssStrings.requestKind,
      );
      eq(
        'EssStrings.onDuty',
        () => LegacyEssStrings.onDuty,
        () => EssStrings.onDuty,
      );
      eq(
        'EssStrings.workFromHome',
        () => LegacyEssStrings.workFromHome,
        () => EssStrings.workFromHome,
      );
      eq(
        'EssStrings.loadingRequests',
        () => LegacyEssStrings.loadingRequests,
        () => EssStrings.loadingRequests,
      );
      eq(
        'EssStrings.requestsLoadFailed',
        () => LegacyEssStrings.requestsLoadFailed,
        () => EssStrings.requestsLoadFailed,
      );
      eq(
        'EssStrings.requestSendFailed',
        () => LegacyEssStrings.requestSendFailed,
        () => EssStrings.requestSendFailed,
      );
      eq(
        'EssStrings.pendingSameDay',
        () => LegacyEssStrings.pendingSameDay,
        () => EssStrings.pendingSameDay,
      );
      eq(
        'EssStrings.requestApprovalNote',
        () => LegacyEssStrings.requestApprovalNote,
        () => EssStrings.requestApprovalNote,
      );
      eq(
        'EssStrings.insufficientBalance',
        () => LegacyEssStrings.insufficientBalance,
        () => EssStrings.insufficientBalance,
      );
      eq(
        'EssStrings.leaveOverlap',
        () => LegacyEssStrings.leaveOverlap,
        () => EssStrings.leaveOverlap,
      );
      eq(
        'EssStrings.noAllocation',
        () => LegacyEssStrings.noAllocation,
        () => EssStrings.noAllocation,
      );
      eq(
        'EssStrings.lwpConfirmTitle',
        () => LegacyEssStrings.lwpConfirmTitle,
        () => EssStrings.lwpConfirmTitle,
      );
      eq(
        'EssStrings.sendAnyway',
        () => LegacyEssStrings.sendAnyway,
        () => EssStrings.sendAnyway,
      );
      eq(
        'EssStrings.statusCancelled',
        () => LegacyEssStrings.statusCancelled,
        () => EssStrings.statusCancelled,
      );
      eq(
        'EssStrings.statusWorkFromHome',
        () => LegacyEssStrings.statusWorkFromHome,
        () => EssStrings.statusWorkFromHome,
      );
      eq(
        'EssStrings.overtimeEntries',
        () => LegacyEssStrings.overtimeEntries,
        () => EssStrings.overtimeEntries,
      );
      eq(
        'EssStrings.overtimeAmountChart',
        () => LegacyEssStrings.overtimeAmountChart,
        () => EssStrings.overtimeAmountChart,
      );
      eq(
        'EssStrings.noOvertimeAmount',
        () => LegacyEssStrings.noOvertimeAmount,
        () => EssStrings.noOvertimeAmount,
      );
      eq(
        'EssStrings.noOvertimeAmountHint',
        () => LegacyEssStrings.noOvertimeAmountHint,
        () => EssStrings.noOvertimeAmountHint,
      );
      eq(
        'EssStrings.overtimeLoadFailed',
        () => LegacyEssStrings.overtimeLoadFailed,
        () => EssStrings.overtimeLoadFailed,
      );
      eq(
        'EssStrings.payrollDate',
        () => LegacyEssStrings.payrollDate,
        () => EssStrings.payrollDate,
      );
      eq(
        'EssStrings.amount',
        () => LegacyEssStrings.amount,
        () => EssStrings.amount,
      );
      eq(
        'EssStrings.advances',
        () => LegacyEssStrings.advances,
        () => EssStrings.advances,
      );
      eq(
        'EssStrings.advancesDesc',
        () => LegacyEssStrings.advancesDesc,
        () => EssStrings.advancesDesc,
      );
      eq(
        'EssStrings.loadingAdvances',
        () => LegacyEssStrings.loadingAdvances,
        () => EssStrings.loadingAdvances,
      );
      eq(
        'EssStrings.advancesLoadFailed',
        () => LegacyEssStrings.advancesLoadFailed,
        () => EssStrings.advancesLoadFailed,
      );
      eq(
        'EssStrings.requestAdvance',
        () => LegacyEssStrings.requestAdvance,
        () => EssStrings.requestAdvance,
      );
      eq(
        'EssStrings.newAdvance',
        () => LegacyEssStrings.newAdvance,
        () => EssStrings.newAdvance,
      );
      eq(
        'EssStrings.advanceAmountLabel',
        () => LegacyEssStrings.advanceAmountLabel,
        () => EssStrings.advanceAmountLabel,
      );
      eq(
        'EssStrings.advancePurpose',
        () => LegacyEssStrings.advancePurpose,
        () => EssStrings.advancePurpose,
      );
      eq(
        'EssStrings.amountInvalid',
        () => LegacyEssStrings.amountInvalid,
        () => EssStrings.amountInvalid,
      );
      eq(
        'EssStrings.advanceSent',
        () => LegacyEssStrings.advanceSent,
        () => EssStrings.advanceSent,
      );
      eq(
        'EssStrings.advanceSendFailed',
        () => LegacyEssStrings.advanceSendFailed,
        () => EssStrings.advanceSendFailed,
      );
      eq(
        'EssStrings.advanceApprovalNote',
        () => LegacyEssStrings.advanceApprovalNote,
        () => EssStrings.advanceApprovalNote,
      );
      eq(
        'EssStrings.noAdvances',
        () => LegacyEssStrings.noAdvances,
        () => EssStrings.noAdvances,
      );
      eq(
        'EssStrings.noAdvancesHint',
        () => LegacyEssStrings.noAdvancesHint,
        () => EssStrings.noAdvancesHint,
      );
      eq(
        'EssStrings.originalAmount',
        () => LegacyEssStrings.originalAmount,
        () => EssStrings.originalAmount,
      );
      eq(
        'EssStrings.paidAmount',
        () => LegacyEssStrings.paidAmount,
        () => EssStrings.paidAmount,
      );
      eq(
        'EssStrings.claimedAmount',
        () => LegacyEssStrings.claimedAmount,
        () => EssStrings.claimedAmount,
      );
      eq(
        'EssStrings.returnedAmount',
        () => LegacyEssStrings.returnedAmount,
        () => EssStrings.returnedAmount,
      );
      eq(
        'EssStrings.remainingAmount',
        () => LegacyEssStrings.remainingAmount,
        () => EssStrings.remainingAmount,
      );
      eq(
        'EssStrings.pendingAmount',
        () => LegacyEssStrings.pendingAmount,
        () => EssStrings.pendingAmount,
      );
      eq(
        'EssStrings.advStatusPending',
        () => LegacyEssStrings.advStatusPending,
        () => EssStrings.advStatusPending,
      );
      eq(
        'EssStrings.advStatusUnpaid',
        () => LegacyEssStrings.advStatusUnpaid,
        () => EssStrings.advStatusUnpaid,
      );
      eq(
        'EssStrings.advStatusPaid',
        () => LegacyEssStrings.advStatusPaid,
        () => EssStrings.advStatusPaid,
      );
      eq(
        'EssStrings.advStatusClaimed',
        () => LegacyEssStrings.advStatusClaimed,
        () => EssStrings.advStatusClaimed,
      );
      eq(
        'EssStrings.advStatusReturned',
        () => LegacyEssStrings.advStatusReturned,
        () => EssStrings.advStatusReturned,
      );
      eq(
        'EssStrings.advStatusPartly',
        () => LegacyEssStrings.advStatusPartly,
        () => EssStrings.advStatusPartly,
      );
      eq(
        'EssStrings.advStatusCancelled',
        () => LegacyEssStrings.advStatusCancelled,
        () => EssStrings.advStatusCancelled,
      );
      eq(
        'EssStrings.advancesTotal',
        () => LegacyEssStrings.advancesTotal,
        () => EssStrings.advancesTotal,
      );
      eq(
        'EssStrings.expenses',
        () => LegacyEssStrings.expenses,
        () => EssStrings.expenses,
      );
      eq(
        'EssStrings.expensesDesc',
        () => LegacyEssStrings.expensesDesc,
        () => EssStrings.expensesDesc,
      );
      eq(
        'EssStrings.loadingExpenses',
        () => LegacyEssStrings.loadingExpenses,
        () => EssStrings.loadingExpenses,
      );
      eq(
        'EssStrings.expensesLoadFailed',
        () => LegacyEssStrings.expensesLoadFailed,
        () => EssStrings.expensesLoadFailed,
      );
      eq(
        'EssStrings.addExpense',
        () => LegacyEssStrings.addExpense,
        () => EssStrings.addExpense,
      );
      eq(
        'EssStrings.newExpense',
        () => LegacyEssStrings.newExpense,
        () => EssStrings.newExpense,
      );
      eq(
        'EssStrings.expenseType',
        () => LegacyEssStrings.expenseType,
        () => EssStrings.expenseType,
      );
      eq(
        'EssStrings.transport',
        () => LegacyEssStrings.transport,
        () => EssStrings.transport,
      );
      eq(
        'EssStrings.meals',
        () => LegacyEssStrings.meals,
        () => EssStrings.meals,
      );
      eq(
        'EssStrings.typeMissing',
        () => LegacyEssStrings.typeMissing,
        () => EssStrings.typeMissing,
      );
      eq(
        'EssStrings.expenseAmount',
        () => LegacyEssStrings.expenseAmount,
        () => EssStrings.expenseAmount,
      );
      eq(
        'EssStrings.expenseDate',
        () => LegacyEssStrings.expenseDate,
        () => EssStrings.expenseDate,
      );
      eq(
        'EssStrings.expenseNotes',
        () => LegacyEssStrings.expenseNotes,
        () => EssStrings.expenseNotes,
      );
      eq(
        'EssStrings.receipt',
        () => LegacyEssStrings.receipt,
        () => EssStrings.receipt,
      );
      eq(
        'EssStrings.takePhoto',
        () => LegacyEssStrings.takePhoto,
        () => EssStrings.takePhoto,
      );
      eq(
        'EssStrings.fromGallery',
        () => LegacyEssStrings.fromGallery,
        () => EssStrings.fromGallery,
      );
      eq(
        'EssStrings.removePhoto',
        () => LegacyEssStrings.removePhoto,
        () => EssStrings.removePhoto,
      );
      eq(
        'EssStrings.noReceipt',
        () => LegacyEssStrings.noReceipt,
        () => EssStrings.noReceipt,
      );
      eq(
        'EssStrings.photoFailed',
        () => LegacyEssStrings.photoFailed,
        () => EssStrings.photoFailed,
      );
      eq(
        'EssStrings.linkAdvance',
        () => LegacyEssStrings.linkAdvance,
        () => EssStrings.linkAdvance,
      );
      eq(
        'EssStrings.noAdvanceLink',
        () => LegacyEssStrings.noAdvanceLink,
        () => EssStrings.noAdvanceLink,
      );
      eq(
        'EssStrings.noOpenAdvances',
        () => LegacyEssStrings.noOpenAdvances,
        () => EssStrings.noOpenAdvances,
      );
      eq(
        'EssStrings.futureDate',
        () => LegacyEssStrings.futureDate,
        () => EssStrings.futureDate,
      );
      eq(
        'EssStrings.sendExpense',
        () => LegacyEssStrings.sendExpense,
        () => EssStrings.sendExpense,
      );
      eq(
        'EssStrings.expenseSent',
        () => LegacyEssStrings.expenseSent,
        () => EssStrings.expenseSent,
      );
      eq(
        'EssStrings.expenseSendFailed',
        () => LegacyEssStrings.expenseSendFailed,
        () => EssStrings.expenseSendFailed,
      );
      eq(
        'EssStrings.expenseApprovalNote',
        () => LegacyEssStrings.expenseApprovalNote,
        () => EssStrings.expenseApprovalNote,
      );
      eq(
        'EssStrings.noExpenses',
        () => LegacyEssStrings.noExpenses,
        () => EssStrings.noExpenses,
      );
      eq(
        'EssStrings.noExpensesHint',
        () => LegacyEssStrings.noExpensesHint,
        () => EssStrings.noExpensesHint,
      );
      eq(
        'EssStrings.expenseStatusDraft',
        () => LegacyEssStrings.expenseStatusDraft,
        () => EssStrings.expenseStatusDraft,
      );
      eq(
        'EssStrings.expenseStatusApproved',
        () => LegacyEssStrings.expenseStatusApproved,
        () => EssStrings.expenseStatusApproved,
      );
      eq(
        'EssStrings.expenseStatusSubmitted',
        () => LegacyEssStrings.expenseStatusSubmitted,
        () => EssStrings.expenseStatusSubmitted,
      );
      eq(
        'EssStrings.expenseStatusPaid',
        () => LegacyEssStrings.expenseStatusPaid,
        () => EssStrings.expenseStatusPaid,
      );
      eq(
        'EssStrings.expenseStatusRejected',
        () => LegacyEssStrings.expenseStatusRejected,
        () => EssStrings.expenseStatusRejected,
      );
      eq(
        'EssStrings.expenseStatusCancelled',
        () => LegacyEssStrings.expenseStatusCancelled,
        () => EssStrings.expenseStatusCancelled,
      );
      eq(
        'EssStrings.payslips',
        () => LegacyEssStrings.payslips,
        () => EssStrings.payslips,
      );
      eq(
        'EssStrings.payslipsDesc',
        () => LegacyEssStrings.payslipsDesc,
        () => EssStrings.payslipsDesc,
      );
      eq(
        'EssStrings.loadingPayslips',
        () => LegacyEssStrings.loadingPayslips,
        () => EssStrings.loadingPayslips,
      );
      eq(
        'EssStrings.payslipsLoadFailed',
        () => LegacyEssStrings.payslipsLoadFailed,
        () => EssStrings.payslipsLoadFailed,
      );
      eq(
        'EssStrings.loadingPayslip',
        () => LegacyEssStrings.loadingPayslip,
        () => EssStrings.loadingPayslip,
      );
      eq(
        'EssStrings.payslipLoadFailed',
        () => LegacyEssStrings.payslipLoadFailed,
        () => EssStrings.payslipLoadFailed,
      );
      eq(
        'EssStrings.noPayslips',
        () => LegacyEssStrings.noPayslips,
        () => EssStrings.noPayslips,
      );
      eq(
        'EssStrings.noPayslipsHint',
        () => LegacyEssStrings.noPayslipsHint,
        () => EssStrings.noPayslipsHint,
      );
      eq(
        'EssStrings.readOnlyNote',
        () => LegacyEssStrings.readOnlyNote,
        () => EssStrings.readOnlyNote,
      );
      eq(
        'EssStrings.netPay',
        () => LegacyEssStrings.netPay,
        () => EssStrings.netPay,
      );
      eq(
        'EssStrings.grossPay',
        () => LegacyEssStrings.grossPay,
        () => EssStrings.grossPay,
      );
      eq(
        'EssStrings.earnings',
        () => LegacyEssStrings.earnings,
        () => EssStrings.earnings,
      );
      eq(
        'EssStrings.totalEarnings',
        () => LegacyEssStrings.totalEarnings,
        () => EssStrings.totalEarnings,
      );
      eq(
        'EssStrings.deductions',
        () => LegacyEssStrings.deductions,
        () => EssStrings.deductions,
      );
      eq(
        'EssStrings.totalDeductions',
        () => LegacyEssStrings.totalDeductions,
        () => EssStrings.totalDeductions,
      );
      eq(
        'EssStrings.noDeductions',
        () => LegacyEssStrings.noDeductions,
        () => EssStrings.noDeductions,
      );
      eq(
        'EssStrings.salarySummary',
        () => LegacyEssStrings.salarySummary,
        () => EssStrings.salarySummary,
      );
      eq(
        'EssStrings.paymentDays',
        () => LegacyEssStrings.paymentDays,
        () => EssStrings.paymentDays,
      );
      eq(
        'EssStrings.salaryPeriod',
        () => LegacyEssStrings.salaryPeriod,
        () => EssStrings.salaryPeriod,
      );
      eq(
        'EssStrings.slipDate',
        () => LegacyEssStrings.slipDate,
        () => EssStrings.slipDate,
      );
      eq(
        'EssStrings.basicSalary',
        () => LegacyEssStrings.basicSalary,
        () => EssStrings.basicSalary,
      );
      eq(
        'EssStrings.transportAllowance',
        () => LegacyEssStrings.transportAllowance,
        () => EssStrings.transportAllowance,
      );
      eq(
        'EssStrings.overtimePay',
        () => LegacyEssStrings.overtimePay,
        () => EssStrings.overtimePay,
      );
      eq(
        'EssStrings.notOnSlip',
        () => LegacyEssStrings.notOnSlip,
        () => EssStrings.notOnSlip,
      );
      eq(
        'EssStrings.otherEarnings',
        () => LegacyEssStrings.otherEarnings,
        () => EssStrings.otherEarnings,
      );
      eq(
        'EssStrings.dedAdvance',
        () => LegacyEssStrings.dedAdvance,
        () => EssStrings.dedAdvance,
      );
      eq(
        'EssStrings.dedAdvanceWhy',
        () => LegacyEssStrings.dedAdvanceWhy,
        () => EssStrings.dedAdvanceWhy,
      );
      eq(
        'EssStrings.dedLwp',
        () => LegacyEssStrings.dedLwp,
        () => EssStrings.dedLwp,
      );
      eq(
        'EssStrings.dedAbsence',
        () => LegacyEssStrings.dedAbsence,
        () => EssStrings.dedAbsence,
      );
      eq(
        'EssStrings.dedLate',
        () => LegacyEssStrings.dedLate,
        () => EssStrings.dedLate,
      );
      eq(
        'EssStrings.dedLateWhy',
        () => LegacyEssStrings.dedLateWhy,
        () => EssStrings.dedLateWhy,
      );
      eq(
        'EssStrings.dedTax',
        () => LegacyEssStrings.dedTax,
        () => EssStrings.dedTax,
      );
      eq(
        'EssStrings.dedTaxWhy',
        () => LegacyEssStrings.dedTaxWhy,
        () => EssStrings.dedTaxWhy,
      );
      eq(
        'EssStrings.dedSocial',
        () => LegacyEssStrings.dedSocial,
        () => EssStrings.dedSocial,
      );
      eq(
        'EssStrings.dedSocialWhy',
        () => LegacyEssStrings.dedSocialWhy,
        () => EssStrings.dedSocialWhy,
      );
      eq(
        'EssStrings.dedHealth',
        () => LegacyEssStrings.dedHealth,
        () => EssStrings.dedHealth,
      );
      eq(
        'EssStrings.dedHealthWhy',
        () => LegacyEssStrings.dedHealthWhy,
        () => EssStrings.dedHealthWhy,
      );
      eq(
        'EssStrings.dedLoan',
        () => LegacyEssStrings.dedLoan,
        () => EssStrings.dedLoan,
      );
      eq(
        'EssStrings.dedLoanWhy',
        () => LegacyEssStrings.dedLoanWhy,
        () => EssStrings.dedLoanWhy,
      );
      eq(
        'EssStrings.dedPenalty',
        () => LegacyEssStrings.dedPenalty,
        () => EssStrings.dedPenalty,
      );
      eq(
        'EssStrings.dedPenaltyWhy',
        () => LegacyEssStrings.dedPenaltyWhy,
        () => EssStrings.dedPenaltyWhy,
      );
      eq(
        'EssStrings.unpaidDaysNote',
        () => LegacyEssStrings.unpaidDaysNote,
        () => EssStrings.unpaidDaysNote,
      );
      eq(
        'EssStrings.explanationNote',
        () => LegacyEssStrings.explanationNote,
        () => EssStrings.explanationNote,
      );
      eq('EssStrings.team', () => LegacyEssStrings.team, () => EssStrings.team);
      eq(
        'EssStrings.teamDesc',
        () => LegacyEssStrings.teamDesc,
        () => EssStrings.teamDesc,
      );
      eq(
        'EssStrings.loadingTeam',
        () => LegacyEssStrings.loadingTeam,
        () => EssStrings.loadingTeam,
      );
      eq(
        'EssStrings.teamLoadFailed',
        () => LegacyEssStrings.teamLoadFailed,
        () => EssStrings.teamLoadFailed,
      );
      eq(
        'EssStrings.teamNoAccess',
        () => LegacyEssStrings.teamNoAccess,
        () => EssStrings.teamNoAccess,
      );
      eq(
        'EssStrings.teamViewOnly',
        () => LegacyEssStrings.teamViewOnly,
        () => EssStrings.teamViewOnly,
      );
      eq(
        'EssStrings.noTeamLeaves',
        () => LegacyEssStrings.noTeamLeaves,
        () => EssStrings.noTeamLeaves,
      );
      eq(
        'EssStrings.noTeamExpenses',
        () => LegacyEssStrings.noTeamExpenses,
        () => EssStrings.noTeamExpenses,
      );
      eq(
        'EssStrings.notLeaveApprover',
        () => LegacyEssStrings.notLeaveApprover,
        () => EssStrings.notLeaveApprover,
      );
      eq(
        'EssStrings.notExpenseApprover',
        () => LegacyEssStrings.notExpenseApprover,
        () => EssStrings.notExpenseApprover,
      );
      eq(
        'EssStrings.leaveRequestType',
        () => LegacyEssStrings.leaveRequestType,
        () => EssStrings.leaveRequestType,
      );
      eq(
        'EssStrings.expenseRequestType',
        () => LegacyEssStrings.expenseRequestType,
        () => EssStrings.expenseRequestType,
      );
      eq(
        'EssStrings.statusAwaiting',
        () => LegacyEssStrings.statusAwaiting,
        () => EssStrings.statusAwaiting,
      );
      eq(
        'EssStrings.overtimeTotalHours',
        () => LegacyEssStrings.overtimeTotalHours,
        () => EssStrings.overtimeTotalHours,
      );
      eq(
        'EssStrings.hoursUnavailable',
        () => LegacyEssStrings.hoursUnavailable,
        () => EssStrings.hoursUnavailable,
      );
      eq(
        'EssStrings.sourceOvertimeSlip',
        () => LegacyEssStrings.sourceOvertimeSlip,
        () => EssStrings.sourceOvertimeSlip,
      );
      eq(
        'EssStrings.sourceNoOvertimeSlip',
        () => LegacyEssStrings.sourceNoOvertimeSlip,
        () => EssStrings.sourceNoOvertimeSlip,
      );
      eq(
        'EssStrings.sourceNoSlipAccess',
        () => LegacyEssStrings.sourceNoSlipAccess,
        () => EssStrings.sourceNoSlipAccess,
      );
      eq(
        'EssStrings.overtimeHoursChart',
        () => LegacyEssStrings.overtimeHoursChart,
        () => EssStrings.overtimeHoursChart,
      );
      eq(
        'EssStrings.overtimeHoursLog',
        () => LegacyEssStrings.overtimeHoursLog,
        () => EssStrings.overtimeHoursLog,
      );
      eq(
        'EssStrings.overtimeAmountsLog',
        () => LegacyEssStrings.overtimeAmountsLog,
        () => EssStrings.overtimeAmountsLog,
      );
      eq(
        'EssStrings.hoursMinutes',
        () => LegacyEssStrings.hoursMinutes(7, 7),
        () => EssStrings.hoursMinutes(7, 7),
      );
      eq(
        'EssStrings.hoursMinutes[\'0\', \'7\']',
        () => LegacyEssStrings.hoursMinutes(0, 7),
        () => EssStrings.hoursMinutes(0, 7),
      );
      eq(
        'EssStrings.hoursMinutes[\'1\', \'7\']',
        () => LegacyEssStrings.hoursMinutes(1, 7),
        () => EssStrings.hoursMinutes(1, 7),
      );
      eq(
        'EssStrings.hoursMinutes[\'2\', \'7\']',
        () => LegacyEssStrings.hoursMinutes(2, 7),
        () => EssStrings.hoursMinutes(2, 7),
      );
      eq(
        'EssStrings.hoursMinutes[\'11\', \'7\']',
        () => LegacyEssStrings.hoursMinutes(11, 7),
        () => EssStrings.hoursMinutes(11, 7),
      );
      eq(
        'EssStrings.hoursMinutes[\'100\', \'7\']',
        () => LegacyEssStrings.hoursMinutes(100, 7),
        () => EssStrings.hoursMinutes(100, 7),
      );
      eq(
        'EssStrings.hoursMinutes[\'7\', \'0\']',
        () => LegacyEssStrings.hoursMinutes(7, 0),
        () => EssStrings.hoursMinutes(7, 0),
      );
      eq(
        'EssStrings.hoursMinutes[\'7\', \'1\']',
        () => LegacyEssStrings.hoursMinutes(7, 1),
        () => EssStrings.hoursMinutes(7, 1),
      );
      eq(
        'EssStrings.hoursMinutes[\'7\', \'2\']',
        () => LegacyEssStrings.hoursMinutes(7, 2),
        () => EssStrings.hoursMinutes(7, 2),
      );
      eq(
        'EssStrings.hoursMinutes[\'7\', \'11\']',
        () => LegacyEssStrings.hoursMinutes(7, 11),
        () => EssStrings.hoursMinutes(7, 11),
      );
      eq(
        'EssStrings.hoursMinutes[\'7\', \'100\']',
        () => LegacyEssStrings.hoursMinutes(7, 100),
        () => EssStrings.hoursMinutes(7, 100),
      );
      eq(
        'EssStrings.monthName',
        () => LegacyEssStrings.monthName(7),
        () => EssStrings.monthName(7),
      );
      eq(
        'EssStrings.monthName[\'0\']',
        () => LegacyEssStrings.monthName(0),
        () => EssStrings.monthName(0),
      );
      eq(
        'EssStrings.monthName[\'1\']',
        () => LegacyEssStrings.monthName(1),
        () => EssStrings.monthName(1),
      );
      eq(
        'EssStrings.monthName[\'2\']',
        () => LegacyEssStrings.monthName(2),
        () => EssStrings.monthName(2),
      );
      eq(
        'EssStrings.monthName[\'11\']',
        () => LegacyEssStrings.monthName(11),
        () => EssStrings.monthName(11),
      );
      eq(
        'EssStrings.monthName[\'100\']',
        () => LegacyEssStrings.monthName(100),
        () => EssStrings.monthName(100),
      );
      eq(
        'EssStrings.lateBy',
        () => LegacyEssStrings.lateBy(7),
        () => EssStrings.lateBy(7),
      );
      eq(
        'EssStrings.lateBy[\'null\']',
        () => LegacyEssStrings.lateBy(null),
        () => EssStrings.lateBy(null),
      );
      eq(
        'EssStrings.lateBy[\'0\']',
        () => LegacyEssStrings.lateBy(0),
        () => EssStrings.lateBy(0),
      );
      eq(
        'EssStrings.lateBy[\'1\']',
        () => LegacyEssStrings.lateBy(1),
        () => EssStrings.lateBy(1),
      );
      eq(
        'EssStrings.lateBy[\'3\']',
        () => LegacyEssStrings.lateBy(3),
        () => EssStrings.lateBy(3),
      );
      eq(
        'EssStrings.earlyBy',
        () => LegacyEssStrings.earlyBy(7),
        () => EssStrings.earlyBy(7),
      );
      eq(
        'EssStrings.earlyBy[\'null\']',
        () => LegacyEssStrings.earlyBy(null),
        () => EssStrings.earlyBy(null),
      );
      eq(
        'EssStrings.earlyBy[\'0\']',
        () => LegacyEssStrings.earlyBy(0),
        () => EssStrings.earlyBy(0),
      );
      eq(
        'EssStrings.earlyBy[\'1\']',
        () => LegacyEssStrings.earlyBy(1),
        () => EssStrings.earlyBy(1),
      );
      eq(
        'EssStrings.earlyBy[\'3\']',
        () => LegacyEssStrings.earlyBy(3),
        () => EssStrings.earlyBy(3),
      );
      eq(
        'EssStrings.hoursValue',
        () => LegacyEssStrings.hoursValue(2.5),
        () => EssStrings.hoursValue(2.5),
      );
      eq(
        'EssStrings.hoursValue[\'0\']',
        () => LegacyEssStrings.hoursValue(0),
        () => EssStrings.hoursValue(0),
      );
      eq(
        'EssStrings.hoursValue[\'1\']',
        () => LegacyEssStrings.hoursValue(1),
        () => EssStrings.hoursValue(1),
      );
      eq(
        'EssStrings.hoursValue[\'1.5\']',
        () => LegacyEssStrings.hoursValue(1.5),
        () => EssStrings.hoursValue(1.5),
      );
      eq(
        'EssStrings.submittedOn',
        () => LegacyEssStrings.submittedOn('X1'),
        () => EssStrings.submittedOn('X1'),
      );
      eq(
        'EssStrings.balanceDetail',
        () => LegacyEssStrings.balanceDetail('X1', 'X1'),
        () => EssStrings.balanceDetail('X1', 'X1'),
      );
      eq(
        'EssStrings.pendingApproval',
        () => LegacyEssStrings.pendingApproval('X1'),
        () => EssStrings.pendingApproval('X1'),
      );
      eq(
        'EssStrings.daysValue',
        () => LegacyEssStrings.daysValue(2.5),
        () => EssStrings.daysValue(2.5),
      );
      eq(
        'EssStrings.daysValue[\'0\']',
        () => LegacyEssStrings.daysValue(0),
        () => EssStrings.daysValue(0),
      );
      eq(
        'EssStrings.daysValue[\'1\']',
        () => LegacyEssStrings.daysValue(1),
        () => EssStrings.daysValue(1),
      );
      eq(
        'EssStrings.daysValue[\'1.5\']',
        () => LegacyEssStrings.daysValue(1.5),
        () => EssStrings.daysValue(1.5),
      );
      eq(
        'EssStrings.exceedsBalance',
        () => LegacyEssStrings.exceedsBalance('X1'),
        () => EssStrings.exceedsBalance('X1'),
      );
      eq(
        'EssStrings.period',
        () => LegacyEssStrings.period('X1', 'X1'),
        () => EssStrings.period('X1', 'X1'),
      );
      eq(
        'EssStrings.chartTooltip',
        () => LegacyEssStrings.chartTooltip('X1', 'X1'),
        () => EssStrings.chartTooltip('X1', 'X1'),
      );
      eq(
        'EssStrings.lwpConfirmMessage',
        () => LegacyEssStrings.lwpConfirmMessage('X1'),
        () => EssStrings.lwpConfirmMessage('X1'),
      );
      eq(
        'EssStrings.advanceOption',
        () => LegacyEssStrings.advanceOption('X1', 'X1'),
        () => EssStrings.advanceOption('X1', 'X1'),
      );
      eq(
        'EssStrings.advanceDeduction',
        () => LegacyEssStrings.advanceDeduction('X1'),
        () => EssStrings.advanceDeduction('X1'),
      );
      eq(
        'EssStrings.expenseSentNoReceipt',
        () => LegacyEssStrings.expenseSentNoReceipt('X1'),
        () => EssStrings.expenseSentNoReceipt('X1'),
      );
      eq(
        'EssStrings.paymentDaysOf',
        () => LegacyEssStrings.paymentDaysOf('X1', 'X1'),
        () => EssStrings.paymentDaysOf('X1', 'X1'),
      );
      eq(
        'EssStrings.dedLwpWhy',
        () => LegacyEssStrings.dedLwpWhy('X1'),
        () => EssStrings.dedLwpWhy('X1'),
      );
      eq(
        'EssStrings.dedAbsenceWhy',
        () => LegacyEssStrings.dedAbsenceWhy('X1'),
        () => EssStrings.dedAbsenceWhy('X1'),
      );
      eq(
        'EssStrings.dedOtherWhy',
        () => LegacyEssStrings.dedOtherWhy('X1'),
        () => EssStrings.dedOtherWhy('X1'),
      );
      eq(
        'EssStrings.unpaidDaysWhy',
        () => LegacyEssStrings.unpaidDaysWhy('X1'),
        () => EssStrings.unpaidDaysWhy('X1'),
      );
      eq(
        'EssStrings.days',
        () => LegacyEssStrings.days(2.5),
        () => EssStrings.days(2.5),
      );
      eq(
        'EssStrings.days[\'0\']',
        () => LegacyEssStrings.days(0),
        () => EssStrings.days(0),
      );
      eq(
        'EssStrings.days[\'1\']',
        () => LegacyEssStrings.days(1),
        () => EssStrings.days(1),
      );
      eq(
        'EssStrings.days[\'1.5\']',
        () => LegacyEssStrings.days(1.5),
        () => EssStrings.days(1.5),
      );
      eq(
        'EssStrings.teamLeavesTab',
        () => LegacyEssStrings.teamLeavesTab(7),
        () => EssStrings.teamLeavesTab(7),
      );
      eq(
        'EssStrings.teamLeavesTab[\'0\']',
        () => LegacyEssStrings.teamLeavesTab(0),
        () => EssStrings.teamLeavesTab(0),
      );
      eq(
        'EssStrings.teamLeavesTab[\'1\']',
        () => LegacyEssStrings.teamLeavesTab(1),
        () => EssStrings.teamLeavesTab(1),
      );
      eq(
        'EssStrings.teamLeavesTab[\'2\']',
        () => LegacyEssStrings.teamLeavesTab(2),
        () => EssStrings.teamLeavesTab(2),
      );
      eq(
        'EssStrings.teamLeavesTab[\'11\']',
        () => LegacyEssStrings.teamLeavesTab(11),
        () => EssStrings.teamLeavesTab(11),
      );
      eq(
        'EssStrings.teamLeavesTab[\'100\']',
        () => LegacyEssStrings.teamLeavesTab(100),
        () => EssStrings.teamLeavesTab(100),
      );
      eq(
        'EssStrings.teamExpensesTab',
        () => LegacyEssStrings.teamExpensesTab(7),
        () => EssStrings.teamExpensesTab(7),
      );
      eq(
        'EssStrings.teamExpensesTab[\'0\']',
        () => LegacyEssStrings.teamExpensesTab(0),
        () => EssStrings.teamExpensesTab(0),
      );
      eq(
        'EssStrings.teamExpensesTab[\'1\']',
        () => LegacyEssStrings.teamExpensesTab(1),
        () => EssStrings.teamExpensesTab(1),
      );
      eq(
        'EssStrings.teamExpensesTab[\'2\']',
        () => LegacyEssStrings.teamExpensesTab(2),
        () => EssStrings.teamExpensesTab(2),
      );
      eq(
        'EssStrings.teamExpensesTab[\'11\']',
        () => LegacyEssStrings.teamExpensesTab(11),
        () => EssStrings.teamExpensesTab(11),
      );
      eq(
        'EssStrings.teamExpensesTab[\'100\']',
        () => LegacyEssStrings.teamExpensesTab(100),
        () => EssStrings.teamExpensesTab(100),
      );
      eq(
        'EssStrings.duration',
        () => LegacyEssStrings.duration(2.5),
        () => EssStrings.duration(2.5),
      );
      eq(
        'EssStrings.duration[\'0\']',
        () => LegacyEssStrings.duration(0),
        () => EssStrings.duration(0),
      );
      eq(
        'EssStrings.duration[\'1\']',
        () => LegacyEssStrings.duration(1),
        () => EssStrings.duration(1),
      );
      eq(
        'EssStrings.duration[\'1.5\']',
        () => LegacyEssStrings.duration(1.5),
        () => EssStrings.duration(1.5),
      );
      eq(
        'EssStrings.sourceLabel',
        () => LegacyEssStrings.sourceLabel('X1'),
        () => EssStrings.sourceLabel('X1'),
      );
      eq(
        'InventoryStrings.section',
        () => LegacyInventoryStrings.section,
        () => InventoryStrings.section,
      );
      eq(
        'InventoryStrings.barcodeLabel',
        () => LegacyInventoryStrings.barcodeLabel,
        () => InventoryStrings.barcodeLabel,
      );
      eq(
        'InventoryStrings.barcodeHint',
        () => LegacyInventoryStrings.barcodeHint,
        () => InventoryStrings.barcodeHint,
      );
      eq(
        'InventoryStrings.scanWithCamera',
        () => LegacyInventoryStrings.scanWithCamera,
        () => InventoryStrings.scanWithCamera,
      );
      eq(
        'InventoryStrings.search',
        () => LegacyInventoryStrings.search,
        () => InventoryStrings.search,
      );
      eq(
        'InventoryStrings.scannerTitle',
        () => LegacyInventoryStrings.scannerTitle,
        () => InventoryStrings.scannerTitle,
      );
      eq(
        'InventoryStrings.scannerHint',
        () => LegacyInventoryStrings.scannerHint,
        () => InventoryStrings.scannerHint,
      );
      eq(
        'InventoryStrings.torch',
        () => LegacyInventoryStrings.torch,
        () => InventoryStrings.torch,
      );
      eq(
        'InventoryStrings.switchCamera',
        () => LegacyInventoryStrings.switchCamera,
        () => InventoryStrings.switchCamera,
      );
      eq(
        'InventoryStrings.startTitle',
        () => LegacyInventoryStrings.startTitle,
        () => InventoryStrings.startTitle,
      );
      eq(
        'InventoryStrings.startMessage',
        () => LegacyInventoryStrings.startMessage,
        () => InventoryStrings.startMessage,
      );
      eq(
        'InventoryStrings.lookupFailed',
        () => LegacyInventoryStrings.lookupFailed,
        () => InventoryStrings.lookupFailed,
      );
      eq(
        'InventoryStrings.itemCode',
        () => LegacyInventoryStrings.itemCode,
        () => InventoryStrings.itemCode,
      );
      eq(
        'InventoryStrings.warehouse',
        () => LegacyInventoryStrings.warehouse,
        () => InventoryStrings.warehouse,
      );
      eq(
        'InventoryStrings.currentQty',
        () => LegacyInventoryStrings.currentQty,
        () => InventoryStrings.currentQty,
      );
      eq(
        'InventoryStrings.newQty',
        () => LegacyInventoryStrings.newQty,
        () => InventoryStrings.newQty,
      );
      eq(
        'InventoryStrings.invalidNumber',
        () => LegacyInventoryStrings.invalidNumber,
        () => InventoryStrings.invalidNumber,
      );
      eq(
        'InventoryStrings.negativeNotAllowed',
        () => LegacyInventoryStrings.negativeNotAllowed,
        () => InventoryStrings.negativeNotAllowed,
      );
      eq(
        'InventoryStrings.saveChanges',
        () => LegacyInventoryStrings.saveChanges,
        () => InventoryStrings.saveChanges,
      );
      eq(
        'InventoryStrings.nothingChanged',
        () => LegacyInventoryStrings.nothingChanged,
        () => InventoryStrings.nothingChanged,
      );
      eq(
        'InventoryStrings.savedStockApplied',
        () => LegacyInventoryStrings.savedStockApplied,
        () => InventoryStrings.savedStockApplied,
      );
      eq(
        'InventoryStrings.savedStockDraft',
        () => LegacyInventoryStrings.savedStockDraft,
        () => InventoryStrings.savedStockDraft,
      );
      eq(
        'InventoryStrings.saveFailed',
        () => LegacyInventoryStrings.saveFailed,
        () => InventoryStrings.saveFailed,
      );
      eq(
        'InventoryStrings.listEmptyTitle',
        () => LegacyInventoryStrings.listEmptyTitle,
        () => InventoryStrings.listEmptyTitle,
      );
      eq(
        'InventoryStrings.listEmptyMessage',
        () => LegacyInventoryStrings.listEmptyMessage,
        () => InventoryStrings.listEmptyMessage,
      );
      eq(
        'InventoryStrings.alreadyInList',
        () => LegacyInventoryStrings.alreadyInList,
        () => InventoryStrings.alreadyInList,
      );
      eq(
        'InventoryStrings.serialBatchBlocked',
        () => LegacyInventoryStrings.serialBatchBlocked,
        () => InventoryStrings.serialBatchBlocked,
      );
      eq(
        'InventoryStrings.countedQty',
        () => LegacyInventoryStrings.countedQty,
        () => InventoryStrings.countedQty,
      );
      eq(
        'InventoryStrings.valuationRate',
        () => LegacyInventoryStrings.valuationRate,
        () => InventoryStrings.valuationRate,
      );
      eq(
        'InventoryStrings.rateRequired',
        () => LegacyInventoryStrings.rateRequired,
        () => InventoryStrings.rateRequired,
      );
      eq(
        'InventoryStrings.remove',
        () => LegacyInventoryStrings.remove,
        () => InventoryStrings.remove,
      );
      eq(
        'InventoryStrings.clearAll',
        () => LegacyInventoryStrings.clearAll,
        () => InventoryStrings.clearAll,
      );
      eq(
        'InventoryStrings.purposeCount',
        () => LegacyInventoryStrings.purposeCount,
        () => InventoryStrings.purposeCount,
      );
      eq(
        'InventoryStrings.purposeOpening',
        () => LegacyInventoryStrings.purposeOpening,
        () => InventoryStrings.purposeOpening,
      );
      eq(
        'InventoryStrings.confirmTitle',
        () => LegacyInventoryStrings.confirmTitle,
        () => InventoryStrings.confirmTitle,
      );
      eq(
        'InventoryStrings.cancel',
        () => LegacyInventoryStrings.cancel,
        () => InventoryStrings.cancel,
      );
      eq(
        'InventoryStrings.send',
        () => LegacyInventoryStrings.send,
        () => InventoryStrings.send,
      );
      eq(
        'InventoryStrings.fixErrors',
        () => LegacyInventoryStrings.fixErrors,
        () => InventoryStrings.fixErrors,
      );
      eq(
        'InventoryStrings.notFound',
        () => LegacyInventoryStrings.notFound('X1'),
        () => InventoryStrings.notFound('X1'),
      );
      eq(
        'InventoryStrings.added',
        () => LegacyInventoryStrings.added('X1'),
        () => InventoryStrings.added('X1'),
      );
      eq(
        'InventoryStrings.approveAndSend',
        () => LegacyInventoryStrings.approveAndSend(7),
        () => InventoryStrings.approveAndSend(7),
      );
      eq(
        'InventoryStrings.approveAndSend[\'0\']',
        () => LegacyInventoryStrings.approveAndSend(0),
        () => InventoryStrings.approveAndSend(0),
      );
      eq(
        'InventoryStrings.approveAndSend[\'1\']',
        () => LegacyInventoryStrings.approveAndSend(1),
        () => InventoryStrings.approveAndSend(1),
      );
      eq(
        'InventoryStrings.approveAndSend[\'2\']',
        () => LegacyInventoryStrings.approveAndSend(2),
        () => InventoryStrings.approveAndSend(2),
      );
      eq(
        'InventoryStrings.approveAndSend[\'11\']',
        () => LegacyInventoryStrings.approveAndSend(11),
        () => InventoryStrings.approveAndSend(11),
      );
      eq(
        'InventoryStrings.approveAndSend[\'100\']',
        () => LegacyInventoryStrings.approveAndSend(100),
        () => InventoryStrings.approveAndSend(100),
      );
      eq(
        'InventoryStrings.confirmBody',
        () => LegacyInventoryStrings.confirmBody(7),
        () => InventoryStrings.confirmBody(7),
      );
      eq(
        'InventoryStrings.confirmBody[\'0\']',
        () => LegacyInventoryStrings.confirmBody(0),
        () => InventoryStrings.confirmBody(0),
      );
      eq(
        'InventoryStrings.confirmBody[\'1\']',
        () => LegacyInventoryStrings.confirmBody(1),
        () => InventoryStrings.confirmBody(1),
      );
      eq(
        'InventoryStrings.confirmBody[\'2\']',
        () => LegacyInventoryStrings.confirmBody(2),
        () => InventoryStrings.confirmBody(2),
      );
      eq(
        'InventoryStrings.confirmBody[\'11\']',
        () => LegacyInventoryStrings.confirmBody(11),
        () => InventoryStrings.confirmBody(11),
      );
      eq(
        'InventoryStrings.confirmBody[\'100\']',
        () => LegacyInventoryStrings.confirmBody(100),
        () => InventoryStrings.confirmBody(100),
      );
      eq(
        'InventoryStrings.sent',
        () => LegacyInventoryStrings.sent('X1'),
        () => InventoryStrings.sent('X1'),
      );
      eq(
        'PurchaseStrings.section',
        () => LegacyPurchaseStrings.section,
        () => PurchaseStrings.section,
      );
      eq(
        'PurchaseStrings.navOrders',
        () => LegacyPurchaseStrings.navOrders,
        () => PurchaseStrings.navOrders,
      );
      eq(
        'PurchaseStrings.navReceipts',
        () => LegacyPurchaseStrings.navReceipts,
        () => PurchaseStrings.navReceipts,
      );
      eq(
        'PurchaseStrings.navInvoices',
        () => LegacyPurchaseStrings.navInvoices,
        () => PurchaseStrings.navInvoices,
      );
      eq(
        'PurchaseStrings.tabToReceive',
        () => LegacyPurchaseStrings.tabToReceive,
        () => PurchaseStrings.tabToReceive,
      );
      eq(
        'PurchaseStrings.newOrder',
        () => LegacyPurchaseStrings.newOrder,
        () => PurchaseStrings.newOrder,
      );
      eq(
        'PurchaseStrings.orderDraftsEmptyTitle',
        () => LegacyPurchaseStrings.orderDraftsEmptyTitle,
        () => PurchaseStrings.orderDraftsEmptyTitle,
      );
      eq(
        'PurchaseStrings.orderDraftsEmptyMessage',
        () => LegacyPurchaseStrings.orderDraftsEmptyMessage,
        () => PurchaseStrings.orderDraftsEmptyMessage,
      );
      eq(
        'PurchaseStrings.toReceiveEmptyTitle',
        () => LegacyPurchaseStrings.toReceiveEmptyTitle,
        () => PurchaseStrings.toReceiveEmptyTitle,
      );
      eq(
        'PurchaseStrings.toReceiveEmptyMessage',
        () => LegacyPurchaseStrings.toReceiveEmptyMessage,
        () => PurchaseStrings.toReceiveEmptyMessage,
      );
      eq(
        'PurchaseStrings.orderToBillEmptyTitle',
        () => LegacyPurchaseStrings.orderToBillEmptyTitle,
        () => PurchaseStrings.orderToBillEmptyTitle,
      );
      eq(
        'PurchaseStrings.orderToBillEmptyMessage',
        () => LegacyPurchaseStrings.orderToBillEmptyMessage,
        () => PurchaseStrings.orderToBillEmptyMessage,
      );
      eq(
        'PurchaseStrings.orderCompletedEmptyTitle',
        () => LegacyPurchaseStrings.orderCompletedEmptyTitle,
        () => PurchaseStrings.orderCompletedEmptyTitle,
      );
      eq(
        'PurchaseStrings.orderCompletedEmptyMessage',
        () => LegacyPurchaseStrings.orderCompletedEmptyMessage,
        () => PurchaseStrings.orderCompletedEmptyMessage,
      );
      eq(
        'PurchaseStrings.approve',
        () => LegacyPurchaseStrings.approve,
        () => PurchaseStrings.approve,
      );
      eq(
        'PurchaseStrings.approveOrderTitle',
        () => LegacyPurchaseStrings.approveOrderTitle,
        () => PurchaseStrings.approveOrderTitle,
      );
      eq(
        'PurchaseStrings.approveOrderMessage',
        () => LegacyPurchaseStrings.approveOrderMessage,
        () => PurchaseStrings.approveOrderMessage,
      );
      eq(
        'PurchaseStrings.orderApproved',
        () => LegacyPurchaseStrings.orderApproved,
        () => PurchaseStrings.orderApproved,
      );
      eq(
        'PurchaseStrings.approveFailed',
        () => LegacyPurchaseStrings.approveFailed,
        () => PurchaseStrings.approveFailed,
      );
      eq(
        'PurchaseStrings.deleteOrderTitle',
        () => LegacyPurchaseStrings.deleteOrderTitle,
        () => PurchaseStrings.deleteOrderTitle,
      );
      eq(
        'PurchaseStrings.deleteOrderMessage',
        () => LegacyPurchaseStrings.deleteOrderMessage,
        () => PurchaseStrings.deleteOrderMessage,
      );
      eq(
        'PurchaseStrings.orderDeleted',
        () => LegacyPurchaseStrings.orderDeleted,
        () => PurchaseStrings.orderDeleted,
      );
      eq(
        'PurchaseStrings.deleteFailed',
        () => LegacyPurchaseStrings.deleteFailed,
        () => PurchaseStrings.deleteFailed,
      );
      eq(
        'PurchaseStrings.orderCreateFailed',
        () => LegacyPurchaseStrings.orderCreateFailed,
        () => PurchaseStrings.orderCreateFailed,
      );
      eq(
        'PurchaseStrings.receive',
        () => LegacyPurchaseStrings.receive,
        () => PurchaseStrings.receive,
      );
      eq(
        'PurchaseStrings.receiveTitle',
        () => LegacyPurchaseStrings.receiveTitle,
        () => PurchaseStrings.receiveTitle,
      );
      eq(
        'PurchaseStrings.receiveMessage',
        () => LegacyPurchaseStrings.receiveMessage,
        () => PurchaseStrings.receiveMessage,
      );
      eq(
        'PurchaseStrings.orderReceived',
        () => LegacyPurchaseStrings.orderReceived,
        () => PurchaseStrings.orderReceived,
      );
      eq(
        'PurchaseStrings.receiveFailed',
        () => LegacyPurchaseStrings.receiveFailed,
        () => PurchaseStrings.receiveFailed,
      );
      eq(
        'PurchaseStrings.receiptAwaitingApproval',
        () => LegacyPurchaseStrings.receiptAwaitingApproval,
        () => PurchaseStrings.receiptAwaitingApproval,
      );
      eq(
        'PurchaseStrings.receiptDraftStatus',
        () => LegacyPurchaseStrings.receiptDraftStatus,
        () => PurchaseStrings.receiptDraftStatus,
      );
      eq(
        'PurchaseStrings.receiptsDraftEmptyTitle',
        () => LegacyPurchaseStrings.receiptsDraftEmptyTitle,
        () => PurchaseStrings.receiptsDraftEmptyTitle,
      );
      eq(
        'PurchaseStrings.receiptsDraftEmptyMessage',
        () => LegacyPurchaseStrings.receiptsDraftEmptyMessage,
        () => PurchaseStrings.receiptsDraftEmptyMessage,
      );
      eq(
        'PurchaseStrings.receiptsToBillEmptyTitle',
        () => LegacyPurchaseStrings.receiptsToBillEmptyTitle,
        () => PurchaseStrings.receiptsToBillEmptyTitle,
      );
      eq(
        'PurchaseStrings.receiptsToBillEmptyMessage',
        () => LegacyPurchaseStrings.receiptsToBillEmptyMessage,
        () => PurchaseStrings.receiptsToBillEmptyMessage,
      );
      eq(
        'PurchaseStrings.receiptsCompletedEmptyTitle',
        () => LegacyPurchaseStrings.receiptsCompletedEmptyTitle,
        () => PurchaseStrings.receiptsCompletedEmptyTitle,
      );
      eq(
        'PurchaseStrings.receiptsCompletedEmptyMessage',
        () => LegacyPurchaseStrings.receiptsCompletedEmptyMessage,
        () => PurchaseStrings.receiptsCompletedEmptyMessage,
      );
      eq(
        'PurchaseStrings.receiptNumber',
        () => LegacyPurchaseStrings.receiptNumber,
        () => PurchaseStrings.receiptNumber,
      );
      eq(
        'PurchaseStrings.bill',
        () => LegacyPurchaseStrings.bill,
        () => PurchaseStrings.bill,
      );
      eq(
        'PurchaseStrings.billTitle',
        () => LegacyPurchaseStrings.billTitle,
        () => PurchaseStrings.billTitle,
      );
      eq(
        'PurchaseStrings.billMessage',
        () => LegacyPurchaseStrings.billMessage,
        () => PurchaseStrings.billMessage,
      );
      eq(
        'PurchaseStrings.billed',
        () => LegacyPurchaseStrings.billed,
        () => PurchaseStrings.billed,
      );
      eq(
        'PurchaseStrings.billFailed',
        () => LegacyPurchaseStrings.billFailed,
        () => PurchaseStrings.billFailed,
      );
      eq(
        'PurchaseStrings.billWaitingApproval',
        () => LegacyPurchaseStrings.billWaitingApproval,
        () => PurchaseStrings.billWaitingApproval,
      );
      eq(
        'PurchaseStrings.billNoReceipt',
        () => LegacyPurchaseStrings.billNoReceipt,
        () => PurchaseStrings.billNoReceipt,
      );
      eq(
        'PurchaseStrings.invoicesDraftEmptyTitle',
        () => LegacyPurchaseStrings.invoicesDraftEmptyTitle,
        () => PurchaseStrings.invoicesDraftEmptyTitle,
      );
      eq(
        'PurchaseStrings.invoicesDraftEmptyMessage',
        () => LegacyPurchaseStrings.invoicesDraftEmptyMessage,
        () => PurchaseStrings.invoicesDraftEmptyMessage,
      );
      eq(
        'PurchaseStrings.invoicesUnpaidEmptyTitle',
        () => LegacyPurchaseStrings.invoicesUnpaidEmptyTitle,
        () => PurchaseStrings.invoicesUnpaidEmptyTitle,
      );
      eq(
        'PurchaseStrings.invoicesUnpaidEmptyMessage',
        () => LegacyPurchaseStrings.invoicesUnpaidEmptyMessage,
        () => PurchaseStrings.invoicesUnpaidEmptyMessage,
      );
      eq(
        'PurchaseStrings.invoicesPartlyEmptyTitle',
        () => LegacyPurchaseStrings.invoicesPartlyEmptyTitle,
        () => PurchaseStrings.invoicesPartlyEmptyTitle,
      );
      eq(
        'PurchaseStrings.invoicesPartlyEmptyMessage',
        () => LegacyPurchaseStrings.invoicesPartlyEmptyMessage,
        () => PurchaseStrings.invoicesPartlyEmptyMessage,
      );
      eq(
        'PurchaseStrings.invoicesPaidEmptyTitle',
        () => LegacyPurchaseStrings.invoicesPaidEmptyTitle,
        () => PurchaseStrings.invoicesPaidEmptyTitle,
      );
      eq(
        'PurchaseStrings.invoicesPaidEmptyMessage',
        () => LegacyPurchaseStrings.invoicesPaidEmptyMessage,
        () => PurchaseStrings.invoicesPaidEmptyMessage,
      );
      eq(
        'PurchaseStrings.supplier',
        () => LegacyPurchaseStrings.supplier,
        () => PurchaseStrings.supplier,
      );
      eq(
        'PurchaseStrings.purchaseOrderNumber',
        () => LegacyPurchaseStrings.purchaseOrderNumber,
        () => PurchaseStrings.purchaseOrderNumber,
      );
      eq(
        'PurchaseStrings.itemsCount',
        () => LegacyPurchaseStrings.itemsCount,
        () => PurchaseStrings.itemsCount,
      );
      eq(
        'PurchaseStrings.invoiceWaitingApproval',
        () => LegacyPurchaseStrings.invoiceWaitingApproval,
        () => PurchaseStrings.invoiceWaitingApproval,
      );
      eq(
        'PurchaseStrings.payToSupplier',
        () => LegacyPurchaseStrings.payToSupplier,
        () => PurchaseStrings.payToSupplier,
      );
      eq(
        'PurchaseStrings.payToSupplierAction',
        () => LegacyPurchaseStrings.payToSupplierAction,
        () => PurchaseStrings.payToSupplierAction,
      );
      eq(
        'PurchaseStrings.payAmount',
        () => LegacyPurchaseStrings.payAmount,
        () => PurchaseStrings.payAmount,
      );
      eq(
        'PurchaseStrings.payMode',
        () => LegacyPurchaseStrings.payMode,
        () => PurchaseStrings.payMode,
      );
      eq(
        'PurchaseStrings.payModesFailed',
        () => LegacyPurchaseStrings.payModesFailed,
        () => PurchaseStrings.payModesFailed,
      );
      eq(
        'PurchaseStrings.payChooseMode',
        () => LegacyPurchaseStrings.payChooseMode,
        () => PurchaseStrings.payChooseMode,
      );
      eq(
        'PurchaseStrings.payZero',
        () => LegacyPurchaseStrings.payZero,
        () => PurchaseStrings.payZero,
      );
      eq(
        'PurchaseStrings.payInvalid',
        () => LegacyPurchaseStrings.payInvalid,
        () => PurchaseStrings.payInvalid,
      );
      eq(
        'PurchaseStrings.payReference',
        () => LegacyPurchaseStrings.payReference,
        () => PurchaseStrings.payReference,
      );
      eq(
        'PurchaseStrings.payReferenceDate',
        () => LegacyPurchaseStrings.payReferenceDate,
        () => PurchaseStrings.payReferenceDate,
      );
      eq(
        'PurchaseStrings.paySave',
        () => LegacyPurchaseStrings.paySave,
        () => PurchaseStrings.paySave,
      );
      eq(
        'PurchaseStrings.paymentSaved',
        () => LegacyPurchaseStrings.paymentSaved,
        () => PurchaseStrings.paymentSaved,
      );
      eq(
        'PurchaseStrings.paymentFailed',
        () => LegacyPurchaseStrings.paymentFailed,
        () => PurchaseStrings.paymentFailed,
      );
      eq(
        'PurchaseStrings.newOrderTitle',
        () => LegacyPurchaseStrings.newOrderTitle,
        () => PurchaseStrings.newOrderTitle,
      );
      eq(
        'PurchaseStrings.chooseSupplier',
        () => LegacyPurchaseStrings.chooseSupplier,
        () => PurchaseStrings.chooseSupplier,
      );
      eq(
        'PurchaseStrings.searchSupplier',
        () => LegacyPurchaseStrings.searchSupplier,
        () => PurchaseStrings.searchSupplier,
      );
      eq(
        'PurchaseStrings.searchItem',
        () => LegacyPurchaseStrings.searchItem,
        () => PurchaseStrings.searchItem,
      );
      eq(
        'PurchaseStrings.addItem',
        () => LegacyPurchaseStrings.addItem,
        () => PurchaseStrings.addItem,
      );
      eq(
        'PurchaseStrings.noResults',
        () => LegacyPurchaseStrings.noResults,
        () => PurchaseStrings.noResults,
      );
      eq(
        'PurchaseStrings.qty',
        () => LegacyPurchaseStrings.qty,
        () => PurchaseStrings.qty,
      );
      eq(
        'PurchaseStrings.unitPrice',
        () => LegacyPurchaseStrings.unitPrice,
        () => PurchaseStrings.unitPrice,
      );
      eq(
        'PurchaseStrings.requiredBy',
        () => LegacyPurchaseStrings.requiredBy,
        () => PurchaseStrings.requiredBy,
      );
      eq(
        'PurchaseStrings.itemsTitle',
        () => LegacyPurchaseStrings.itemsTitle,
        () => PurchaseStrings.itemsTitle,
      );
      eq(
        'PurchaseStrings.noItemsYet',
        () => LegacyPurchaseStrings.noItemsYet,
        () => PurchaseStrings.noItemsYet,
      );
      eq(
        'PurchaseStrings.saveDraft',
        () => LegacyPurchaseStrings.saveDraft,
        () => PurchaseStrings.saveDraft,
      );
      eq(
        'PurchaseStrings.subtotal',
        () => LegacyPurchaseStrings.subtotal,
        () => PurchaseStrings.subtotal,
      );
      eq(
        'PurchaseStrings.taxes',
        () => LegacyPurchaseStrings.taxes,
        () => PurchaseStrings.taxes,
      );
      eq(
        'PurchaseStrings.total',
        () => LegacyPurchaseStrings.total,
        () => PurchaseStrings.total,
      );
      eq(
        'PurchaseStrings.orderSaved',
        () => LegacyPurchaseStrings.orderSaved,
        () => PurchaseStrings.orderSaved,
      );
      eq(
        'PurchaseStrings.invalidLine',
        () => LegacyPurchaseStrings.invalidLine,
        () => PurchaseStrings.invalidLine,
      );
      eq(
        'PurchaseStrings.editItems',
        () => LegacyPurchaseStrings.editItems,
        () => PurchaseStrings.editItems,
      );
      eq(
        'PurchaseStrings.editItemsTitle',
        () => LegacyPurchaseStrings.editItemsTitle,
        () => PurchaseStrings.editItemsTitle,
      );
      eq(
        'PurchaseStrings.qtyLabel',
        () => LegacyPurchaseStrings.qtyLabel,
        () => PurchaseStrings.qtyLabel,
      );
      eq(
        'PurchaseStrings.warehouseLabel',
        () => LegacyPurchaseStrings.warehouseLabel,
        () => PurchaseStrings.warehouseLabel,
      );
      eq(
        'PurchaseStrings.saveItems',
        () => LegacyPurchaseStrings.saveItems,
        () => PurchaseStrings.saveItems,
      );
      eq(
        'PurchaseStrings.itemsSaved',
        () => LegacyPurchaseStrings.itemsSaved,
        () => PurchaseStrings.itemsSaved,
      );
      eq(
        'PurchaseStrings.itemsSaveFailed',
        () => LegacyPurchaseStrings.itemsSaveFailed,
        () => PurchaseStrings.itemsSaveFailed,
      );
      eq(
        'PurchaseStrings.itemsInvalid',
        () => LegacyPurchaseStrings.itemsInvalid,
        () => PurchaseStrings.itemsInvalid,
      );
      eq(
        'PurchaseStrings.totalsFromErp',
        () => LegacyPurchaseStrings.totalsFromErp,
        () => PurchaseStrings.totalsFromErp,
      );
      eq(
        'PurchaseStrings.payExceeds',
        () => LegacyPurchaseStrings.payExceeds('X1'),
        () => PurchaseStrings.payExceeds('X1'),
      );
      eq(
        'PurchaseStrings.paymentPending',
        () => LegacyPurchaseStrings.paymentPending('X1'),
        () => PurchaseStrings.paymentPending('X1'),
      );
      eq(
        'ReturnsStrings.section',
        () => LegacyReturnsStrings.section,
        () => ReturnsStrings.section,
      );
      eq(
        'ReturnsStrings.chooseCustomer',
        () => LegacyReturnsStrings.chooseCustomer,
        () => ReturnsStrings.chooseCustomer,
      );
      eq(
        'ReturnsStrings.chooseCustomerHint',
        () => LegacyReturnsStrings.chooseCustomerHint,
        () => ReturnsStrings.chooseCustomerHint,
      );
      eq(
        'ReturnsStrings.searchHint',
        () => LegacyReturnsStrings.searchHint,
        () => ReturnsStrings.searchHint,
      );
      eq(
        'ReturnsStrings.loadingCustomers',
        () => LegacyReturnsStrings.loadingCustomers,
        () => ReturnsStrings.loadingCustomers,
      );
      eq(
        'ReturnsStrings.noCustomers',
        () => LegacyReturnsStrings.noCustomers,
        () => ReturnsStrings.noCustomers,
      );
      eq(
        'ReturnsStrings.loadFailed',
        () => LegacyReturnsStrings.loadFailed,
        () => ReturnsStrings.loadFailed,
      );
      eq(
        'ReturnsStrings.chooseInvoice',
        () => LegacyReturnsStrings.chooseInvoice,
        () => ReturnsStrings.chooseInvoice,
      );
      eq(
        'ReturnsStrings.loadingInvoices',
        () => LegacyReturnsStrings.loadingInvoices,
        () => ReturnsStrings.loadingInvoices,
      );
      eq(
        'ReturnsStrings.noInvoices',
        () => LegacyReturnsStrings.noInvoices,
        () => ReturnsStrings.noInvoices,
      );
      eq(
        'ReturnsStrings.loadingItems',
        () => LegacyReturnsStrings.loadingItems,
        () => ReturnsStrings.loadingItems,
      );
      eq(
        'ReturnsStrings.noItems',
        () => LegacyReturnsStrings.noItems,
        () => ReturnsStrings.noItems,
      );
      eq(
        'ReturnsStrings.soldQty',
        () => LegacyReturnsStrings.soldQty,
        () => ReturnsStrings.soldQty,
      );
      eq(
        'ReturnsStrings.returnedQty',
        () => LegacyReturnsStrings.returnedQty,
        () => ReturnsStrings.returnedQty,
      );
      eq(
        'ReturnsStrings.returnableQty',
        () => LegacyReturnsStrings.returnableQty,
        () => ReturnsStrings.returnableQty,
      );
      eq(
        'ReturnsStrings.returnQty',
        () => LegacyReturnsStrings.returnQty,
        () => ReturnsStrings.returnQty,
      );
      eq(
        'ReturnsStrings.fullyReturned',
        () => LegacyReturnsStrings.fullyReturned,
        () => ReturnsStrings.fullyReturned,
      );
      eq(
        'ReturnsStrings.wholeNumberOnly',
        () => LegacyReturnsStrings.wholeNumberOnly,
        () => ReturnsStrings.wholeNumberOnly,
      );
      eq(
        'ReturnsStrings.reasonLabel',
        () => LegacyReturnsStrings.reasonLabel,
        () => ReturnsStrings.reasonLabel,
      );
      eq(
        'ReturnsStrings.createReturn',
        () => LegacyReturnsStrings.createReturn,
        () => ReturnsStrings.createReturn,
      );
      eq(
        'ReturnsStrings.nothingChosen',
        () => LegacyReturnsStrings.nothingChosen,
        () => ReturnsStrings.nothingChosen,
      );
      eq(
        'ReturnsStrings.fixErrors',
        () => LegacyReturnsStrings.fixErrors,
        () => ReturnsStrings.fixErrors,
      );
      eq(
        'ReturnsStrings.confirmTitle',
        () => LegacyReturnsStrings.confirmTitle,
        () => ReturnsStrings.confirmTitle,
      );
      eq(
        'ReturnsStrings.createFailed',
        () => LegacyReturnsStrings.createFailed,
        () => ReturnsStrings.createFailed,
      );
      eq(
        'ReturnsStrings.createdTitle',
        () => LegacyReturnsStrings.createdTitle,
        () => ReturnsStrings.createdTitle,
      );
      eq(
        'ReturnsStrings.ok',
        () => LegacyReturnsStrings.ok,
        () => ReturnsStrings.ok,
      );
      eq(
        'ReturnsStrings.pendingTitle',
        () => LegacyReturnsStrings.pendingTitle,
        () => ReturnsStrings.pendingTitle,
      );
      eq(
        'ReturnsStrings.creditNotes',
        () => LegacyReturnsStrings.creditNotes,
        () => ReturnsStrings.creditNotes,
      );
      eq(
        'ReturnsStrings.stockReturns',
        () => LegacyReturnsStrings.stockReturns,
        () => ReturnsStrings.stockReturns,
      );
      eq(
        'ReturnsStrings.noPending',
        () => LegacyReturnsStrings.noPending,
        () => ReturnsStrings.noPending,
      );
      eq(
        'ReturnsStrings.approve',
        () => LegacyReturnsStrings.approve,
        () => ReturnsStrings.approve,
      );
      eq(
        'ReturnsStrings.reject',
        () => LegacyReturnsStrings.reject,
        () => ReturnsStrings.reject,
      );
      eq(
        'ReturnsStrings.rejectBody',
        () => LegacyReturnsStrings.rejectBody,
        () => ReturnsStrings.rejectBody,
      );
      eq(
        'ReturnsStrings.actionFailed',
        () => LegacyReturnsStrings.actionFailed,
        () => ReturnsStrings.actionFailed,
      );
      eq(
        'ReturnsStrings.refundTitle',
        () => LegacyReturnsStrings.refundTitle,
        () => ReturnsStrings.refundTitle,
      );
      eq(
        'ReturnsStrings.paymentMode',
        () => LegacyReturnsStrings.paymentMode,
        () => ReturnsStrings.paymentMode,
      );
      eq(
        'ReturnsStrings.referenceNo',
        () => LegacyReturnsStrings.referenceNo,
        () => ReturnsStrings.referenceNo,
      );
      eq(
        'ReturnsStrings.referenceDate',
        () => LegacyReturnsStrings.referenceDate,
        () => ReturnsStrings.referenceDate,
      );
      eq(
        'ReturnsStrings.referenceRequired',
        () => LegacyReturnsStrings.referenceRequired,
        () => ReturnsStrings.referenceRequired,
      );
      eq(
        'ReturnsStrings.saveRefund',
        () => LegacyReturnsStrings.saveRefund,
        () => ReturnsStrings.saveRefund,
      );
      eq(
        'ReturnsStrings.skipRefund',
        () => LegacyReturnsStrings.skipRefund,
        () => ReturnsStrings.skipRefund,
      );
      eq(
        'ReturnsStrings.refundFailed',
        () => LegacyReturnsStrings.refundFailed,
        () => ReturnsStrings.refundFailed,
      );
      eq(
        'ReturnsStrings.refundNotPay',
        () => LegacyReturnsStrings.refundNotPay,
        () => ReturnsStrings.refundNotPay,
      );
      eq(
        'ReturnsStrings.modesFailed',
        () => LegacyReturnsStrings.modesFailed,
        () => ReturnsStrings.modesFailed,
      );
      eq(
        'ReturnsStrings.invoicesCount',
        () => LegacyReturnsStrings.invoicesCount(7),
        () => ReturnsStrings.invoicesCount(7),
      );
      eq(
        'ReturnsStrings.invoicesCount[\'0\']',
        () => LegacyReturnsStrings.invoicesCount(0),
        () => ReturnsStrings.invoicesCount(0),
      );
      eq(
        'ReturnsStrings.invoicesCount[\'1\']',
        () => LegacyReturnsStrings.invoicesCount(1),
        () => ReturnsStrings.invoicesCount(1),
      );
      eq(
        'ReturnsStrings.invoicesCount[\'2\']',
        () => LegacyReturnsStrings.invoicesCount(2),
        () => ReturnsStrings.invoicesCount(2),
      );
      eq(
        'ReturnsStrings.invoicesCount[\'11\']',
        () => LegacyReturnsStrings.invoicesCount(11),
        () => ReturnsStrings.invoicesCount(11),
      );
      eq(
        'ReturnsStrings.invoicesCount[\'100\']',
        () => LegacyReturnsStrings.invoicesCount(100),
        () => ReturnsStrings.invoicesCount(100),
      );
      eq(
        'ReturnsStrings.lastInvoice',
        () => LegacyReturnsStrings.lastInvoice('X1'),
        () => ReturnsStrings.lastInvoice('X1'),
      );
      eq(
        'ReturnsStrings.savedAt',
        () => LegacyReturnsStrings.savedAt('X1'),
        () => ReturnsStrings.savedAt('X1'),
      );
      eq(
        'ReturnsStrings.total',
        () => LegacyReturnsStrings.total('X1'),
        () => ReturnsStrings.total('X1'),
      );
      eq(
        'ReturnsStrings.outstanding',
        () => LegacyReturnsStrings.outstanding('X1'),
        () => ReturnsStrings.outstanding('X1'),
      );
      eq(
        'ReturnsStrings.maxReturnable',
        () => LegacyReturnsStrings.maxReturnable('X1'),
        () => ReturnsStrings.maxReturnable('X1'),
      );
      eq(
        'ReturnsStrings.returnTotal',
        () => LegacyReturnsStrings.returnTotal('X1'),
        () => ReturnsStrings.returnTotal('X1'),
      );
      eq(
        'ReturnsStrings.confirmBody',
        () => LegacyReturnsStrings.confirmBody(7, 'X1'),
        () => ReturnsStrings.confirmBody(7, 'X1'),
      );
      eq(
        'ReturnsStrings.confirmBody[\'0\', "\'X1\'"]',
        () => LegacyReturnsStrings.confirmBody(0, 'X1'),
        () => ReturnsStrings.confirmBody(0, 'X1'),
      );
      eq(
        'ReturnsStrings.confirmBody[\'1\', "\'X1\'"]',
        () => LegacyReturnsStrings.confirmBody(1, 'X1'),
        () => ReturnsStrings.confirmBody(1, 'X1'),
      );
      eq(
        'ReturnsStrings.confirmBody[\'2\', "\'X1\'"]',
        () => LegacyReturnsStrings.confirmBody(2, 'X1'),
        () => ReturnsStrings.confirmBody(2, 'X1'),
      );
      eq(
        'ReturnsStrings.confirmBody[\'11\', "\'X1\'"]',
        () => LegacyReturnsStrings.confirmBody(11, 'X1'),
        () => ReturnsStrings.confirmBody(11, 'X1'),
      );
      eq(
        'ReturnsStrings.confirmBody[\'100\', "\'X1\'"]',
        () => LegacyReturnsStrings.confirmBody(100, 'X1'),
        () => ReturnsStrings.confirmBody(100, 'X1'),
      );
      eq(
        'ReturnsStrings.creditNoteSaved',
        () => LegacyReturnsStrings.creditNoteSaved('X1'),
        () => ReturnsStrings.creditNoteSaved('X1'),
      );
      eq(
        'ReturnsStrings.stockReturnSaved',
        () => LegacyReturnsStrings.stockReturnSaved('X1'),
        () => ReturnsStrings.stockReturnSaved('X1'),
      );
      eq(
        'ReturnsStrings.stockReturnFailed',
        () => LegacyReturnsStrings.stockReturnFailed('X1', 'X1'),
        () => ReturnsStrings.stockReturnFailed('X1', 'X1'),
      );
      eq(
        'ReturnsStrings.against',
        () => LegacyReturnsStrings.against('X1'),
        () => ReturnsStrings.against('X1'),
      );
      eq(
        'ReturnsStrings.approveTitle',
        () => LegacyReturnsStrings.approveTitle('X1'),
        () => ReturnsStrings.approveTitle('X1'),
      );
      eq(
        'ReturnsStrings.rejectTitle',
        () => LegacyReturnsStrings.rejectTitle('X1'),
        () => ReturnsStrings.rejectTitle('X1'),
      );
      eq(
        'ReturnsStrings.approved',
        () => LegacyReturnsStrings.approved('X1'),
        () => ReturnsStrings.approved('X1'),
      );
      eq(
        'ReturnsStrings.rejected',
        () => LegacyReturnsStrings.rejected('X1'),
        () => ReturnsStrings.rejected('X1'),
      );
      eq(
        'ReturnsStrings.refundAmount',
        () => LegacyReturnsStrings.refundAmount('X1'),
        () => ReturnsStrings.refundAmount('X1'),
      );
      eq(
        'ReturnsStrings.customerStillOwes',
        () => LegacyReturnsStrings.customerStillOwes('X1'),
        () => ReturnsStrings.customerStillOwes('X1'),
      );
      eq(
        'ReturnsStrings.refundSaved',
        () => LegacyReturnsStrings.refundSaved('X1'),
        () => ReturnsStrings.refundSaved('X1'),
      );
      eq(
        'ReturnsStrings.refundNoAccount',
        () => LegacyReturnsStrings.refundNoAccount('X1'),
        () => ReturnsStrings.refundNoAccount('X1'),
      );
      eq(
        'StatementStrings.section',
        () => LegacyStatementStrings.section,
        () => StatementStrings.section,
      );
      eq(
        'StatementStrings.searchHint',
        () => LegacyStatementStrings.searchHint,
        () => StatementStrings.searchHint,
      );
      eq(
        'StatementStrings.loadingCustomers',
        () => LegacyStatementStrings.loadingCustomers,
        () => StatementStrings.loadingCustomers,
      );
      eq(
        'StatementStrings.noCustomers',
        () => LegacyStatementStrings.noCustomers,
        () => StatementStrings.noCustomers,
      );
      eq(
        'StatementStrings.loadFailed',
        () => LegacyStatementStrings.loadFailed,
        () => StatementStrings.loadFailed,
      );
      eq(
        'StatementStrings.loadingStatement',
        () => LegacyStatementStrings.loadingStatement,
        () => StatementStrings.loadingStatement,
      );
      eq(
        'StatementStrings.allPeriods',
        () => LegacyStatementStrings.allPeriods,
        () => StatementStrings.allPeriods,
      );
      eq(
        'StatementStrings.chooseRange',
        () => LegacyStatementStrings.chooseRange,
        () => StatementStrings.chooseRange,
      );
      eq(
        'StatementStrings.clearRange',
        () => LegacyStatementStrings.clearRange,
        () => StatementStrings.clearRange,
      );
      eq(
        'StatementStrings.openingBalance',
        () => LegacyStatementStrings.openingBalance,
        () => StatementStrings.openingBalance,
      );
      eq(
        'StatementStrings.totalDebit',
        () => LegacyStatementStrings.totalDebit,
        () => StatementStrings.totalDebit,
      );
      eq(
        'StatementStrings.totalCredit',
        () => LegacyStatementStrings.totalCredit,
        () => StatementStrings.totalCredit,
      );
      eq(
        'StatementStrings.closingBalance',
        () => LegacyStatementStrings.closingBalance,
        () => StatementStrings.closingBalance,
      );
      eq(
        'StatementStrings.balance',
        () => LegacyStatementStrings.balance,
        () => StatementStrings.balance,
      );
      eq(
        'StatementStrings.debit',
        () => LegacyStatementStrings.debit,
        () => StatementStrings.debit,
      );
      eq(
        'StatementStrings.credit',
        () => LegacyStatementStrings.credit,
        () => StatementStrings.credit,
      );
      eq(
        'StatementStrings.owesUs',
        () => LegacyStatementStrings.owesUs,
        () => StatementStrings.owesUs,
      );
      eq(
        'StatementStrings.inCredit',
        () => LegacyStatementStrings.inCredit,
        () => StatementStrings.inCredit,
      );
      eq(
        'StatementStrings.settled',
        () => LegacyStatementStrings.settled,
        () => StatementStrings.settled,
      );
      eq(
        'StatementStrings.noEntries',
        () => LegacyStatementStrings.noEntries,
        () => StatementStrings.noEntries,
      );
      eq(
        'StatementStrings.needsAccountsRole',
        () => LegacyStatementStrings.needsAccountsRole,
        () => StatementStrings.needsAccountsRole,
      );
      eq(
        'StatementStrings.loadingDocument',
        () => LegacyStatementStrings.loadingDocument,
        () => StatementStrings.loadingDocument,
      );
      eq(
        'StatementStrings.number',
        () => LegacyStatementStrings.number,
        () => StatementStrings.number,
      );
      eq(
        'StatementStrings.date',
        () => LegacyStatementStrings.date,
        () => StatementStrings.date,
      );
      eq(
        'StatementStrings.status',
        () => LegacyStatementStrings.status,
        () => StatementStrings.status,
      );
      eq(
        'StatementStrings.party',
        () => LegacyStatementStrings.party,
        () => StatementStrings.party,
      );
      eq(
        'StatementStrings.draft',
        () => LegacyStatementStrings.draft,
        () => StatementStrings.draft,
      );
      eq(
        'StatementStrings.submitted',
        () => LegacyStatementStrings.submitted,
        () => StatementStrings.submitted,
      );
      eq(
        'StatementStrings.cancelled',
        () => LegacyStatementStrings.cancelled,
        () => StatementStrings.cancelled,
      );
      eq(
        'StatementStrings.items',
        () => LegacyStatementStrings.items,
        () => StatementStrings.items,
      );
      eq(
        'StatementStrings.qty',
        () => LegacyStatementStrings.qty,
        () => StatementStrings.qty,
      );
      eq(
        'StatementStrings.rate',
        () => LegacyStatementStrings.rate,
        () => StatementStrings.rate,
      );
      eq(
        'StatementStrings.amount',
        () => LegacyStatementStrings.amount,
        () => StatementStrings.amount,
      );
      eq(
        'StatementStrings.invoiceTotal',
        () => LegacyStatementStrings.invoiceTotal,
        () => StatementStrings.invoiceTotal,
      );
      eq(
        'StatementStrings.outstanding',
        () => LegacyStatementStrings.outstanding,
        () => StatementStrings.outstanding,
      );
      eq(
        'StatementStrings.returnAgainst',
        () => LegacyStatementStrings.returnAgainst,
        () => StatementStrings.returnAgainst,
      );
      eq(
        'StatementStrings.creditNote',
        () => LegacyStatementStrings.creditNote,
        () => StatementStrings.creditNote,
      );
      eq(
        'StatementStrings.modeOfPayment',
        () => LegacyStatementStrings.modeOfPayment,
        () => StatementStrings.modeOfPayment,
      );
      eq(
        'StatementStrings.received',
        () => LegacyStatementStrings.received,
        () => StatementStrings.received,
      );
      eq(
        'StatementStrings.creditedToCustomer',
        () => LegacyStatementStrings.creditedToCustomer,
        () => StatementStrings.creditedToCustomer,
      );
      eq(
        'StatementStrings.paidTo',
        () => LegacyStatementStrings.paidTo,
        () => StatementStrings.paidTo,
      );
      eq(
        'StatementStrings.referenceNo',
        () => LegacyStatementStrings.referenceNo,
        () => StatementStrings.referenceNo,
      );
      eq(
        'StatementStrings.referenceDate',
        () => LegacyStatementStrings.referenceDate,
        () => StatementStrings.referenceDate,
      );
      eq(
        'StatementStrings.allocations',
        () => LegacyStatementStrings.allocations,
        () => StatementStrings.allocations,
      );
      eq(
        'StatementStrings.unallocated',
        () => LegacyStatementStrings.unallocated,
        () => StatementStrings.unallocated,
      );
      eq(
        'StatementStrings.notAllocated',
        () => LegacyStatementStrings.notAllocated,
        () => StatementStrings.notAllocated,
      );
      eq(
        'StatementStrings.remarks',
        () => LegacyStatementStrings.remarks,
        () => StatementStrings.remarks,
      );
      eq(
        'StatementStrings.accounts',
        () => LegacyStatementStrings.accounts,
        () => StatementStrings.accounts,
      );
      eq(
        'StatementStrings.account',
        () => LegacyStatementStrings.account,
        () => StatementStrings.account,
      );
      eq(
        'StatementStrings.voucherType',
        () => LegacyStatementStrings.voucherType('X1'),
        () => StatementStrings.voucherType('X1'),
      );
      eq(
        'VanStrings.section',
        () => LegacyVanStrings.section,
        () => VanStrings.section,
      );
      eq(
        'VanStrings.stockTitle',
        () => LegacyVanStrings.stockTitle,
        () => VanStrings.stockTitle,
      );
      eq(
        'VanStrings.loading',
        () => LegacyVanStrings.loading,
        () => VanStrings.loading,
      );
      eq(
        'VanStrings.loadFailed',
        () => LegacyVanStrings.loadFailed,
        () => VanStrings.loadFailed,
      );
      eq(
        'VanStrings.searchHint',
        () => LegacyVanStrings.searchHint,
        () => VanStrings.searchHint,
      );
      eq('VanStrings.scan', () => LegacyVanStrings.scan, () => VanStrings.scan);
      eq(
        'VanStrings.empty',
        () => LegacyVanStrings.empty,
        () => VanStrings.empty,
      );
      eq(
        'VanStrings.emptyHint',
        () => LegacyVanStrings.emptyHint,
        () => VanStrings.emptyHint,
      );
      eq(
        'VanStrings.noMatch',
        () => LegacyVanStrings.noMatch,
        () => VanStrings.noMatch,
      );
      eq(
        'VanStrings.available',
        () => LegacyVanStrings.available,
        () => VanStrings.available,
      );
      eq('VanStrings.code', () => LegacyVanStrings.code, () => VanStrings.code);
      eq(
        'VanStrings.scanFailed',
        () => LegacyVanStrings.scanFailed,
        () => VanStrings.scanFailed,
      );
      eq(
        'VanStrings.clearScan',
        () => LegacyVanStrings.clearScan,
        () => VanStrings.clearScan,
      );
      eq(
        'VanStrings.stockDesc',
        () => LegacyVanStrings.stockDesc,
        () => VanStrings.stockDesc,
      );
      eq(
        'VanStrings.newSale',
        () => LegacyVanStrings.newSale,
        () => VanStrings.newSale,
      );
      eq(
        'VanStrings.newSaleDesc',
        () => LegacyVanStrings.newSaleDesc,
        () => VanStrings.newSaleDesc,
      );
      eq(
        'VanStrings.customer',
        () => LegacyVanStrings.customer,
        () => VanStrings.customer,
      );
      eq(
        'VanStrings.chooseCustomer',
        () => LegacyVanStrings.chooseCustomer,
        () => VanStrings.chooseCustomer,
      );
      eq(
        'VanStrings.searchCustomer',
        () => LegacyVanStrings.searchCustomer,
        () => VanStrings.searchCustomer,
      );
      eq(
        'VanStrings.loadingCustomers',
        () => LegacyVanStrings.loadingCustomers,
        () => VanStrings.loadingCustomers,
      );
      eq(
        'VanStrings.noCustomers',
        () => LegacyVanStrings.noCustomers,
        () => VanStrings.noCustomers,
      );
      eq(
        'VanStrings.customersFailed',
        () => LegacyVanStrings.customersFailed,
        () => VanStrings.customersFailed,
      );
      eq(
        'VanStrings.products',
        () => LegacyVanStrings.products,
        () => VanStrings.products,
      );
      eq(
        'VanStrings.addProduct',
        () => LegacyVanStrings.addProduct,
        () => VanStrings.addProduct,
      );
      eq(
        'VanStrings.chooseProduct',
        () => LegacyVanStrings.chooseProduct,
        () => VanStrings.chooseProduct,
      );
      eq(
        'VanStrings.noLines',
        () => LegacyVanStrings.noLines,
        () => VanStrings.noLines,
      );
      eq('VanStrings.unit', () => LegacyVanStrings.unit, () => VanStrings.unit);
      eq(
        'VanStrings.loadingUnits',
        () => LegacyVanStrings.loadingUnits,
        () => VanStrings.loadingUnits,
      );
      eq(
        'VanStrings.unitsFailed',
        () => LegacyVanStrings.unitsFailed,
        () => VanStrings.unitsFailed,
      );
      eq(
        'VanStrings.quantity',
        () => LegacyVanStrings.quantity,
        () => VanStrings.quantity,
      );
      eq(
        'VanStrings.qtyPositive',
        () => LegacyVanStrings.qtyPositive,
        () => VanStrings.qtyPositive,
      );
      eq(
        'VanStrings.estimatedPrice',
        () => LegacyVanStrings.estimatedPrice,
        () => VanStrings.estimatedPrice,
      );
      eq(
        'VanStrings.noPrice',
        () => LegacyVanStrings.noPrice,
        () => VanStrings.noPrice,
      );
      eq('VanStrings.add', () => LegacyVanStrings.add, () => VanStrings.add);
      eq(
        'VanStrings.update',
        () => LegacyVanStrings.update,
        () => VanStrings.update,
      );
      eq(
        'VanStrings.remove',
        () => LegacyVanStrings.remove,
        () => VanStrings.remove,
      );
      eq(
        'VanStrings.cancel',
        () => LegacyVanStrings.cancel,
        () => VanStrings.cancel,
      );
      eq(
        'VanStrings.review',
        () => LegacyVanStrings.review,
        () => VanStrings.review,
      );
      eq(
        'VanStrings.reviewAndSave',
        () => LegacyVanStrings.reviewAndSave,
        () => VanStrings.reviewAndSave,
      );
      eq(
        'VanStrings.saveDraft',
        () => LegacyVanStrings.saveDraft,
        () => VanStrings.saveDraft,
      );
      eq(
        'VanStrings.estimatedTotal',
        () => LegacyVanStrings.estimatedTotal,
        () => VanStrings.estimatedTotal,
      );
      eq(
        'VanStrings.reviewNote',
        () => LegacyVanStrings.reviewNote,
        () => VanStrings.reviewNote,
      );
      eq(
        'VanStrings.warehouseLabel',
        () => LegacyVanStrings.warehouseLabel,
        () => VanStrings.warehouseLabel,
      );
      eq(
        'VanStrings.needCustomer',
        () => LegacyVanStrings.needCustomer,
        () => VanStrings.needCustomer,
      );
      eq(
        'VanStrings.needLines',
        () => LegacyVanStrings.needLines,
        () => VanStrings.needLines,
      );
      eq(
        'VanStrings.saveFailed',
        () => LegacyVanStrings.saveFailed,
        () => VanStrings.saveFailed,
      );
      eq(
        'VanStrings.discardTitle',
        () => LegacyVanStrings.discardTitle,
        () => VanStrings.discardTitle,
      );
      eq(
        'VanStrings.discardMessage',
        () => LegacyVanStrings.discardMessage,
        () => VanStrings.discardMessage,
      );
      eq(
        'VanStrings.discard',
        () => LegacyVanStrings.discard,
        () => VanStrings.discard,
      );
      eq(
        'VanStrings.returnTitle',
        () => LegacyVanStrings.returnTitle,
        () => VanStrings.returnTitle,
      );
      eq(
        'VanStrings.returnDesc',
        () => LegacyVanStrings.returnDesc,
        () => VanStrings.returnDesc,
      );
      eq(
        'VanStrings.loadingInvoices',
        () => LegacyVanStrings.loadingInvoices,
        () => VanStrings.loadingInvoices,
      );
      eq(
        'VanStrings.invoicesFailed',
        () => LegacyVanStrings.invoicesFailed,
        () => VanStrings.invoicesFailed,
      );
      eq(
        'VanStrings.noInvoices',
        () => LegacyVanStrings.noInvoices,
        () => VanStrings.noInvoices,
      );
      eq(
        'VanStrings.noInvoicesHint',
        () => LegacyVanStrings.noInvoicesHint,
        () => VanStrings.noInvoicesHint,
      );
      eq(
        'VanStrings.searchInvoice',
        () => LegacyVanStrings.searchInvoice,
        () => VanStrings.searchInvoice,
      );
      eq(
        'VanStrings.chooseInvoice',
        () => LegacyVanStrings.chooseInvoice,
        () => VanStrings.chooseInvoice,
      );
      eq(
        'VanStrings.loadingItems',
        () => LegacyVanStrings.loadingItems,
        () => VanStrings.loadingItems,
      );
      eq(
        'VanStrings.itemsFailed',
        () => LegacyVanStrings.itemsFailed,
        () => VanStrings.itemsFailed,
      );
      eq(
        'VanStrings.chooseItems',
        () => LegacyVanStrings.chooseItems,
        () => VanStrings.chooseItems,
      );
      eq(
        'VanStrings.nothingReturnable',
        () => LegacyVanStrings.nothingReturnable,
        () => VanStrings.nothingReturnable,
      );
      eq(
        'VanStrings.returnQty',
        () => LegacyVanStrings.returnQty,
        () => VanStrings.returnQty,
      );
      eq(
        'VanStrings.needReturnLines',
        () => LegacyVanStrings.needReturnLines,
        () => VanStrings.needReturnLines,
      );
      eq(
        'VanStrings.saveReturn',
        () => LegacyVanStrings.saveReturn,
        () => VanStrings.saveReturn,
      );
      eq(
        'VanStrings.returnFailed',
        () => LegacyVanStrings.returnFailed,
        () => VanStrings.returnFailed,
      );
      eq(
        'VanStrings.returnSavedTitle',
        () => LegacyVanStrings.returnSavedTitle,
        () => VanStrings.returnSavedTitle,
      );
      eq(
        'VanStrings.returnSavedNote',
        () => LegacyVanStrings.returnSavedNote,
        () => VanStrings.returnSavedNote,
      );
      eq(
        'VanStrings.returnAgainst',
        () => LegacyVanStrings.returnAgainst,
        () => VanStrings.returnAgainst,
      );
      eq(
        'VanStrings.returnValue',
        () => LegacyVanStrings.returnValue,
        () => VanStrings.returnValue,
      );
      eq(
        'VanStrings.netTotal',
        () => LegacyVanStrings.netTotal,
        () => VanStrings.netTotal,
      );
      eq(
        'VanStrings.taxes',
        () => LegacyVanStrings.taxes,
        () => VanStrings.taxes,
      );
      eq(
        'VanStrings.grandTotal',
        () => LegacyVanStrings.grandTotal,
        () => VanStrings.grandTotal,
      );
      eq('VanStrings.done', () => LegacyVanStrings.done, () => VanStrings.done);
      eq(
        'VanStrings.creditTitle',
        () => LegacyVanStrings.creditTitle,
        () => VanStrings.creditTitle,
      );
      eq(
        'VanStrings.creditDesc',
        () => LegacyVanStrings.creditDesc,
        () => VanStrings.creditDesc,
      );
      eq(
        'VanStrings.loadingCredit',
        () => LegacyVanStrings.loadingCredit,
        () => VanStrings.loadingCredit,
      );
      eq(
        'VanStrings.creditFailed',
        () => LegacyVanStrings.creditFailed,
        () => VanStrings.creditFailed,
      );
      eq(
        'VanStrings.chooseCustomerHint',
        () => LegacyVanStrings.chooseCustomerHint,
        () => VanStrings.chooseCustomerHint,
      );
      eq(
        'VanStrings.creditLimit',
        () => LegacyVanStrings.creditLimit,
        () => VanStrings.creditLimit,
      );
      eq(
        'VanStrings.currentBalance',
        () => LegacyVanStrings.currentBalance,
        () => VanStrings.currentBalance,
      );
      eq(
        'VanStrings.currentBalanceHint',
        () => LegacyVanStrings.currentBalanceHint,
        () => VanStrings.currentBalanceHint,
      );
      eq(
        'VanStrings.availableCredit',
        () => LegacyVanStrings.availableCredit,
        () => VanStrings.availableCredit,
      );
      eq(
        'VanStrings.noCreditLimit',
        () => LegacyVanStrings.noCreditLimit,
        () => VanStrings.noCreditLimit,
      );
      eq(
        'VanStrings.limitFromCustomer',
        () => LegacyVanStrings.limitFromCustomer,
        () => VanStrings.limitFromCustomer,
      );
      eq(
        'VanStrings.overLimit',
        () => LegacyVanStrings.overLimit,
        () => VanStrings.overLimit,
      );
      eq(
        'VanStrings.customerGroup',
        () => LegacyVanStrings.customerGroup,
        () => VanStrings.customerGroup,
      );
      eq(
        'VanStrings.phone',
        () => LegacyVanStrings.phone,
        () => VanStrings.phone,
      );
      eq(
        'VanStrings.customerId',
        () => LegacyVanStrings.customerId,
        () => VanStrings.customerId,
      );
      eq(
        'VanStrings.creditNote',
        () => LegacyVanStrings.creditNote,
        () => VanStrings.creditNote,
      );
      eq(
        'VanStrings.creditCheck',
        () => LegacyVanStrings.creditCheck,
        () => VanStrings.creditCheck,
      );
      eq(
        'VanStrings.withinLimit',
        () => LegacyVanStrings.withinLimit,
        () => VanStrings.withinLimit,
      );
      eq(
        'VanStrings.cannotCheckLimit',
        () => LegacyVanStrings.cannotCheckLimit,
        () => VanStrings.cannotCheckLimit,
      );
      eq(
        'VanStrings.exceedsTitle',
        () => LegacyVanStrings.exceedsTitle,
        () => VanStrings.exceedsTitle,
      );
      eq(
        'VanStrings.saveAnyway',
        () => LegacyVanStrings.saveAnyway,
        () => VanStrings.saveAnyway,
      );
      eq(
        'VanStrings.eodTitle',
        () => LegacyVanStrings.eodTitle,
        () => VanStrings.eodTitle,
      );
      eq(
        'VanStrings.eodDesc',
        () => LegacyVanStrings.eodDesc,
        () => VanStrings.eodDesc,
      );
      eq(
        'VanStrings.stockCountTab',
        () => LegacyVanStrings.stockCountTab,
        () => VanStrings.stockCountTab,
      );
      eq(
        'VanStrings.daySalesTab',
        () => LegacyVanStrings.daySalesTab,
        () => VanStrings.daySalesTab,
      );
      eq(
        'VanStrings.systemQty',
        () => LegacyVanStrings.systemQty,
        () => VanStrings.systemQty,
      );
      eq(
        'VanStrings.physicalQty',
        () => LegacyVanStrings.physicalQty,
        () => VanStrings.physicalQty,
      );
      eq(
        'VanStrings.difference',
        () => LegacyVanStrings.difference,
        () => VanStrings.difference,
      );
      eq(
        'VanStrings.onlyDifferences',
        () => LegacyVanStrings.onlyDifferences,
        () => VanStrings.onlyDifferences,
      );
      eq(
        'VanStrings.countHint',
        () => LegacyVanStrings.countHint,
        () => VanStrings.countHint,
      );
      eq(
        'VanStrings.qtyNotNegative',
        () => LegacyVanStrings.qtyNotNegative,
        () => VanStrings.qtyNotNegative,
      );
      eq(
        'VanStrings.createReconciliation',
        () => LegacyVanStrings.createReconciliation,
        () => VanStrings.createReconciliation,
      );
      eq(
        'VanStrings.noDifferences',
        () => LegacyVanStrings.noDifferences,
        () => VanStrings.noDifferences,
      );
      eq(
        'VanStrings.reconcileTitle',
        () => LegacyVanStrings.reconcileTitle,
        () => VanStrings.reconcileTitle,
      );
      eq(
        'VanStrings.reconcileFailed',
        () => LegacyVanStrings.reconcileFailed,
        () => VanStrings.reconcileFailed,
      );
      eq(
        'VanStrings.loadingDaySales',
        () => LegacyVanStrings.loadingDaySales,
        () => VanStrings.loadingDaySales,
      );
      eq(
        'VanStrings.daySalesFailed',
        () => LegacyVanStrings.daySalesFailed,
        () => VanStrings.daySalesFailed,
      );
      eq(
        'VanStrings.totalSales',
        () => LegacyVanStrings.totalSales,
        () => VanStrings.totalSales,
      );
      eq(
        'VanStrings.totalReturns',
        () => LegacyVanStrings.totalReturns,
        () => VanStrings.totalReturns,
      );
      eq(
        'VanStrings.netSales',
        () => LegacyVanStrings.netSales,
        () => VanStrings.netSales,
      );
      eq(
        'VanStrings.noDaySales',
        () => LegacyVanStrings.noDaySales,
        () => VanStrings.noDaySales,
      );
      eq(
        'VanStrings.dayTotalsNote',
        () => LegacyVanStrings.dayTotalsNote,
        () => VanStrings.dayTotalsNote,
      );
      eq(
        'VanStrings.draftLabel',
        () => LegacyVanStrings.draftLabel,
        () => VanStrings.draftLabel,
      );
      eq(
        'VanStrings.returnLabel',
        () => LegacyVanStrings.returnLabel,
        () => VanStrings.returnLabel,
      );
      eq(
        'VanStrings.refillTitle',
        () => LegacyVanStrings.refillTitle,
        () => VanStrings.refillTitle,
      );
      eq(
        'VanStrings.refillDesc',
        () => LegacyVanStrings.refillDesc,
        () => VanStrings.refillDesc,
      );
      eq(
        'VanStrings.refillHint',
        () => LegacyVanStrings.refillHint,
        () => VanStrings.refillHint,
      );
      eq(
        'VanStrings.requestedQty',
        () => LegacyVanStrings.requestedQty,
        () => VanStrings.requestedQty,
      );
      eq('VanStrings.from', () => LegacyVanStrings.from, () => VanStrings.from);
      eq('VanStrings.to', () => LegacyVanStrings.to, () => VanStrings.to);
      eq(
        'VanStrings.saveRequest',
        () => LegacyVanStrings.saveRequest,
        () => VanStrings.saveRequest,
      );
      eq(
        'VanStrings.needRequestLines',
        () => LegacyVanStrings.needRequestLines,
        () => VanStrings.needRequestLines,
      );
      eq(
        'VanStrings.requestFailed',
        () => LegacyVanStrings.requestFailed,
        () => VanStrings.requestFailed,
      );
      eq(
        'VanStrings.requestSavedTitle',
        () => LegacyVanStrings.requestSavedTitle,
        () => VanStrings.requestSavedTitle,
      );
      eq(
        'VanStrings.requestSavedNote',
        () => LegacyVanStrings.requestSavedNote,
        () => VanStrings.requestSavedNote,
      );
      eq(
        'VanStrings.requestNo',
        () => LegacyVanStrings.requestNo,
        () => VanStrings.requestNo,
      );
      eq(
        'VanStrings.requestStatus',
        () => LegacyVanStrings.requestStatus,
        () => VanStrings.requestStatus,
      );
      eq(
        'VanStrings.requestDate',
        () => LegacyVanStrings.requestDate,
        () => VanStrings.requestDate,
      );
      eq(
        'VanStrings.requiredBy',
        () => LegacyVanStrings.requiredBy,
        () => VanStrings.requiredBy,
      );
      eq(
        'VanStrings.productsCount',
        () => LegacyVanStrings.productsCount(7),
        () => VanStrings.productsCount(7),
      );
      eq(
        'VanStrings.productsCount[\'0\']',
        () => LegacyVanStrings.productsCount(0),
        () => VanStrings.productsCount(0),
      );
      eq(
        'VanStrings.productsCount[\'1\']',
        () => LegacyVanStrings.productsCount(1),
        () => VanStrings.productsCount(1),
      );
      eq(
        'VanStrings.productsCount[\'2\']',
        () => LegacyVanStrings.productsCount(2),
        () => VanStrings.productsCount(2),
      );
      eq(
        'VanStrings.productsCount[\'11\']',
        () => LegacyVanStrings.productsCount(11),
        () => VanStrings.productsCount(11),
      );
      eq(
        'VanStrings.productsCount[\'100\']',
        () => LegacyVanStrings.productsCount(100),
        () => VanStrings.productsCount(100),
      );
      eq(
        'VanStrings.scanned',
        () => LegacyVanStrings.scanned('X1'),
        () => VanStrings.scanned('X1'),
      );
      eq(
        'VanStrings.notInVan',
        () => LegacyVanStrings.notInVan('X1'),
        () => VanStrings.notInVan('X1'),
      );
      eq(
        'VanStrings.inVan',
        () => LegacyVanStrings.inVan('X1'),
        () => VanStrings.inVan('X1'),
      );
      eq(
        'VanStrings.unitFactor',
        () => LegacyVanStrings.unitFactor('X1', 'X1', 'X1'),
        () => VanStrings.unitFactor('X1', 'X1', 'X1'),
      );
      eq(
        'VanStrings.qtyWhole',
        () => LegacyVanStrings.qtyWhole('X1'),
        () => VanStrings.qtyWhole('X1'),
      );
      eq(
        'VanStrings.qtyAboveStock',
        () => LegacyVanStrings.qtyAboveStock('X1'),
        () => VanStrings.qtyAboveStock('X1'),
      );
      eq(
        'VanStrings.linesCount',
        () => LegacyVanStrings.linesCount(7),
        () => VanStrings.linesCount(7),
      );
      eq(
        'VanStrings.linesCount[\'0\']',
        () => LegacyVanStrings.linesCount(0),
        () => VanStrings.linesCount(0),
      );
      eq(
        'VanStrings.linesCount[\'1\']',
        () => LegacyVanStrings.linesCount(1),
        () => VanStrings.linesCount(1),
      );
      eq(
        'VanStrings.linesCount[\'2\']',
        () => LegacyVanStrings.linesCount(2),
        () => VanStrings.linesCount(2),
      );
      eq(
        'VanStrings.linesCount[\'11\']',
        () => LegacyVanStrings.linesCount(11),
        () => VanStrings.linesCount(11),
      );
      eq(
        'VanStrings.linesCount[\'100\']',
        () => LegacyVanStrings.linesCount(100),
        () => VanStrings.linesCount(100),
      );
      eq(
        'VanStrings.saved',
        () => LegacyVanStrings.saved('X1', 'X1'),
        () => VanStrings.saved('X1', 'X1'),
      );
      eq(
        'VanStrings.invoiceTotal',
        () => LegacyVanStrings.invoiceTotal('X1'),
        () => VanStrings.invoiceTotal('X1'),
      );
      eq(
        'VanStrings.soldQty',
        () => LegacyVanStrings.soldQty('X1'),
        () => VanStrings.soldQty('X1'),
      );
      eq(
        'VanStrings.returnedQty',
        () => LegacyVanStrings.returnedQty('X1'),
        () => VanStrings.returnedQty('X1'),
      );
      eq(
        'VanStrings.returnableQty',
        () => LegacyVanStrings.returnableQty('X1'),
        () => VanStrings.returnableQty('X1'),
      );
      eq(
        'VanStrings.qtyAboveReturnable',
        () => LegacyVanStrings.qtyAboveReturnable('X1'),
        () => VanStrings.qtyAboveReturnable('X1'),
      );
      eq(
        'VanStrings.selectedForReturn',
        () => LegacyVanStrings.selectedForReturn(7),
        () => VanStrings.selectedForReturn(7),
      );
      eq(
        'VanStrings.selectedForReturn[\'0\']',
        () => LegacyVanStrings.selectedForReturn(0),
        () => VanStrings.selectedForReturn(0),
      );
      eq(
        'VanStrings.selectedForReturn[\'1\']',
        () => LegacyVanStrings.selectedForReturn(1),
        () => VanStrings.selectedForReturn(1),
      );
      eq(
        'VanStrings.selectedForReturn[\'2\']',
        () => LegacyVanStrings.selectedForReturn(2),
        () => VanStrings.selectedForReturn(2),
      );
      eq(
        'VanStrings.selectedForReturn[\'11\']',
        () => LegacyVanStrings.selectedForReturn(11),
        () => VanStrings.selectedForReturn(11),
      );
      eq(
        'VanStrings.selectedForReturn[\'100\']',
        () => LegacyVanStrings.selectedForReturn(100),
        () => VanStrings.selectedForReturn(100),
      );
      eq(
        'VanStrings.limitFromGroup',
        () => LegacyVanStrings.limitFromGroup('X1'),
        () => VanStrings.limitFromGroup('X1'),
      );
      eq(
        'VanStrings.usedPercent',
        () => LegacyVanStrings.usedPercent('X1'),
        () => VanStrings.usedPercent('X1'),
      );
      eq(
        'VanStrings.afterInvoice',
        () => LegacyVanStrings.afterInvoice('X1'),
        () => VanStrings.afterInvoice('X1'),
      );
      eq(
        'VanStrings.exceedsLimit',
        () => LegacyVanStrings.exceedsLimit('X1'),
        () => VanStrings.exceedsLimit('X1'),
      );
      eq(
        'VanStrings.differencesCount',
        () => LegacyVanStrings.differencesCount(7),
        () => VanStrings.differencesCount(7),
      );
      eq(
        'VanStrings.differencesCount[\'0\']',
        () => LegacyVanStrings.differencesCount(0),
        () => VanStrings.differencesCount(0),
      );
      eq(
        'VanStrings.differencesCount[\'1\']',
        () => LegacyVanStrings.differencesCount(1),
        () => VanStrings.differencesCount(1),
      );
      eq(
        'VanStrings.differencesCount[\'2\']',
        () => LegacyVanStrings.differencesCount(2),
        () => VanStrings.differencesCount(2),
      );
      eq(
        'VanStrings.differencesCount[\'11\']',
        () => LegacyVanStrings.differencesCount(11),
        () => VanStrings.differencesCount(11),
      );
      eq(
        'VanStrings.differencesCount[\'100\']',
        () => LegacyVanStrings.differencesCount(100),
        () => VanStrings.differencesCount(100),
      );
      eq(
        'VanStrings.reconcileMessage',
        () => LegacyVanStrings.reconcileMessage(7),
        () => VanStrings.reconcileMessage(7),
      );
      eq(
        'VanStrings.reconcileMessage[\'0\']',
        () => LegacyVanStrings.reconcileMessage(0),
        () => VanStrings.reconcileMessage(0),
      );
      eq(
        'VanStrings.reconcileMessage[\'1\']',
        () => LegacyVanStrings.reconcileMessage(1),
        () => VanStrings.reconcileMessage(1),
      );
      eq(
        'VanStrings.reconcileMessage[\'2\']',
        () => LegacyVanStrings.reconcileMessage(2),
        () => VanStrings.reconcileMessage(2),
      );
      eq(
        'VanStrings.reconcileMessage[\'11\']',
        () => LegacyVanStrings.reconcileMessage(11),
        () => VanStrings.reconcileMessage(11),
      );
      eq(
        'VanStrings.reconcileMessage[\'100\']',
        () => LegacyVanStrings.reconcileMessage(100),
        () => VanStrings.reconcileMessage(100),
      );
      eq(
        'VanStrings.reconcileSaved',
        () => LegacyVanStrings.reconcileSaved('X1'),
        () => VanStrings.reconcileSaved('X1'),
      );
      eq(
        'VanStrings.invoicesCount',
        () => LegacyVanStrings.invoicesCount(7),
        () => VanStrings.invoicesCount(7),
      );
      eq(
        'VanStrings.invoicesCount[\'0\']',
        () => LegacyVanStrings.invoicesCount(0),
        () => VanStrings.invoicesCount(0),
      );
      eq(
        'VanStrings.invoicesCount[\'1\']',
        () => LegacyVanStrings.invoicesCount(1),
        () => VanStrings.invoicesCount(1),
      );
      eq(
        'VanStrings.invoicesCount[\'2\']',
        () => LegacyVanStrings.invoicesCount(2),
        () => VanStrings.invoicesCount(2),
      );
      eq(
        'VanStrings.invoicesCount[\'11\']',
        () => LegacyVanStrings.invoicesCount(11),
        () => VanStrings.invoicesCount(11),
      );
      eq(
        'VanStrings.invoicesCount[\'100\']',
        () => LegacyVanStrings.invoicesCount(100),
        () => VanStrings.invoicesCount(100),
      );
      eq(
        'VanStrings.returnsCount',
        () => LegacyVanStrings.returnsCount(7),
        () => VanStrings.returnsCount(7),
      );
      eq(
        'VanStrings.returnsCount[\'0\']',
        () => LegacyVanStrings.returnsCount(0),
        () => VanStrings.returnsCount(0),
      );
      eq(
        'VanStrings.returnsCount[\'1\']',
        () => LegacyVanStrings.returnsCount(1),
        () => VanStrings.returnsCount(1),
      );
      eq(
        'VanStrings.returnsCount[\'2\']',
        () => LegacyVanStrings.returnsCount(2),
        () => VanStrings.returnsCount(2),
      );
      eq(
        'VanStrings.returnsCount[\'11\']',
        () => LegacyVanStrings.returnsCount(11),
        () => VanStrings.returnsCount(11),
      );
      eq(
        'VanStrings.returnsCount[\'100\']',
        () => LegacyVanStrings.returnsCount(100),
        () => VanStrings.returnsCount(100),
      );
      eq(
        'VanStrings.draftsPending',
        () => LegacyVanStrings.draftsPending(7, 'X1'),
        () => VanStrings.draftsPending(7, 'X1'),
      );
      eq(
        'VanStrings.draftsPending[\'0\', "\'X1\'"]',
        () => LegacyVanStrings.draftsPending(0, 'X1'),
        () => VanStrings.draftsPending(0, 'X1'),
      );
      eq(
        'VanStrings.draftsPending[\'1\', "\'X1\'"]',
        () => LegacyVanStrings.draftsPending(1, 'X1'),
        () => VanStrings.draftsPending(1, 'X1'),
      );
      eq(
        'VanStrings.draftsPending[\'2\', "\'X1\'"]',
        () => LegacyVanStrings.draftsPending(2, 'X1'),
        () => VanStrings.draftsPending(2, 'X1'),
      );
      eq(
        'VanStrings.draftsPending[\'11\', "\'X1\'"]',
        () => LegacyVanStrings.draftsPending(11, 'X1'),
        () => VanStrings.draftsPending(11, 'X1'),
      );
      eq(
        'VanStrings.draftsPending[\'100\', "\'X1\'"]',
        () => LegacyVanStrings.draftsPending(100, 'X1'),
        () => VanStrings.draftsPending(100, 'X1'),
      );
      eq(
        'VanStrings.requestedCount',
        () => LegacyVanStrings.requestedCount(7),
        () => VanStrings.requestedCount(7),
      );
      eq(
        'VanStrings.requestedCount[\'0\']',
        () => LegacyVanStrings.requestedCount(0),
        () => VanStrings.requestedCount(0),
      );
      eq(
        'VanStrings.requestedCount[\'1\']',
        () => LegacyVanStrings.requestedCount(1),
        () => VanStrings.requestedCount(1),
      );
      eq(
        'VanStrings.requestedCount[\'2\']',
        () => LegacyVanStrings.requestedCount(2),
        () => VanStrings.requestedCount(2),
      );
      eq(
        'VanStrings.requestedCount[\'11\']',
        () => LegacyVanStrings.requestedCount(11),
        () => VanStrings.requestedCount(11),
      );
      eq(
        'VanStrings.requestedCount[\'100\']',
        () => LegacyVanStrings.requestedCount(100),
        () => VanStrings.requestedCount(100),
      );
      eq(
        'VisitStrings.home',
        () => LegacyVisitStrings.home,
        () => VisitStrings.home,
      );
      eq(
        'VisitStrings.dashboard',
        () => LegacyVisitStrings.dashboard,
        () => VisitStrings.dashboard,
      );
      eq(
        'VisitStrings.settings',
        () => LegacyVisitStrings.settings,
        () => VisitStrings.settings,
      );
      eq(
        'VisitStrings.section',
        () => LegacyVisitStrings.section,
        () => VisitStrings.section,
      );
      eq(
        'VisitStrings.todayTitle',
        () => LegacyVisitStrings.todayTitle,
        () => VisitStrings.todayTitle,
      );
      eq(
        'VisitStrings.allVisits',
        () => LegacyVisitStrings.allVisits,
        () => VisitStrings.allVisits,
      );
      eq(
        'VisitStrings.newVisit',
        () => LegacyVisitStrings.newVisit,
        () => VisitStrings.newVisit,
      );
      eq(
        'VisitStrings.editVisit',
        () => LegacyVisitStrings.editVisit,
        () => VisitStrings.editVisit,
      );
      eq(
        'VisitStrings.loading',
        () => LegacyVisitStrings.loading,
        () => VisitStrings.loading,
      );
      eq(
        'VisitStrings.loadFailed',
        () => LegacyVisitStrings.loadFailed,
        () => VisitStrings.loadFailed,
      );
      eq(
        'VisitStrings.noToday',
        () => LegacyVisitStrings.noToday,
        () => VisitStrings.noToday,
      );
      eq(
        'VisitStrings.noVisits',
        () => LegacyVisitStrings.noVisits,
        () => VisitStrings.noVisits,
      );
      eq(
        'VisitStrings.showCancelled',
        () => LegacyVisitStrings.showCancelled,
        () => VisitStrings.showCancelled,
      );
      eq(
        'VisitStrings.forever',
        () => LegacyVisitStrings.forever,
        () => VisitStrings.forever,
      );
      eq(
        'VisitStrings.oneOff',
        () => LegacyVisitStrings.oneOff,
        () => VisitStrings.oneOff,
      );
      eq(
        'VisitStrings.customer',
        () => LegacyVisitStrings.customer,
        () => VisitStrings.customer,
      );
      eq(
        'VisitStrings.chooseCustomer',
        () => LegacyVisitStrings.chooseCustomer,
        () => VisitStrings.chooseCustomer,
      );
      eq(
        'VisitStrings.searchCustomer',
        () => LegacyVisitStrings.searchCustomer,
        () => VisitStrings.searchCustomer,
      );
      eq(
        'VisitStrings.loadingCustomers',
        () => LegacyVisitStrings.loadingCustomers,
        () => VisitStrings.loadingCustomers,
      );
      eq(
        'VisitStrings.noCustomers',
        () => LegacyVisitStrings.noCustomers,
        () => VisitStrings.noCustomers,
      );
      eq(
        'VisitStrings.date',
        () => LegacyVisitStrings.date,
        () => VisitStrings.date,
      );
      eq(
        'VisitStrings.startTime',
        () => LegacyVisitStrings.startTime,
        () => VisitStrings.startTime,
      );
      eq(
        'VisitStrings.endTime',
        () => LegacyVisitStrings.endTime,
        () => VisitStrings.endTime,
      );
      eq(
        'VisitStrings.notes',
        () => LegacyVisitStrings.notes,
        () => VisitStrings.notes,
      );
      eq(
        'VisitStrings.weekly',
        () => LegacyVisitStrings.weekly,
        () => VisitStrings.weekly,
      );
      eq(
        'VisitStrings.weeklyHint',
        () => LegacyVisitStrings.weeklyHint,
        () => VisitStrings.weeklyHint,
      );
      eq(
        'VisitStrings.repeatTill',
        () => LegacyVisitStrings.repeatTill,
        () => VisitStrings.repeatTill,
      );
      eq(
        'VisitStrings.noEndDate',
        () => LegacyVisitStrings.noEndDate,
        () => VisitStrings.noEndDate,
      );
      eq(
        'VisitStrings.seriesNote',
        () => LegacyVisitStrings.seriesNote,
        () => VisitStrings.seriesNote,
      );
      eq(
        'VisitStrings.save',
        () => LegacyVisitStrings.save,
        () => VisitStrings.save,
      );
      eq(
        'VisitStrings.customerRequired',
        () => LegacyVisitStrings.customerRequired,
        () => VisitStrings.customerRequired,
      );
      eq(
        'VisitStrings.endBeforeStart',
        () => LegacyVisitStrings.endBeforeStart,
        () => VisitStrings.endBeforeStart,
      );
      eq(
        'VisitStrings.tillBeforeStart',
        () => LegacyVisitStrings.tillBeforeStart,
        () => VisitStrings.tillBeforeStart,
      );
      eq(
        'VisitStrings.noVisitsDay',
        () => LegacyVisitStrings.noVisitsDay,
        () => VisitStrings.noVisitsDay,
      );
      eq(
        'VisitStrings.previousMonth',
        () => LegacyVisitStrings.previousMonth,
        () => VisitStrings.previousMonth,
      );
      eq(
        'VisitStrings.nextMonth',
        () => LegacyVisitStrings.nextMonth,
        () => VisitStrings.nextMonth,
      );
      eq(
        'VisitStrings.today',
        () => LegacyVisitStrings.today,
        () => VisitStrings.today,
      );
      eq(
        'VisitStrings.created',
        () => LegacyVisitStrings.created,
        () => VisitStrings.created,
      );
      eq(
        'VisitStrings.updated',
        () => LegacyVisitStrings.updated,
        () => VisitStrings.updated,
      );
      eq(
        'VisitStrings.saveFailed',
        () => LegacyVisitStrings.saveFailed,
        () => VisitStrings.saveFailed,
      );
      eq(
        'VisitStrings.edit',
        () => LegacyVisitStrings.edit,
        () => VisitStrings.edit,
      );
      eq(
        'VisitStrings.complete',
        () => LegacyVisitStrings.complete,
        () => VisitStrings.complete,
      );
      eq(
        'VisitStrings.reopen',
        () => LegacyVisitStrings.reopen,
        () => VisitStrings.reopen,
      );
      eq(
        'VisitStrings.cancel',
        () => LegacyVisitStrings.cancel,
        () => VisitStrings.cancel,
      );
      eq(
        'VisitStrings.delete',
        () => LegacyVisitStrings.delete,
        () => VisitStrings.delete,
      );
      eq(
        'VisitStrings.deleteMessage',
        () => LegacyVisitStrings.deleteMessage,
        () => VisitStrings.deleteMessage,
      );
      eq(
        'VisitStrings.editClosedMessage',
        () => LegacyVisitStrings.editClosedMessage,
        () => VisitStrings.editClosedMessage,
      );
      eq(
        'VisitStrings.editAnyway',
        () => LegacyVisitStrings.editAnyway,
        () => VisitStrings.editAnyway,
      );
      eq(
        'VisitStrings.cancelled',
        () => LegacyVisitStrings.cancelled,
        () => VisitStrings.cancelled,
      );
      eq(
        'VisitStrings.completed',
        () => LegacyVisitStrings.completed,
        () => VisitStrings.completed,
      );
      eq(
        'VisitStrings.reopened',
        () => LegacyVisitStrings.reopened,
        () => VisitStrings.reopened,
      );
      eq(
        'VisitStrings.deleted',
        () => LegacyVisitStrings.deleted,
        () => VisitStrings.deleted,
      );
      eq(
        'VisitStrings.actionFailed',
        () => LegacyVisitStrings.actionFailed,
        () => VisitStrings.actionFailed,
      );
      eq(
        'VisitStrings.greeting',
        () => LegacyVisitStrings.greeting(7),
        () => VisitStrings.greeting(7),
      );
      eq(
        'VisitStrings.greeting[\'0\']',
        () => LegacyVisitStrings.greeting(0),
        () => VisitStrings.greeting(0),
      );
      eq(
        'VisitStrings.greeting[\'1\']',
        () => LegacyVisitStrings.greeting(1),
        () => VisitStrings.greeting(1),
      );
      eq(
        'VisitStrings.greeting[\'2\']',
        () => LegacyVisitStrings.greeting(2),
        () => VisitStrings.greeting(2),
      );
      eq(
        'VisitStrings.greeting[\'11\']',
        () => LegacyVisitStrings.greeting(11),
        () => VisitStrings.greeting(11),
      );
      eq(
        'VisitStrings.greeting[\'100\']',
        () => LegacyVisitStrings.greeting(100),
        () => VisitStrings.greeting(100),
      );
      eq(
        'VisitStrings.welcome',
        () => LegacyVisitStrings.welcome('X1'),
        () => VisitStrings.welcome('X1'),
      );
      eq(
        'VisitStrings.welcome[\'null\']',
        () => LegacyVisitStrings.welcome(null),
        () => VisitStrings.welcome(null),
      );
      eq(
        'VisitStrings.welcome["\'\'"]',
        () => LegacyVisitStrings.welcome(''),
        () => VisitStrings.welcome(''),
      );
      eq(
        'VisitStrings.visitsToday',
        () => LegacyVisitStrings.visitsToday(7),
        () => VisitStrings.visitsToday(7),
      );
      eq(
        'VisitStrings.visitsToday[\'0\']',
        () => LegacyVisitStrings.visitsToday(0),
        () => VisitStrings.visitsToday(0),
      );
      eq(
        'VisitStrings.visitsToday[\'1\']',
        () => LegacyVisitStrings.visitsToday(1),
        () => VisitStrings.visitsToday(1),
      );
      eq(
        'VisitStrings.visitsToday[\'2\']',
        () => LegacyVisitStrings.visitsToday(2),
        () => VisitStrings.visitsToday(2),
      );
      eq(
        'VisitStrings.visitsToday[\'11\']',
        () => LegacyVisitStrings.visitsToday(11),
        () => VisitStrings.visitsToday(11),
      );
      eq(
        'VisitStrings.visitsToday[\'100\']',
        () => LegacyVisitStrings.visitsToday(100),
        () => VisitStrings.visitsToday(100),
      );
      eq(
        'VisitStrings.subject',
        () => LegacyVisitStrings.subject('X1'),
        () => VisitStrings.subject('X1'),
      );
      eq(
        'VisitStrings.status',
        () => LegacyVisitStrings.status('X1'),
        () => VisitStrings.status('X1'),
      );
      eq(
        'VisitStrings.weekday',
        () => LegacyVisitStrings.weekday(7),
        () => VisitStrings.weekday(7),
      );
      eq(
        'VisitStrings.weekday[\'0\']',
        () => LegacyVisitStrings.weekday(0),
        () => VisitStrings.weekday(0),
      );
      eq(
        'VisitStrings.weekday[\'1\']',
        () => LegacyVisitStrings.weekday(1),
        () => VisitStrings.weekday(1),
      );
      eq(
        'VisitStrings.weekday[\'2\']',
        () => LegacyVisitStrings.weekday(2),
        () => VisitStrings.weekday(2),
      );
      eq(
        'VisitStrings.weekday[\'11\']',
        () => LegacyVisitStrings.weekday(11),
        () => VisitStrings.weekday(11),
      );
      eq(
        'VisitStrings.weekday[\'100\']',
        () => LegacyVisitStrings.weekday(100),
        () => VisitStrings.weekday(100),
      );
      eq(
        'VisitStrings.weeklyOn',
        () => LegacyVisitStrings.weeklyOn('X1'),
        () => VisitStrings.weeklyOn('X1'),
      );
      eq(
        'VisitStrings.until',
        () => LegacyVisitStrings.until('X1'),
        () => VisitStrings.until('X1'),
      );
      eq(
        'VisitStrings.conflict',
        () => LegacyVisitStrings.conflict(
          'X1',
          DateTime(2026, 1, 2, 9, 5),
          DateTime(2026, 1, 2, 9, 5),
        ),
        () => VisitStrings.conflict(
          'X1',
          DateTime(2026, 1, 2, 9, 5),
          DateTime(2026, 1, 2, 9, 5),
        ),
      );
      eq(
        'VisitStrings.cancelTitle',
        () => LegacyVisitStrings.cancelTitle('X1'),
        () => VisitStrings.cancelTitle('X1'),
      );
      eq(
        'VisitStrings.cancelMessage',
        () => LegacyVisitStrings.cancelMessage(true),
        () => VisitStrings.cancelMessage(true),
      );
      eq(
        'VisitStrings.cancelMessage[\'false\']',
        () => LegacyVisitStrings.cancelMessage(false),
        () => VisitStrings.cancelMessage(false),
      );
      eq(
        'VisitStrings.deleteTitle',
        () => LegacyVisitStrings.deleteTitle('X1'),
        () => VisitStrings.deleteTitle('X1'),
      );
      eq(
        'VisitStrings.editClosedTitle',
        () => LegacyVisitStrings.editClosedTitle('X1'),
        () => VisitStrings.editClosedTitle('X1'),
      );
      eq(
        'WarehouseStrings.section',
        () => LegacyWarehouseStrings.section,
        () => WarehouseStrings.section,
      );
      eq(
        'WarehouseStrings.loadingWarehouses',
        () => LegacyWarehouseStrings.loadingWarehouses,
        () => WarehouseStrings.loadingWarehouses,
      );
      eq(
        'WarehouseStrings.noWarehouses',
        () => LegacyWarehouseStrings.noWarehouses,
        () => WarehouseStrings.noWarehouses,
      );
      eq(
        'WarehouseStrings.loadFailed',
        () => LegacyWarehouseStrings.loadFailed,
        () => WarehouseStrings.loadFailed,
      );
      eq(
        'WarehouseStrings.loadingItems',
        () => LegacyWarehouseStrings.loadingItems,
        () => WarehouseStrings.loadingItems,
      );
      eq(
        'WarehouseStrings.noItems',
        () => LegacyWarehouseStrings.noItems,
        () => WarehouseStrings.noItems,
      );
      eq(
        'WarehouseStrings.searchItems',
        () => LegacyWarehouseStrings.searchItems,
        () => WarehouseStrings.searchItems,
      );
      eq(
        'WarehouseStrings.actual',
        () => LegacyWarehouseStrings.actual,
        () => WarehouseStrings.actual,
      );
      eq(
        'WarehouseStrings.reserved',
        () => LegacyWarehouseStrings.reserved,
        () => WarehouseStrings.reserved,
      );
      eq(
        'WarehouseStrings.available',
        () => LegacyWarehouseStrings.available,
        () => WarehouseStrings.available,
      );
      eq(
        'WarehouseStrings.transferFromHere',
        () => LegacyWarehouseStrings.transferFromHere,
        () => WarehouseStrings.transferFromHere,
      );
      eq(
        'WarehouseStrings.newTransfer',
        () => LegacyWarehouseStrings.newTransfer,
        () => WarehouseStrings.newTransfer,
      );
      eq(
        'WarehouseStrings.from',
        () => LegacyWarehouseStrings.from,
        () => WarehouseStrings.from,
      );
      eq(
        'WarehouseStrings.to',
        () => LegacyWarehouseStrings.to,
        () => WarehouseStrings.to,
      );
      eq(
        'WarehouseStrings.chooseWarehouse',
        () => LegacyWarehouseStrings.chooseWarehouse,
        () => WarehouseStrings.chooseWarehouse,
      );
      eq(
        'WarehouseStrings.sameWarehouse',
        () => LegacyWarehouseStrings.sameWarehouse,
        () => WarehouseStrings.sameWarehouse,
      );
      eq(
        'WarehouseStrings.chooseSourceFirst',
        () => LegacyWarehouseStrings.chooseSourceFirst,
        () => WarehouseStrings.chooseSourceFirst,
      );
      eq(
        'WarehouseStrings.remarks',
        () => LegacyWarehouseStrings.remarks,
        () => WarehouseStrings.remarks,
      );
      eq(
        'WarehouseStrings.quantity',
        () => LegacyWarehouseStrings.quantity,
        () => WarehouseStrings.quantity,
      );
      eq(
        'WarehouseStrings.remove',
        () => LegacyWarehouseStrings.remove,
        () => WarehouseStrings.remove,
      );
      eq(
        'WarehouseStrings.add',
        () => LegacyWarehouseStrings.add,
        () => WarehouseStrings.add,
      );
      eq(
        'WarehouseStrings.cancel',
        () => LegacyWarehouseStrings.cancel,
        () => WarehouseStrings.cancel,
      );
      eq(
        'WarehouseStrings.noLines',
        () => LegacyWarehouseStrings.noLines,
        () => WarehouseStrings.noLines,
      );
      eq(
        'WarehouseStrings.saveFailed',
        () => LegacyWarehouseStrings.saveFailed,
        () => WarehouseStrings.saveFailed,
      );
      eq(
        'WarehouseStrings.qtyPositive',
        () => LegacyWarehouseStrings.qtyPositive,
        () => WarehouseStrings.qtyPositive,
      );
      eq(
        'WarehouseStrings.reservedConfirmTitle',
        () => LegacyWarehouseStrings.reservedConfirmTitle,
        () => WarehouseStrings.reservedConfirmTitle,
      );
      eq(
        'WarehouseStrings.continueAnyway',
        () => LegacyWarehouseStrings.continueAnyway,
        () => WarehouseStrings.continueAnyway,
      );
      eq(
        'WarehouseStrings.pendingTitle',
        () => LegacyWarehouseStrings.pendingTitle,
        () => WarehouseStrings.pendingTitle,
      );
      eq(
        'WarehouseStrings.loadingPending',
        () => LegacyWarehouseStrings.loadingPending,
        () => WarehouseStrings.loadingPending,
      );
      eq(
        'WarehouseStrings.noPending',
        () => LegacyWarehouseStrings.noPending,
        () => WarehouseStrings.noPending,
      );
      eq(
        'WarehouseStrings.showItems',
        () => LegacyWarehouseStrings.showItems,
        () => WarehouseStrings.showItems,
      );
      eq(
        'WarehouseStrings.approve',
        () => LegacyWarehouseStrings.approve,
        () => WarehouseStrings.approve,
      );
      eq(
        'WarehouseStrings.reject',
        () => LegacyWarehouseStrings.reject,
        () => WarehouseStrings.reject,
      );
      eq(
        'WarehouseStrings.approveMessage',
        () => LegacyWarehouseStrings.approveMessage,
        () => WarehouseStrings.approveMessage,
      );
      eq(
        'WarehouseStrings.rejectMessage',
        () => LegacyWarehouseStrings.rejectMessage,
        () => WarehouseStrings.rejectMessage,
      );
      eq(
        'WarehouseStrings.approveFailed',
        () => LegacyWarehouseStrings.approveFailed,
        () => WarehouseStrings.approveFailed,
      );
      eq(
        'WarehouseStrings.rejectFailed',
        () => LegacyWarehouseStrings.rejectFailed,
        () => WarehouseStrings.rejectFailed,
      );
      eq(
        'WarehouseStrings.parent',
        () => LegacyWarehouseStrings.parent('X1'),
        () => WarehouseStrings.parent('X1'),
      );
      eq(
        'WarehouseStrings.itemsCount',
        () => LegacyWarehouseStrings.itemsCount(7),
        () => WarehouseStrings.itemsCount(7),
      );
      eq(
        'WarehouseStrings.itemsCount[\'0\']',
        () => LegacyWarehouseStrings.itemsCount(0),
        () => WarehouseStrings.itemsCount(0),
      );
      eq(
        'WarehouseStrings.itemsCount[\'1\']',
        () => LegacyWarehouseStrings.itemsCount(1),
        () => WarehouseStrings.itemsCount(1),
      );
      eq(
        'WarehouseStrings.itemsCount[\'2\']',
        () => LegacyWarehouseStrings.itemsCount(2),
        () => WarehouseStrings.itemsCount(2),
      );
      eq(
        'WarehouseStrings.itemsCount[\'11\']',
        () => LegacyWarehouseStrings.itemsCount(11),
        () => WarehouseStrings.itemsCount(11),
      );
      eq(
        'WarehouseStrings.itemsCount[\'100\']',
        () => LegacyWarehouseStrings.itemsCount(100),
        () => WarehouseStrings.itemsCount(100),
      );
      eq(
        'WarehouseStrings.selectedCount',
        () => LegacyWarehouseStrings.selectedCount(7),
        () => WarehouseStrings.selectedCount(7),
      );
      eq(
        'WarehouseStrings.selectedCount[\'0\']',
        () => LegacyWarehouseStrings.selectedCount(0),
        () => WarehouseStrings.selectedCount(0),
      );
      eq(
        'WarehouseStrings.selectedCount[\'1\']',
        () => LegacyWarehouseStrings.selectedCount(1),
        () => WarehouseStrings.selectedCount(1),
      );
      eq(
        'WarehouseStrings.selectedCount[\'2\']',
        () => LegacyWarehouseStrings.selectedCount(2),
        () => WarehouseStrings.selectedCount(2),
      );
      eq(
        'WarehouseStrings.selectedCount[\'11\']',
        () => LegacyWarehouseStrings.selectedCount(11),
        () => WarehouseStrings.selectedCount(11),
      );
      eq(
        'WarehouseStrings.selectedCount[\'100\']',
        () => LegacyWarehouseStrings.selectedCount(100),
        () => WarehouseStrings.selectedCount(100),
      );
      eq(
        'WarehouseStrings.saveDraft',
        () => LegacyWarehouseStrings.saveDraft(7),
        () => WarehouseStrings.saveDraft(7),
      );
      eq(
        'WarehouseStrings.saveDraft[\'0\']',
        () => LegacyWarehouseStrings.saveDraft(0),
        () => WarehouseStrings.saveDraft(0),
      );
      eq(
        'WarehouseStrings.saveDraft[\'1\']',
        () => LegacyWarehouseStrings.saveDraft(1),
        () => WarehouseStrings.saveDraft(1),
      );
      eq(
        'WarehouseStrings.saveDraft[\'2\']',
        () => LegacyWarehouseStrings.saveDraft(2),
        () => WarehouseStrings.saveDraft(2),
      );
      eq(
        'WarehouseStrings.saveDraft[\'11\']',
        () => LegacyWarehouseStrings.saveDraft(11),
        () => WarehouseStrings.saveDraft(11),
      );
      eq(
        'WarehouseStrings.saveDraft[\'100\']',
        () => LegacyWarehouseStrings.saveDraft(100),
        () => WarehouseStrings.saveDraft(100),
      );
      eq(
        'WarehouseStrings.savedDraft',
        () => LegacyWarehouseStrings.savedDraft('X1'),
        () => WarehouseStrings.savedDraft('X1'),
      );
      eq(
        'WarehouseStrings.qtyAboveActual',
        () => LegacyWarehouseStrings.qtyAboveActual('X1'),
        () => WarehouseStrings.qtyAboveActual('X1'),
      );
      eq(
        'WarehouseStrings.qtyWhole',
        () => LegacyWarehouseStrings.qtyWhole('X1'),
        () => WarehouseStrings.qtyWhole('X1'),
      );
      eq(
        'WarehouseStrings.qtyReservedWarning',
        () => LegacyWarehouseStrings.qtyReservedWarning('X1'),
        () => WarehouseStrings.qtyReservedWarning('X1'),
      );
      eq(
        'WarehouseStrings.reservedConfirmMessage',
        () => LegacyWarehouseStrings.reservedConfirmMessage('X1'),
        () => WarehouseStrings.reservedConfirmMessage('X1'),
      );
      eq(
        'WarehouseStrings.approveTitle',
        () => LegacyWarehouseStrings.approveTitle('X1'),
        () => WarehouseStrings.approveTitle('X1'),
      );
      eq(
        'WarehouseStrings.rejectTitle',
        () => LegacyWarehouseStrings.rejectTitle('X1'),
        () => WarehouseStrings.rejectTitle('X1'),
      );
      eq(
        'WarehouseStrings.approved',
        () => LegacyWarehouseStrings.approved('X1'),
        () => WarehouseStrings.approved('X1'),
      );
      eq(
        'WarehouseStrings.rejected',
        () => LegacyWarehouseStrings.rejected('X1'),
        () => WarehouseStrings.rejected('X1'),
      );
      expect(diffs, isEmpty, reason: diffs.take(20).join('\n'));
    });
  }
}
