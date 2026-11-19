import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../home/employee_service.dart';
import '../../shared/models/employee_models.dart';
import '../controllers/profile_controller.dart';

/// حسابي: بيانات الموظف المرتبط بالمستخدم الحالي من ERPNext — الصورة والاسم
/// والرقم الوظيفي والقسم والمسمى والبريد والهاتف، ثم الوردية ووقتا الدوام.
///
/// (R5) الحالة في [ProfileController] (StateMixin): الواجهة تعرض فقط.
class MyAccountScreen extends GetView<ProfileController> {
  const MyAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(EmployeeService.profile.title)),
      body: controller.obx(
        onLoading: LoadingView(message: EssStrings.loadingProfile),
        onError: (message) =>
            ErrorView(message: message!, onRetry: controller.load),
        (data) {
          final p = data!;
          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _Header(profile: p, image: controller.image),
                const SizedBox(height: 16),
                _Section(
                  title: EssStrings.jobInfo,
                  icon: Icons.work_outline,
                  children: [
                    _Row(Icons.tag, EssStrings.employeeId, p.id, ltr: true),
                    _Row(
                      Icons.apartment_outlined,
                      EssStrings.department,
                      p.department,
                    ),
                    _Row(
                      Icons.badge_outlined,
                      EssStrings.designation,
                      p.designation,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: EssStrings.contactInfo,
                  icon: Icons.contact_mail_outlined,
                  children: [
                    _Row(
                      Icons.email_outlined,
                      EssStrings.email,
                      p.email,
                      ltr: true,
                    ),
                    _Row(
                      Icons.phone_outlined,
                      EssStrings.phone,
                      p.phone,
                      ltr: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ShiftSection(shift: p.shift),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// الصورة (أو أيقونة) والاسم والمسمى
class _Header extends StatelessWidget {
  final EmployeeProfile profile;

  /// تُحمَّل في ProfileController بعد البيانات (null = الأيقونة)
  final Rxn<Uint8List> image;

  const _Header({required this.profile, required this.image});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = profile;

    final placeholder = Icon(Icons.person, size: 52, color: scheme.onPrimary);
    final avatar = CircleAvatar(
      radius: 44,
      backgroundColor: scheme.onPrimary.withValues(alpha: 0.2),
      child: ClipOval(
        child: SizedBox(
          width: 88,
          height: 88,
          child: Obx(
            () => image.value == null
                ? placeholder
                : Image.memory(
                    image.value!,
                    fit: BoxFit.cover,
                    // ملف ليس صورة: الأيقونة بدلًا منه
                    errorBuilder: (_, _, _) => placeholder,
                  ),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          avatar,
          const SizedBox(height: 12),
          Text(
            p.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (p.designation.isNotEmpty)
            Text(
              p.designation,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.85)),
            ),
        ],
      ),
    );
  }
}

class _ShiftSection extends StatelessWidget {
  final EmployeeShift? shift;

  const _ShiftSection({required this.shift});

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    String time(String raw) {
      final parts = raw.split(':');
      final h = int.tryParse(parts.first);
      final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
      if (h == null || m == null) return raw;
      return loc.formatTimeOfDay(TimeOfDay(hour: h % 24, minute: m));
    }

    final s = shift;
    return _Section(
      title: EssStrings.shiftInfo,
      icon: Icons.schedule,
      children: s == null
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(EssStrings.noShift),
              ),
            ]
          : [
              _Row(Icons.label_outline, EssStrings.shiftName, s.name),
              _Row(Icons.login, EssStrings.shiftStart, time(s.startTime)),
              _Row(Icons.logout, EssStrings.shiftEnd, time(s.endTime)),
            ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool ltr;

  const _Row(this.icon, this.label, this.value, {this.ltr = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final empty = value.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              empty ? EssStrings.notSet : value,
              // طرف السطر حسب لغة الواجهة، حتى للقيم اللاتينية (البريد والهاتف)
              textAlign: Directionality.of(context) == TextDirection.rtl
                  ? TextAlign.left
                  : TextAlign.right,
              textDirection: ltr && !empty ? TextDirection.ltr : null,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: empty ? scheme.outline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
