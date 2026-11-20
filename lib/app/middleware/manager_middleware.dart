import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../modules/hr/shared/hr_approver_access.dart';
import '../routes/app_routes.dart';

/// مسار للمعتمِدين فقط (Leave Approver أو Expense Approver، من أدوار ERPNext).
///
/// يُوضع بعد [AuthMiddleware] في GetPage. صلاحية المعتمِد تُفحص من الخادم عند
/// فتح قسم الموارد البشرية (HrAccessController) وتُحفظ في [HrApproverAccess]؛
/// بلا صلاحية معروفة (غير معتمِد، أو لم تُفحص بعد) يُحوَّل إلى مدخل القسم الذي
/// يفحصها. لا يعتمد على إخفاء الزر وحده، ولا يغيّر نظام الصلاحيات في ERPNext.
class ManagerMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      Get.find<HrApproverAccess>().canSeeTeam
      ? null
      : const RouteSettings(name: Routes.hr);
}
