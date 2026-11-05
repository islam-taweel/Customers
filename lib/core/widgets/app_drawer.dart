import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_strings.dart';
import '../localization/language_controller.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/order/controllers/order_controller.dart';
import '../../features/order/screens/new_order_screen.dart';
import '../../features/orders_section/screens/orders_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/purchases/screens/purchases_screen.dart';
import '../../features/sales_returns/screens/sales_returns_screen.dart';
import '../constants/inventory_strings.dart';
import '../constants/purchase_strings.dart';
import '../constants/returns_strings.dart';
import '../constants/statement_strings.dart';
import '../constants/ess_strings.dart';
import '../constants/visit_strings.dart';
import '../../features/employee_services/screens/employee_services_screen.dart';
import '../constants/warehouse_strings.dart';
import '../../features/home/screens/main_shell.dart';
import '../../features/visits/screens/visits_screen.dart';
import '../../features/warehouses/screens/warehouses_screen.dart';
import '../../features/statement/screens/customer_statement_list_screen.dart';

/// القائمة الجانبية: الشعار بالأعلى، الرئيسية ولوحة التحكم وبقية الأقسام، ومبدّل اللغة بالأسفل.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const _logoAsset = 'assets/splash/logo.png';

  /// تبويب في الشريط السفلي (الرئيسية أو لوحة التحكم أو الإعدادات)
  void _openTab(BuildContext context, ShellTab tab) {
    final navigator = Navigator.of(context);
    // قبل الإغلاق: القائمة ما زالت داخل الهيكل
    MainShell.select(context, tab);
    navigator.pop(); // إغلاق القائمة
    navigator.popUntil((route) => route.isFirst);
  }

  void _openEmployeeServices(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop(); // إغلاق القائمة
    navigator.push(EmployeeServicesScreen.route());
  }

  void _openVisits(BuildContext context) {
    final navigator = Navigator.of(context);
    final route = VisitsScreen.route(context);
    navigator.pop(); // إغلاق القائمة
    navigator.push(route);
  }

  void _openOrders(BuildContext context) {
    final navigator = Navigator.of(context);
    // متحكم جديد لكل طلبية: تبدأ دائمًا من الخطوة الأولى
    final controller = context.read<OrderControllerFactory>().create();
    navigator.pop(); // إغلاق القائمة
    navigator.push(NewOrderScreen.route(controller));
  }

  void _openOrdersSection(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop(); // إغلاق القائمة
    navigator.push(OrdersScreen.route());
  }

  void _openSalesReturns(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop(); // إغلاق القائمة
    navigator.push(SalesReturnsScreen.route());
  }

  void _openStatements(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop(); // إغلاق القائمة
    navigator.push(CustomerStatementListScreen.route());
  }

  void _openPurchases(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop(); // إغلاق القائمة
    navigator.push(PurchasesScreen.route());
  }

  void _openInventory(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop(); // إغلاق القائمة
    navigator.push(InventoryScreen.route());
  }

  void _openWarehouses(BuildContext context) {
    final navigator = Navigator.of(context);
    final route = WarehousesScreen.route(context);
    navigator.pop(); // إغلاق القائمة
    navigator.push(route);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.logoutConfirmTitle),
        content: Text(AppStrings.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppStrings.logout),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final auth = context.read<AuthController>();
    Navigator.of(context).pop(); // إغلاق القائمة
    // بوابة التطبيق تنقل المستخدم إلى شاشة الدخول فور تغيّر الحالة
    await auth.logout();
  }

  void _changeLanguage(BuildContext context, AppLanguage language) {
    final controller = context.read<LanguageController>();
    if (controller.language == language) return;
    Navigator.of(context).pop();
    // ننتظر انتهاء حركة إغلاق القائمة حتى لا تقفز لجهة الاتجاه الجديد
    Future.delayed(
      const Duration(milliseconds: 260),
      () => controller.setLanguage(language),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<LanguageController>().language;
    final fullName = context.watch<AuthController>().fullName;
    final errorColor = Theme.of(context).colorScheme.error;

    return Drawer(
      child: SafeArea(
        // تتمرر إن زادت العناصر عن ارتفاع الشاشة (الهواتف الصغيرة)، وإلا يبقى
        // تسجيل الخروج واللغة في الأسفل كما كانا
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: _items(context, current, fullName, errorColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _items(
    BuildContext context,
    AppLanguage current,
    String? fullName,
    Color errorColor,
  ) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) الشعار في الأعلى بالمنتصف
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Image.asset(
                  _logoAsset,
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // الرئيسية: الترحيب ومواعيد اليوم
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: const Icon(Icons.home_outlined),
                title: Text(VisitStrings.home),
                onTap: () => _openTab(context, ShellTab.home),
              ),
            ),

            // 2) لوحة التحكم (= شاشة العملاء)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: const Icon(Icons.dashboard_outlined),
                title: Text(AppStrings.dashboard),
                onTap: () => _openTab(context, ShellTab.dashboard),
              ),
            ),

            // المواعيد: زيارات العملاء (إنشاء وتعديل وإلغاء)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: const Icon(Icons.event_note_outlined),
                title: Text(VisitStrings.section),
                onTap: () => _openVisits(context),
              ),
            ),

            // 3) طلبيات العملاء (Stepper: العميل ← الأصناف ← الفاتورة)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(AppStrings.customerOrders),
                onTap: () => _openOrders(context),
              ),
            ),

            // 4) الطلبات: الطلبيات والتسليمات والفواتير (شريط تنقل سفلي)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(AppStrings.ordersSection),
                onTap: () => _openOrdersSection(context),
              ),
            ),

            // مردود المبيعات: اختيار عميل سابق وعرض كل أصنافه بكمياتها
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: const Icon(Icons.assignment_return_outlined),
                title: Text(ReturnsStrings.section),
                onTap: () => _openSalesReturns(context),
              ),
            ),

            // كشف حساب العملاء: كل العملاء ← كشف حساب العميل من ERPNext
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: const Icon(Icons.request_page_outlined),
                title: Text(StatementStrings.section),
                onTap: () => _openStatements(context),
              ),
            ),

            // المشتريات: أوامر الشراء والاستلامات والفواتير (شريط تنقل سفلي)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: const Icon(Icons.shopping_cart_outlined),
                title: Text(PurchaseStrings.section),
                onTap: () => _openPurchases(context),
              ),
            ),

            // الجرد: الباركود (كتابة أو كاميرا) ثم تعديل كمية الصنف وسعره
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: const Icon(Icons.qr_code_scanner),
                title: Text(InventoryStrings.section),
                onTap: () => _openInventory(context),
              ),
            ),

            // المستودعات: أصناف كل مستودع بكمياتها، ونقل الأصناف بينها
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: const Icon(Icons.warehouse_outlined),
                title: Text(WarehouseStrings.section),
                onTap: () => _openWarehouses(context),
              ),
            ),

            // خدمات الموظف: حسابي، الحضور والانصراف، الإجازات، العمل الإضافي...
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: const Icon(Icons.badge_outlined),
                title: Text(EssStrings.section),
                onTap: () => _openEmployeeServices(context),
              ),
            ),

            // 5) الإعدادات: مزامنة العملاء والأصناف والفواتير
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: const Icon(Icons.settings_outlined),
                title: Text(AppStrings.settings),
                onTap: () => _openTab(context, ShellTab.settings),
              ),
            ),

            const Spacer(),

            // تسجيل الخروج: اسم المستخدم الحالي تحت العنوان
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                leading: Icon(Icons.logout, color: errorColor),
                title: Text(
                  AppStrings.logout,
                  style: TextStyle(color: errorColor),
                ),
                subtitle: (fullName == null || fullName.isEmpty)
                    ? null
                    : Text(fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _confirmLogout(context),
              ),
            ),

            // 6) زرّان متلاصقان للتبديل بين العربية والإنجليزية
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<AppLanguage>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: AppLanguage.arabic,
                    label: Text('العربية'),
                  ),
                  ButtonSegment(
                    value: AppLanguage.english,
                    label: Text('English'),
                  ),
                ],
                selected: {current},
                onSelectionChanged: (s) => _changeLanguage(context, s.first),
              ),
            ),
          ],
        );
  }
}
