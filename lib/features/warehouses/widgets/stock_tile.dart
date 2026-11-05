import 'package:flutter/material.dart';

import '../../../core/constants/warehouse_strings.dart';
import '../../../data/models/warehouse_models.dart';

/// صنف في مستودع: الاسم والرمز، ثم الموجود والمحجوز والمتاح بوحدة المخزون.
class StockTile extends StatelessWidget {
  final WarehouseStock stock;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  const StockTile({
    super.key,
    required this.stock,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = stock;

    Widget figure(String label, double v, Color color) => Padding(
          padding: const EdgeInsetsDirectional.only(end: 14),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                TextSpan(
                  text: WarehouseStrings.qty(v, s.uom),
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
            style: theme.textTheme.bodySmall,
          ),
        );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? scheme.secondaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.itemName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      s.itemGroup.isEmpty
                          ? s.itemCode
                          : '${s.itemCode}  •  ${s.itemGroup}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      runSpacing: 2,
                      children: [
                        figure(WarehouseStrings.actual, s.actualQty,
                            scheme.onSurface),
                        if (s.reservedQty > 0)
                          figure(WarehouseStrings.reserved, s.reservedQty,
                              scheme.tertiary),
                        figure(WarehouseStrings.available, s.availableQty,
                            s.availableQty > 0 ? scheme.primary : scheme.error),
                      ],
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
