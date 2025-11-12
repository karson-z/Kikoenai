import 'package:flutter/material.dart';

class AlbumHeader extends StatelessWidget {
  final String title;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const AlbumHeader({
    super.key,
    required this.title,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButton<String>(
              value: selectedFilter,
              underline: const SizedBox.shrink(),
              items: filters
                  .map(
                    (filter) => DropdownMenuItem(
                      value: filter,
                      child: Text(filter),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onFilterChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
