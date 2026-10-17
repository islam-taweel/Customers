/// خيارات فرز قائمة العملاء.
///
/// كل خيار يحمل جملة `ORDER BY` الخاصة به. القيم ثابتة مكتوبة هنا في الكود
/// (وليست نصًا قادمًا من المستخدم)، فلا خطر حقن SQL عند إدراجها في الاستعلام.
///
/// كل خيار ينتهي بـ `c.id` كمفتاح فرز أخير: عند تساوي القيم يبقى الترتيب ثابتًا
/// بين صفحة وأخرى، وإلا قد يتكرر عميل أو يضيع عند الـ Pagination.
enum CustomerSortOption {
  /// حسب الاسم أبجديًا
  name('c.name COLLATE NOCASE ASC, c.id ASC'),

  /// الأحدث أولًا. الـ id من نوع AUTOINCREMENT فكلما كبر كان العميل أحدث.
  newest('c.id DESC'),

  /// الأعلى ديونًا أولًا (balance هو الاسم المستعار للرصيد في الاستعلام)
  highestDebt('balance DESC, c.name COLLATE NOCASE ASC, c.id ASC');

  const CustomerSortOption(this.orderBy);

  /// المقطع الذي يأتي بعد `ORDER BY`
  final String orderBy;
}
