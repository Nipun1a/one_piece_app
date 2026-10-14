import 'package:flutter/material.dart';

import '../providers/product_provider.dart';

/// A horizontally scrollable row of [ChoiceChip] widgets for filtering
/// products by category.
class CategoryChipBar extends StatelessWidget {
  final String selectedCategory;
  final void Function(String) onSelected;

  const CategoryChipBar({
    required this.selectedCategory,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ProductProvider.categories.map((label) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: selectedCategory == label,
              onSelected: (v) {
                if (v) onSelected(label);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
