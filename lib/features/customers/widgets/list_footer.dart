import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';

/// مؤشر تحميل صغير يظهر أسفل القائمة أثناء جلب الدفعة التالية.
class ListFooterLoader extends StatelessWidget {
  const ListFooterLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

/// شريط خطأ أسفل القائمة (عند فشل جلب دفعة تالية) مع زر إعادة المحاولة.
class ListFooterError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ListFooterError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: Text(AppStrings.retry)),
        ],
      ),
    );
  }
}