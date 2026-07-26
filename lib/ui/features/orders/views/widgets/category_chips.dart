import 'package:flutter/material.dart';

import '../../../../../data/repositories/category_repository.dart';

/// Lista horizontal de chips de categoría con estilo Material 3.
class CategoryChips extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final isAll = index == 0;
          final selected = isAll ? selectedId == null : selectedId == categories[index - 1].id;
          final label = isAll ? 'Todas' : categories[index - 1].name;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: ChoiceChip(
              key: ValueKey('${label}_$selected'),
              label: Text(label),
              selected: selected,
              onSelected: (_) => onSelected(isAll ? null : categories[index - 1].id),
              showCheckmark: false,
              avatar: selected
                  ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
                  : null,
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest,
              labelStyle: TextStyle(
                color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: selected ? colorScheme.primary : colorScheme.outlineVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
