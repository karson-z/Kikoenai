import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';

/// 作品浏览布局模式（首页"最新作品" / 分类页共用）。
enum WorkLayoutMode { grid, list }

/// 全局作品浏览布局模式：持久化到 Hive，重启后保持用户选择。
final workLayoutModeProvider = NotifierProvider<WorkLayoutModeNotifier,
    WorkLayoutMode>(WorkLayoutModeNotifier.new);

class WorkLayoutModeNotifier extends Notifier<WorkLayoutMode> {
  @override
  WorkLayoutMode build() {
    final stored = AppStorage.settingsBox.get(StorageKeys.workLayoutMode);
    return stored == 'list' ? WorkLayoutMode.list : WorkLayoutMode.grid;
  }

  void toggle() {
    state = state == WorkLayoutMode.grid
        ? WorkLayoutMode.list
        : WorkLayoutMode.grid;
    // 持久化用户选择
    AppStorage.settingsBox.put(StorageKeys.workLayoutMode, state.name);
  }
}

/// 布局切换按钮：图标展示"将要切换到的模式"，点击切换并持久化。
class WorkLayoutToggleButton extends ConsumerWidget {
  const WorkLayoutToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isListMode = ref.watch(workLayoutModeProvider) ==
        WorkLayoutMode.list;
    // 不指定颜色：跟随当前 IconTheme（默认图标色），
    // 避免在分类页等头部与周边图标（字幕/排序）风格不一致。
    return IconButton(
      tooltip: isListMode ? '切换到卡片网格' : '切换到列表',
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(
        isListMode ? Icons.grid_view_rounded : Icons.view_list_rounded,
      ),
      onPressed: () => ref.read(workLayoutModeProvider.notifier).toggle(),
    );
  }
}
