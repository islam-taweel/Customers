import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/models/customer_with_balance.dart';
import '../../../data/repositories/outstanding_repository.dart';
import 'customer_tile.dart';

/// بطاقة عميل يمكن سحبها من أي جانب لحذفها.
///
/// - المفتاح `ValueKey(customer.id)` يعطي كل بطاقة هوية ثابتة، فلا تنتقل حالة
///   بطاقة محذوفة إلى جارتها.
/// - [confirmDelete] يُستدعى قبل الحذف (نافذة تأكيد)؛ إن أرجع false تعود البطاقة
///   إلى مكانها ويبقى العميل.
/// - [onDelete] يُستدعى بعد الموافقة وانتهاء حركة السحب.
class DismissibleCustomerTile extends StatelessWidget {
  final CustomerWithBalance item;

  /// مستحق العميل من ERPNext لكل عملة (null = غير متاح)
  final List<CurrencyAmount>? outstanding;
  final VoidCallback onTap;
  final Future<bool> Function() confirmDelete;
  final VoidCallback onDelete;

  const DismissibleCustomerTile({
    super.key,
    required this.item,
    required this.outstanding,
    required this.onTap,
    required this.confirmDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.customer.id),
      // اتجاه السحب مرتبط بلغة الواجهة (start/end) فيعمل في RTL كما في LTR
      background: const _DeleteBackground(alignment: AlignmentDirectional.centerStart),
      secondaryBackground:
          const _DeleteBackground(alignment: AlignmentDirectional.centerEnd),
      confirmDismiss: (_) => confirmDelete(),
      onDismissed: (_) => onDelete(),
      child: CustomerTile(item: item, outstanding: outstanding, onTap: onTap),
    );
  }
}

/// الخلفية الحمراء التي تظهر خلف البطاقة أثناء السحب.
class _DeleteBackground extends StatelessWidget {
  final AlignmentGeometry alignment;

  const _DeleteBackground({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.error,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: scheme.onError),
          const SizedBox(width: 8),
          Text(
            AppStrings.delete,
            style: TextStyle(color: scheme.onError, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}