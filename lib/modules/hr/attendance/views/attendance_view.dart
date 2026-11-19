import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/ess_strings.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../home/employee_service.dart';
import '../../shared/widgets/month_year_picker.dart';
import '../controllers/attendance_controller.dart';
import '../models/attendance_models.dart';
import '../widgets/attendance_widgets.dart';

/// سجل حضوري من ERPNext (Attendance المعتمد): اختيار الشهر والسنة، ملخص الشهر
/// (الحضور والغياب والتأخير وساعات العمل)، ثم سجل كل يوم الأحدث أولًا.
///
/// (R5) الحالة في [AttendanceController] (StateMixin: loading/error/empty/success)؛
/// الواجهة تعرض فقط. «لا سجلات» يعرض الملخص (أصفار) ورسالة الفراغ كما كان.
class AttendanceLogScreen extends GetView<AttendanceController> {
  const AttendanceLogScreen({super.key});

  Widget _list(List<AttendanceRecord> records) => RefreshIndicator(
    onRefresh: controller.load,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        SummaryGrid(summary: controller.summary),
        const SizedBox(height: 16),
        if (records.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: EmptyView(
              icon: Icons.event_busy_outlined,
              title: EssStrings.noAttendance,
              message: EssStrings.noAttendanceHint,
            ),
          )
        else
          for (final r in records) RecordCard(record: r),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(EmployeeService.attendance.title)),
      body: Column(
        children: [
          Obx(
            () => MonthYearPicker(
              year: controller.year.value,
              month: controller.month.value,
              onChanged: controller.setPeriod,
            ),
          ),
          Expanded(
            child: controller.obx(
              (records) => _list(records ?? const []),
              onLoading: LoadingView(message: EssStrings.loadingAttendance),
              onEmpty: _list(const []),
              onError: (message) =>
                  ErrorView(message: message!, onRetry: controller.load),
            ),
          ),
        ],
      ),
    );
  }
}
