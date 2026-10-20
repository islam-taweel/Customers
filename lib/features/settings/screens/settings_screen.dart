import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/sync_models.dart';

/// الإعدادات: ثلاثة صناديق للمزامنة (العملاء، الأصناف، الفواتير).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen());

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.settings),
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SyncCard(
            icon: Icons.people_alt_outlined,
            title: AppStrings.syncCustomersTitle,
            description: AppStrings.syncCustomersDesc,
            status: sync.status(SyncSection.customers),
            onSync: sync.syncCustomers,
          ),
          const SizedBox(height: 14),
          _SyncCard(
            icon: Icons.inventory_2_outlined,
            title: AppStrings.syncItemsTitle,
            description: AppStrings.syncItemsDesc,
            status: sync.status(SyncSection.items),
            onSync: sync.syncItems,
          ),
          const SizedBox(height: 14),
          _SyncCard(
            icon: Icons.receipt_long_outlined,
            title: AppStrings.syncInvoicesTitle,
            description: AppStrings.syncInvoicesDesc,
            status: sync.status(SyncSection.invoices),
            onSync: sync.syncInvoices,
            extra: _PendingOrders(
              pending: sync.pendingCount,
              failed: sync.failedCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final SectionStatus status;
  final Future<void> Function() onSync;
  final Widget? extra;

  const _SyncCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onSync,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final lastSync = status.lastSync;
    final info = lastSync == null
        ? AppStrings.neverSynced
        : [
            AppStrings.lastSynced(formatDateTime(lastSync)),
            if (status.summary != null) status.summary!,
          ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (status.running) ...[
            LinearProgressIndicator(
              value: status.progress,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              status.stage ?? AppStrings.syncRunning,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ] else
            Row(
              children: [
                Icon(
                  lastSync == null
                      ? Icons.sync_disabled_outlined
                      : Icons.check_circle_outline,
                  size: 18,
                  color: lastSync == null
                      ? scheme.onSurfaceVariant
                      : scheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          if (status.error != null) ...[
            const SizedBox(height: 8),
            Text(
              status.error!,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
          if (status.warning != null) ...[
            const SizedBox(height: 8),
            Text(
              status.warning!,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
          if (extra != null) ...[
            const SizedBox(height: 10),
            extra!,
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: status.running ? null : onSync,
            icon: const Icon(Icons.sync_rounded),
            label: Text(
              status.running ? AppStrings.syncRunning : AppStrings.syncNow,
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}

/// عدد الطلبيات المحفوظة على الجهاز والتي لم تُرفع بعد.
class _PendingOrders extends StatelessWidget {
  final int pending;
  final int failed;

  const _PendingOrders({required this.pending, required this.failed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (pending == 0 && failed == 0) {
      return Text(
        AppStrings.autoUploadNote,
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (pending > 0)
          Chip(
            avatar: Icon(
              Icons.cloud_upload_outlined,
              size: 18,
              color: scheme.onSecondaryContainer,
            ),
            label: Text(AppStrings.pendingOrdersCount(pending)),
            backgroundColor: scheme.secondaryContainer,
            side: BorderSide.none,
          ),
        if (failed > 0)
          Chip(
            avatar: Icon(
              Icons.error_outline,
              size: 18,
              color: scheme.onErrorContainer,
            ),
            label: Text(AppStrings.failedOrdersCount(failed)),
            backgroundColor: scheme.errorContainer,
            side: BorderSide.none,
          ),
      ],
    );
  }
}
