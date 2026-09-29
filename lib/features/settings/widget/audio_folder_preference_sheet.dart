import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/service/file/audio_folder_preference.dart';

/// 详情页文件区的两张偏好表：音频格式和音效。
class AudioFolderPreferenceSheet extends StatefulWidget {
  const AudioFolderPreferenceSheet({super.key, required this.settingsBox});

  final Box<dynamic> settingsBox;

  @override
  State<AudioFolderPreferenceSheet> createState() =>
      _AudioFolderPreferenceSheetState();
}

class _AudioFolderPreferenceSheetState
    extends State<AudioFolderPreferenceSheet> {
  late AudioFolderPreference _preference;

  @override
  void initState() {
    super.initState();
    _preference = AudioFolderPreference.fromStorage(widget.settingsBox);
  }

  Future<void> _save(AudioFolderPreference preference) async {
    setState(() => _preference = preference);
    await preference.save(widget.settingsBox);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text('音频类型偏好', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            '进入作品详情时，按这两张表落到对应文件夹。拖动调整优先级。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _PreferenceTable<String>(
            title: '音频格式',
            items: _preference.formats,
            labelOf: (format) => format,
            onReorder: (formats) => _save(
              AudioFolderPreference(
                formats: formats,
                effects: _preference.effects,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _PreferenceTable<AudioEffectPreference>(
            title: '音效',
            items: _preference.effects,
            labelOf: (effect) => effect.label,
            onReorder: (effects) => _save(
              AudioFolderPreference(
                formats: _preference.formats,
                effects: effects,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceTable<T> extends StatelessWidget {
  const _PreferenceTable({
    required this.title,
    required this.items,
    required this.labelOf,
    required this.onReorder,
  });

  final String title;
  final List<T> items;
  final String Function(T item) labelOf;
  final ValueChanged<List<T>> onReorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Material(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: items.length,
            onReorderItem: (oldIndex, newIndex) {
              final next = [...items];
              final moved = next.removeAt(oldIndex);
              next.insert(newIndex, moved);
              onReorder(next);
            },
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                key: ValueKey(item),
                leading: Text(
                  '${index + 1}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(labelOf(item)),
                trailing: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
