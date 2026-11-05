import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../data/models/sync_models.dart';

/// الإعدادات: المظهر (الثيم)، ثم حالة المزامنة التلقائية لكل قسم
/// (العملاء، الأصناف، الفواتير). لا يوجد زر مزامنة: تتم وحدها ما دام الاتصال متاحًا.
class SettingsScreen extends StatelessWidget {
  /// داخل الشريط السفلي: تظهر القائمة الجانبية بدل زر الرجوع
  final bool inShell;

  const SettingsScreen({super.key, this.inShell = false});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen());

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();

    return Scaffold(
      drawer: inShell ? const AppDrawer() : null,
      appBar: AppBar(
        title: Text(AppStrings.settings),
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _AppearanceCard(),
          const SizedBox(height: 14),
          // المزامنة تلقائية بالكامل: لا أزرار، فقط حالتها
          _AutoSyncBanner(online: sync.online, syncing: sync.syncingAll),
          const SizedBox(height: 14),
          _SyncCard(
            icon: Icons.people_alt_outlined,
            title: AppStrings.syncCustomersTitle,
            description: AppStrings.syncCustomersDesc,
            status: sync.status(SyncSection.customers),
          ),
          const SizedBox(height: 14),
          _SyncCard(
            icon: Icons.inventory_2_outlined,
            title: AppStrings.syncItemsTitle,
            description: AppStrings.syncItemsDesc,
            status: sync.status(SyncSection.items),
          ),
          const SizedBox(height: 14),
          _SyncCard(
            icon: Icons.receipt_long_outlined,
            title: AppStrings.syncInvoicesTitle,
            description: AppStrings.syncInvoicesDesc,
            status: sync.status(SyncSection.invoices),
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

/// المظهر: داكن (بنفسجي) / فاتح (سماوي) / مخصص، ولألوان «مخصص» مربعات للاختيار.
class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                child: Icon(
                  Icons.palette_outlined,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.appearanceTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.appearanceDesc,
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
          SegmentedButton<AppThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: AppThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined),
                label: Text(AppStrings.themeDark),
              ),
              ButtonSegment(
                value: AppThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined),
                label: Text(AppStrings.themeLight),
              ),
              ButtonSegment(
                value: AppThemeMode.custom,
                icon: const Icon(Icons.color_lens_outlined),
                label: Text(AppStrings.themeCustom),
              ),
            ],
            selected: {controller.mode},
            onSelectionChanged: (s) => controller.setMode(s.first),
          ),
          if (controller.mode == AppThemeMode.custom) ...[
            const SizedBox(height: 14),
            Text(
              AppStrings.themeChooseColor,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in ThemeColor.customChoices)
                  _ColorSwatch(
                    color: c,
                    selected: controller.customColor == c,
                    onTap: () => controller.setCustomColor(c),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final ThemeColor color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = AppStrings.themeColorName(color.name);

    return Tooltip(
      message: name,
      child: Semantics(
        button: true,
        selected: selected,
        label: name,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? scheme.onSurface : Colors.transparent,
                width: 3,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

/// شريط حالة المزامنة التلقائية: جارية الآن، أو بانتظار الاتصال، أو محدّثة.
class _AutoSyncBanner extends StatelessWidget {
  final bool? online;
  final bool syncing;

  const _AutoSyncBanner({required this.online, required this.syncing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final offline = online == false;
    final (IconData icon, String text, Color bg, Color fg) = syncing
        ? (
            Icons.sync_rounded,
            AppStrings.autoSyncRunning,
            scheme.secondaryContainer,
            scheme.onSecondaryContainer,
          )
        : offline
            ? (
                Icons.cloud_off_outlined,
                AppStrings.autoSyncOffline,
                scheme.errorContainer,
                scheme.onErrorContainer,
              )
            : (
                Icons.cloud_done_outlined,
                AppStrings.autoSyncOnline,
                scheme.primaryContainer,
                scheme.onPrimaryContainer,
              );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (syncing)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else
            Icon(icon, color: fg, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: fg),
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
  final Widget? extra;

  const _SyncCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
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
