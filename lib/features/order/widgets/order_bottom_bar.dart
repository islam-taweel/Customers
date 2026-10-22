import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../controllers/order_controller.dart';
import 'animated_amount.dart';

/// الشريط السفلي: الإجمالي الحي (إن وُجدت أصناف) وأزرار رجوع/التالي/إرسال.
class OrderBottomBar extends StatelessWidget {
  final OrderController controller;

  const OrderBottomBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final step = c.step;
    final isInvoice = step == OrderStep.invoice;
    final showTotal = step != OrderStep.customer && c.hasLines;

    return Material(
      color: scheme.surface,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (c.submitError != null) ...[
                _ErrorBanner(
                  message: c.submitError!,
                  onClose: c.clearSubmitError,
                ),
                const SizedBox(height: 10),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: showTotal
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Badge.count(
                                count: c.lineCount,
                                child: Icon(
                                  Icons.shopping_basket_rounded,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppStrings.orderTotal,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            AnimatedAmount(
                              value: c.total,
                              currency: c.orderCurrency,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              Row(
                children: [
                  if (step != OrderStep.customer) ...[
                    OutlinedButton.icon(
                      onPressed: c.submitting ? null : c.back,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(AppStrings.back),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: isInvoice
                        ? FilledButton.icon(
                            onPressed: c.submitting || !c.hasLines
                                ? null
                                : c.submit,
                            icon: c.submitting
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: scheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(
                              c.submitting
                                  ? AppStrings.submittingOrder
                                  : AppStrings.submitOrder,
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          )
                        : FilledButton(
                            onPressed: c.canGoNext ? c.next : null,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(AppStrings.next),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ErrorBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline, color: scheme.onErrorContainer),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 96),
              child: SingleChildScrollView(
                child: Text(
                  message,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, color: scheme.onErrorContainer),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
