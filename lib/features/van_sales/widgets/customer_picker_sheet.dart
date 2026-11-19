import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/van_strings.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../data/models/erp_customer.dart';

/// اختيار عميل من ERPNext مع البحث (بالاسم أو الرقم أو الهاتف). يعيد العميل
/// المختار. يعمل مع أي متحكم GetX فيه قائمة العملاء وحالة تحميلها.
class CustomerPickerSheet extends StatefulWidget {
  final RxList<ErpCustomer> customers;
  final RxBool loading;
  final Rxn<Object> error;
  final List<ErpCustomer> Function(String query) filter;
  final Future<void> Function() onRetry;
  final String? selectedId;

  const CustomerPickerSheet({
    super.key,
    required this.customers,
    required this.loading,
    required this.error,
    required this.filter,
    required this.onRetry,
    this.selectedId,
  });

  static Future<ErpCustomer?> show(
    BuildContext context, {
    required RxList<ErpCustomer> customers,
    required RxBool loading,
    required Rxn<Object> error,
    required List<ErpCustomer> Function(String query) filter,
    required Future<void> Function() onRetry,
    String? selectedId,
  }) => showModalBottomSheet<ErpCustomer>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CustomerPickerSheet(
      customers: customers,
      loading: loading,
      error: error,
      filter: filter,
      onRetry: onRetry,
      selectedId: selectedId,
    ),
  );

  @override
  State<CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<CustomerPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: VanStrings.searchCustomer,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final all = widget.customers;
              final list = widget.filter(_query);
              if (widget.loading.value && all.isEmpty) {
                return LoadingView(message: VanStrings.loadingCustomers);
              }
              final error = widget.error.value;
              if (error != null && all.isEmpty) {
                return ErrorView(
                  message: describeError(
                    error,
                    fallback: VanStrings.customersFailed,
                  ),
                  onRetry: widget.onRetry,
                );
              }
              if (list.isEmpty) {
                return Center(child: Text(VanStrings.noCustomers));
              }
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final cu = list[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        cu.name.isEmpty ? '?' : cu.name.characters.first,
                      ),
                    ),
                    title: Text(cu.name),
                    subtitle: Text(
                      cu.phone.isEmpty ? cu.id : '${cu.id}  •  ${cu.phone}',
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                    ),
                    selected: cu.id == widget.selectedId,
                    onTap: () => Navigator.of(context).pop(cu),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
