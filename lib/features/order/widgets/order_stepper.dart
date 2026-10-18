import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../controllers/order_controller.dart';

/// مؤشر الخطوات في أعلى الشاشة: العميل ← الأصناف ← الفاتورة.
/// الخطوة المنتهية تظهر بعلامة ✓ وخط ملوّن، والحالية بدائرة مضيئة، والقادمة باهتة.
/// يتبع اتجاه اللغة تلقائيًا (RTL/LTR).
class OrderStepper extends StatelessWidget {
  final OrderStep step;

  const OrderStepper({super.key, required this.step});

  static const _duration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.person_outline, Icons.person, AppStrings.stepCustomer),
      (Icons.inventory_2_outlined, Icons.inventory_2, AppStrings.stepItems),
      (Icons.receipt_long_outlined, Icons.receipt_long, AppStrings.stepInvoice),
    ];
    // done = كل الخطوات منتهية
    final current = step.index;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Expanded(
              child: _StepNode(
                index: i,
                count: steps.length,
                current: current,
                icon: steps[i].$1,
                activeIcon: steps[i].$2,
                label: steps[i].$3,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  final int index;
  final int count;
  final int current;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _StepNode({
    required this.index,
    required this.count,
    required this.current,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDone = index < current;
    final isActive = index == current;

    final circleColor = isDone
        ? scheme.primary
        : isActive
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest;
    final borderColor = isDone || isActive ? scheme.primary : scheme.outlineVariant;
    final iconColor = isDone
        ? scheme.onPrimary
        : isActive
            ? scheme.primary
            : scheme.onSurfaceVariant;

    return Column(
      children: [
        Row(
          children: [
            // الخط قبل الدائرة (مخفي في أول خطوة)
            Expanded(
              child: _Line(
                visible: index > 0,
                filled: index <= current,
              ),
            ),
            AnimatedContainer(
              duration: OrderStepper._duration,
              curve: Curves.easeOutCubic,
              width: isActive ? 46 : 40,
              height: isActive ? 46 : 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
                border: Border.all(color: borderColor, width: isActive ? 2.5 : 1.5),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.30),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: AnimatedSwitcher(
                duration: OrderStepper._duration,
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isDone ? Icons.check_rounded : (isActive ? activeIcon : icon),
                  key: ValueKey('$index-$isDone-$isActive'),
                  color: iconColor,
                  size: isActive ? 24 : 20,
                ),
              ),
            ),
            // الخط بعد الدائرة (مخفي في آخر خطوة)
            Expanded(
              child: _Line(
                visible: index < count - 1,
                filled: index < current,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedDefaultTextStyle(
          duration: OrderStepper._duration,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: isActive || isDone
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final bool visible;
  final bool filled;

  const _Line({required this.visible, required this.filled});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: OrderStepper._duration,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: !visible
            ? Colors.transparent
            : filled
                ? scheme.primary
                : scheme.outlineVariant,
      ),
    );
  }
}
