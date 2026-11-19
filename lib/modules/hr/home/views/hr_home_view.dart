import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/ess_strings.dart';
import '../../../../features/auth/controllers/auth_controller.dart';
import '../bindings/hr_home_binding.dart';
import '../controllers/hr_access_controller.dart';
import '../employee_service.dart';

/// قسم «خدمات الموظف»: رأس باسم المستخدم، ثم بطاقة لكل خدمة (أيقونة وعنوان
/// ووصف قصير). الضغط على البطاقة يفتح شاشة الخدمة. صلاحيات المستخدم تُفحص عند
/// فتح القسم: «فريقي» يظهر فقط لمعتمِدي الإجازات أو المصاريف.
///
/// (R5) الصلاحيات في [HrAccessController] (HrHomeBinding)، والانتقال إلى كل خدمة
/// بـ Get.toNamed(service.routeName).
class EmployeeServicesScreen extends GetView<HrAccessController> {
  const EmployeeServicesScreen({super.key});

  /// نفس الواجهة القديمة (القائمة الجانبية تستدعيها)، بمسار GetX يربط المتحكم
  /// بعمر الشاشة.
  static Route<void> route() => GetPageRoute<void>(
    settings: const RouteSettings(name: Routes.hr),
    page: () => const EmployeeServicesScreen(),
    binding: HrHomeBinding(),
    transition: Transition.native,
  );

  @override
  Widget build(BuildContext context) {
    final access = controller;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = context.select<AuthController, String?>((a) => a.fullName);
    // عمودان في الهاتف، وأكثر في الشاشات العريضة
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900
        ? 4
        : width >= 600
        ? 3
        : 2;

    return Scaffold(
      appBar: AppBar(title: Text(EssStrings.section)),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.tertiary],
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: scheme.onPrimary.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.person_outline,
                        size: 30,
                        color: scheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (name == null || name.isEmpty)
                                ? EssStrings.section
                                : name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            EssStrings.intro,
                            style: TextStyle(
                              color: scheme.onPrimary.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: Obx(
              () => SliverGrid.count(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  for (final s in EmployeeService.values)
                    // «فريقي» لا يظهر نهائيًا لمن لا يملك صلاحية الموافقة
                    if (s != EmployeeService.team || access.canSeeTeam)
                      _ServiceCard(service: s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final EmployeeService service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = service.color(scheme);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.toNamed(service.routeName),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(service.icon, color: color, size: 26),
              ),
              const Spacer(),
              Text(
                service.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                service.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
