import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/ess_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/api/erp_api_client.dart';
import '../../../data/models/employee_models.dart';
import '../../../data/repositories/erp_employee_repository.dart';
import '../employee_service.dart';

/// حسابي: بيانات الموظف المرتبط بالمستخدم الحالي من ERPNext — الصورة والاسم
/// والرقم الوظيفي والقسم والمسمى والبريد والهاتف، ثم الوردية ووقتا الدوام.
class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  late Future<EmployeeProfile> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<ErpEmployeeRepository>().fetchProfile();
  }

  String _message(Object e) {
    if (e is EmployeeNotLinkedException) return EssStrings.notLinked;
    if (e is ErpApiException && e.type == ErpErrorType.forbidden) {
      return EssStrings.noPermission;
    }
    return describeError(e, fallback: EssStrings.profileLoadFailed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(EmployeeService.profile.title)),
      body: FutureBuilder<EmployeeProfile>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return LoadingView(message: EssStrings.loadingProfile);
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: _message(snapshot.error!),
              onRetry: () => setState(_load),
            );
          }
          final p = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(_load);
              await _future.then((_) {}, onError: (_) {});
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _Header(profile: p),
                const SizedBox(height: 16),
                _Section(
                  title: EssStrings.jobInfo,
                  icon: Icons.work_outline,
                  children: [
                    _Row(Icons.tag, EssStrings.employeeId, p.id, ltr: true),
                    _Row(Icons.apartment_outlined, EssStrings.department,
                        p.department),
                    _Row(Icons.badge_outlined, EssStrings.designation,
                        p.designation),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: EssStrings.contactInfo,
                  icon: Icons.contact_mail_outlined,
                  children: [
                    _Row(Icons.email_outlined, EssStrings.email, p.email,
                        ltr: true),
                    _Row(Icons.phone_outlined, EssStrings.phone, p.phone,
                        ltr: true),
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
class _Header extends StatefulWidget {
  final EmployeeProfile profile;

  const _Header({required this.profile});

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  Future<Uint8List>? _image;

  @override
  void initState() {
    super.initState();
    final path = widget.profile.image;
    if (path.isNotEmpty) {
      _image = context.read<ErpEmployeeRepository>().fetchImage(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = widget.profile;

    final placeholder = Icon(Icons.person, size: 52, color: scheme.onPrimary);
    final avatar = CircleAvatar(
      radius: 44,
      backgroundColor: scheme.onPrimary.withValues(alpha: 0.2),
      child: ClipOval(
        child: SizedBox(
          width: 88,
          height: 88,
          child: _image == null
              ? placeholder
              : FutureBuilder<Uint8List>(
                  future: _image,
                  builder: (_, snap) => snap.hasData
                      ? Image.memory(
                          snap.data!,
                          fit: BoxFit.cover,
                          // ملف ليس صورة: الأيقونة بدلًا منه
                          errorBuilder: (_, _, _) => placeholder,
                        )
                      : placeholder,
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
              style: TextStyle(
                color: scheme.onPrimary.withValues(alpha: 0.85),
              ),
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
