import 'package:flutter/material.dart';

/// أيقونة ولون لكل مجموعة أصناف معروفة (غير المعروفة تأخذ أيقونة عامة).
class GroupVisual {
  final IconData icon;
  final Color color;
  const GroupVisual(this.icon, this.color);

  static GroupVisual of(String group) => switch (group) {
        'Electrical' => const GroupVisual(
            Icons.electrical_services_rounded,
            Color(0xFFF9A825),
          ),
        'Hand Tools' => const GroupVisual(
            Icons.handyman_rounded,
            Color(0xFF8D6E63),
          ),
        'Plumbing' => const GroupVisual(
            Icons.plumbing_rounded,
            Color(0xFF1E88E5),
          ),
        'Power Tools' => const GroupVisual(
            Icons.construction_rounded,
            Color(0xFFE64A19),
          ),
        'Consumable' => const GroupVisual(
            Icons.inventory_rounded,
            Color(0xFF43A047),
          ),
        'Raw Material' => const GroupVisual(
            Icons.layers_rounded,
            Color(0xFF6D4C41),
          ),
        'Services' => const GroupVisual(
            Icons.miscellaneous_services_rounded,
            Color(0xFF5E35B1),
          ),
        'Sub Assemblies' => const GroupVisual(
            Icons.settings_suggest_rounded,
            Color(0xFF00897B),
          ),
        'Products' => const GroupVisual(
            Icons.category_rounded,
            Color(0xFFD81B60),
          ),
        _ => const GroupVisual(Icons.folder_rounded, Color(0xFF546E7A)),
      };
}
