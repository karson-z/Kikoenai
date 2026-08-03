import 'package:flutter/material.dart';
import 'package:kikoenai_core/core/model/history/history_entry.dart';

class HistoryHorizontalSection extends StatelessWidget {
  const HistoryHorizontalSection({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    this.onMoreTap,
  });

  final String title;

  final List<HistoryEntry> items;

  final Widget Function(BuildContext context, HistoryEntry entry) itemBuilder;

  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (onMoreTap != null)
                InkWell(
                  onTap: onMoreTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        /// Horizontal List
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0) const SizedBox(width: 14),
                  itemBuilder(context, items[index]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
