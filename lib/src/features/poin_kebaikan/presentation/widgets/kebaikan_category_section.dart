import 'package:flutter/material.dart';
import '../../data/poin_kebaikan_data.dart';

/// Widget presentasi untuk satu bagian kategori kebaikan beserta daftar itemnya
class KebaikanCategorySection extends StatelessWidget {
  final KebaikanCategory category;
  final Set<String> selectedItemIds;
  final ValueChanged<String> onItemToggle;

  const KebaikanCategorySection({
    super.key,
    required this.category,
    required this.selectedItemIds,
    required this.onItemToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kategori
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: category.bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(category.icon, color: category.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  category.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: category.color,
                  ),
                ),
                const Spacer(),
                Text(
                  '${category.items.length} kegiatan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: category.color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // Daftar Item Kegiatan
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: category.items.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
            itemBuilder: (ctx, idx) {
              final item = category.items[idx];
              final isChecked = selectedItemIds.contains(item.id);

              return InkWell(
                onTap: () => onItemToggle(item.id),
                child: Container(
                  color: isChecked
                      ? category.bgColor.withValues(alpha: 0.4)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: isChecked,
                          activeColor: category.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (_) => onItemToggle(item.id),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isChecked
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isChecked
                                ? const Color(0xFF111827)
                                : const Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
