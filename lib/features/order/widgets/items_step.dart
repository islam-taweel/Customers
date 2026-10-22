import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/order_models.dart';
import '../controllers/order_controller.dart';
import 'animated_amount.dart';
import 'order_visuals.dart';
import 'qty_control.dart';

/// الخطوة 2: مجموعات الأصناف (شرائح أفقية) ثم أصناف المجموعة المختارة.
/// الضغط على صنف يفتحه ويجلب سعره ومخزونه، ثم تُضبط الكمية والإجمالي يتحدث فورًا.
class ItemsStep extends StatefulWidget {
  const ItemsStep({super.key});

  @override
  State<ItemsStep> createState() => _ItemsStepState();
}

class _ItemsStepState extends State<ItemsStep> {
  /// الصنف المفتوح حاليًا (واحد فقط في كل مرة)
  String? _expanded;

  void _toggle(OrderController c, ErpItem item) {
    final opening = _expanded != item.code;
    setState(() => _expanded = opening ? item.code : null);
    if (opening) c.loadPricing(item);
  }

  void _warnClamped(double available) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppStrings.maxAvailable(formatQty(available))),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OrderController>();

    return Column(
      children: [
        _CustomerBanner(name: c.customer?.name ?? ''),
        _GroupChips(
          controller: c,
          onSelected: (g) {
            setState(() => _expanded = null);
            c.selectGroup(g);
          },
        ),
        const Divider(height: 1),
        Expanded(child: _body(c)),
      ],
    );
  }

  Widget _body(OrderController c) {
    if (c.groupsLoading && c.groups.isEmpty) {
      return LoadingView(message: AppStrings.loadingGroups);
    }
    if (c.groupsError != null && c.groups.isEmpty) {
      return ErrorView(message: c.groupsError!, onRetry: c.loadGroups);
    }
    if (c.groups.isEmpty) {
      return EmptyView(
        icon: Icons.folder_off_outlined,
        title: AppStrings.noGroupsTitle,
      );
    }
    if (c.group == null) {
      return EmptyView(
        icon: Icons.touch_app_outlined,
        title: AppStrings.chooseGroupHint,
      );
    }
    if (c.itemsLoading) {
      return LoadingView(message: AppStrings.loadingItems);
    }
    if (c.itemsError != null) {
      return ErrorView(message: c.itemsError!, onRetry: c.retryItems);
    }

    final items = c.items;
    if (items.isEmpty) {
      return EmptyView(
        icon: Icons.inventory_2_outlined,
        title: AppStrings.noItemsTitle,
        message: AppStrings.noItemsMessage,
      );
    }

    final visual = GroupVisual.of(c.group!);
    return ListView.builder(
      // نفس القائمة تُعاد لكل مجموعة، فالمفتاح يمنع إعادة استخدام حالة التمرير
      key: PageStorageKey<String>('items-${c.group}'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return _ItemCard(
          item: item,
          visual: visual,
          expanded: _expanded == item.code,
          onTap: () => _toggle(c, item),
          onClamped: _warnClamped,
        );
      },
    );
  }
}

/// شريط صغير يذكّر لأي عميل هذه الطلبية.
class _CustomerBanner extends StatelessWidget {
  final String name;

  const _CustomerBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: scheme.primaryContainer.withValues(alpha: 0.45),
      child: Row(
        children: [
          Icon(Icons.person_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.orderFor(name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupChips extends StatelessWidget {
  final OrderController controller;
  final ValueChanged<String> onSelected;

  const _GroupChips({required this.controller, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final groups = controller.groups;
    if (groups.isEmpty) return const SizedBox(height: 8);

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final g = groups[i];
          final visual = GroupVisual.of(g);
          final selected = controller.group == g;
          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            avatar: Icon(
              visual.icon,
              size: 18,
              color: selected ? Colors.white : visual.color,
            ),
            label: Text(AppStrings.itemGroupName(g)),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : null,
            ),
            selectedColor: visual.color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected ? visual.color : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            onSelected: (_) => onSelected(g),
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ErpItem item;
  final GroupVisual visual;
  final bool expanded;
  final VoidCallback onTap;
  final ValueChanged<double> onClamped;

  const _ItemCard({
    required this.item,
    required this.visual,
    required this.expanded,
    required this.onTap,
    required this.onClamped,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OrderController>();
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final qty = c.qtyOf(item.code);
    final inCart = qty > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius + 4),
          border: Border.all(
            color: inCart
                ? scheme.primary
                : expanded
                    ? visual.color.withValues(alpha: 0.6)
                    : scheme.outlineVariant,
            width: inCart || expanded ? 1.8 : 1,
          ),
          boxShadow: expanded
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Material(
              type: MaterialType.transparency,
              child: InkWell(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius + 4),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: visual.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(visual.icon, color: visual.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.uom.isEmpty
                                ? item.code
                                : '${item.code} · ${item.uom}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (inCart)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '×${formatQty(qty)}',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: expanded
                  ? _Details(item: item, onClamped: onClamped)
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// تفاصيل الصنف المفتوح: السعر والمخزون والكمية والإجمالي.
class _Details extends StatelessWidget {
  final ErpItem item;
  final ValueChanged<double> onClamped;

  const _Details({required this.item, required this.onClamped});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<OrderController>();
    final scheme = Theme.of(context).colorScheme;
    final pricing = c.pricingOf(item.code);

    Widget child;
    if (c.isPricingLoading(item.code) || (pricing == null && c.pricingError(item.code) == null)) {
      child = Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 12),
          Text(AppStrings.loadingPricing),
        ],
      );
    } else if (pricing == null) {
      child = Row(
        children: [
          Icon(Icons.error_outline, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(c.pricingError(item.code)!)),
          TextButton(
            onPressed: () => c.loadPricing(item),
            child: Text(AppStrings.retry),
          ),
        ],
      );
    } else if (!pricing.hasPrice) {
      child = _Notice(
        icon: Icons.sell_outlined,
        title: AppStrings.noPriceTitle,
        message: AppStrings.noPriceMessage,
      );
    } else if (!pricing.inStock) {
      child = _Notice(
        icon: Icons.production_quantity_limits_rounded,
        title: AppStrings.outOfStock,
        message: AppStrings.outOfStockMessage,
      );
    } else {
      child = _Orderable(
        item: item,
        pricing: pricing,
        onClamped: onClamped,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        children: [
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Orderable extends StatelessWidget {
  final ErpItem item;
  final ItemPricing pricing;
  final ValueChanged<double> onClamped;

  const _Orderable({
    required this.item,
    required this.pricing,
    required this.onClamped,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.read<OrderController>();
    final qty = context.select<OrderController, double>(
      (o) => o.qtyOf(item.code),
    );
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final rate = pricing.rate!;
    final left = pricing.available - qty;

    void apply(bool clamped) {
      if (clamped) onClamped(pricing.available);
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.sell_rounded,
                color: scheme.primary,
                label: AppStrings.itemPrice,
                value: formatAmount(
                  rate * c.priceFactor,
                  currency: c.orderCurrency,
                ),
                footer: item.uom.isEmpty ? null : '/ ${item.uom}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoTile(
                icon: Icons.warehouse_rounded,
                color: left <= 0 ? scheme.error : const Color(0xFF2E7D32),
                label: AppStrings.itemStock,
                value: formatQty(pricing.available),
                footer: qty > 0
                    ? AppStrings.afterOrder(formatQty(left))
                    : (item.uom.isEmpty ? null : item.uom),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.quantity,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                QtyControl(
                  qty: qty,
                  max: pricing.available,
                  onIncrement: () => apply(c.increment(item)),
                  onDecrement: () => c.decrement(item),
                  onTyped: (v) => apply(c.setQty(item, v)),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppStrings.lineTotal,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedAmount(
                  value: qty * rate * c.priceFactor,
                  currency: c.orderCurrency,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: qty > 0 ? scheme.primary : scheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? footer;

  const _InfoTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (footer != null)
            Text(
              footer!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _Notice({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onErrorContainer,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
