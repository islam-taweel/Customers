import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../controllers/order_controller.dart';
import '../widgets/customer_step.dart';
import '../widgets/invoice_step.dart';
import '../widgets/items_step.dart';
import '../widgets/order_bottom_bar.dart';
import '../widgets/order_stepper.dart';
import '../widgets/success_view.dart';

/// شاشة «طلبية جديدة»: Stepper من ثلاث خطوات (العميل ← الأصناف ← الفاتورة)
/// ثم شاشة نجاح برقم الطلبية. الواجهة فقط؛ كل الحالة في [OrderController].
class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  /// يربط المتحكم بالشاشة؛ الـ Provider يتلفه تلقائيًا عند إغلاق الشاشة.
  static Route<void> route(OrderController controller) {
    return MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider<OrderController>(
        create: (_) => controller,
        child: const NewOrderScreen(),
      ),
    );
  }

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  int _previousIndex = 0;

  Future<void> _onBackPressed(OrderController c) async {
    if (c.step != OrderStep.customer) {
      c.back();
      return;
    }
    // الخطوة الأولى وفي السلة أصناف: نتأكد قبل التخلي عنها
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.remove_shopping_cart_outlined),
        title: Text(AppStrings.leaveOrderTitle),
        content: Text(AppStrings.leaveOrderMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.keepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.discard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OrderController>();
    final index = c.step.index;
    final forward = index >= _previousIndex;
    _previousIndex = index;

    final isDone = c.step == OrderStep.done;
    final canPop =
        isDone || (c.step == OrderStep.customer && !c.hasUnsavedWork);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final sign = (rtl ? -1.0 : 1.0) * (forward ? 1.0 : -1.0);

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed(c);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.newOrderTitle),
          scrolledUnderElevation: 0,
        ),
        body: Column(
          children: [
            OrderStepper(step: c.step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0.06 * sign, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(c.step),
                  child: switch (c.step) {
                    OrderStep.customer => const CustomerStep(),
                    OrderStep.items => const ItemsStep(),
                    OrderStep.invoice => const InvoiceStep(),
                    OrderStep.done => const SuccessView(),
                  },
                ),
              ),
            ),
          ],
        ),
        // لوحة المفاتيح مفتوحة (بحث أو كتابة كمية): نخفي الشريط ليبقى مكان للمحتوى
        bottomNavigationBar: isDone || keyboardOpen
            ? null
            : OrderBottomBar(controller: c),
      ),
    );
  }
}
