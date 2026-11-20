import 'package:get/get.dart';

import '../../../app/services/session_service.dart';

/// آخر صلاحية معتمِد (Leave/Expense Approver) عرفها التطبيق من أدوار ERPNext.
///
/// يقرؤها [ManagerMiddleware] (متزامن) لحماية مسار «فريقي»، ويكتبها
/// HrAccessController وTeamController بعد فحص الخادم. غير معروفة (لم تُفحص بعد)
/// = لا صلاحية. تُمسح عند انتهاء الجلسة أو الخروج، فلا تنتقل بين مستخدمين.
/// الخادم يبقى المرجع: TeamController يعيد الفحص عند كل فتح، وطلبات الفريق
/// تُفلتر على الخادم بـ leave_approver / expense_approver.
class HrApproverAccess extends GetxService {
  HrApproverAccess(this._session);

  final SessionService _session;

  final canApproveLeaves = false.obs;
  final canApproveExpenses = false.obs;

  bool get canSeeTeam => canApproveLeaves.value || canApproveExpenses.value;

  @override
  void onInit() {
    super.onInit();
    ever<bool>(_session.isAuthenticated, (signedIn) {
      if (!signedIn) clear();
    });
  }

  void update({required bool leaves, required bool expenses}) {
    canApproveLeaves.value = leaves;
    canApproveExpenses.value = expenses;
  }

  void clear() => update(leaves: false, expenses: false);
}
