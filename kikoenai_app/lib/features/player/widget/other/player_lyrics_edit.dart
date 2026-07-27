import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../../../core/widgets/common/back_button_interceptor.dart';
import '../../provider/player_lyrics_provider.dart';

/// 构建字幕样式配置的页面
/// 构建字幕样式配置的页面
SliverWoltModalSheetPage buildLyricsStylePage(BuildContext context) {
  return SliverWoltModalSheetPage(
    isTopBarLayerAlwaysVisible: true,
    pageTitle: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        "字幕样式",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    // 修复 1：使用 Builder 获取局部上下文，并使用 removePage() 彻底移除本页
    leadingNavBarWidget: Builder(
      builder: (navContext) => Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            WoltModalSheet.of(navContext).popPage();
          },
        ),
      ),
    ),
    mainContentSliversBuilder: (builderContext) => [
      const SliverPadding(padding: EdgeInsets.only(top: 16)),
      const SliverToBoxAdapter(
        child: BackButtonPriorityWrapper(
          zIndex: 101, // 层级必须大于第一页的 100
          name: 'LyricsConfigPageBackInterceptor',
          child: _LyricsStyleConfigContent(),
        ),
      ),
      const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
    ],
  );
}

/// 字幕样式配置的内容组件，连接 Riverpod
class _LyricsStyleConfigContent extends ConsumerWidget {
  const _LyricsStyleConfigContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(lyricConfigProvider);
    final notifier = ref.read(lyricConfigProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSliderRow(
          title: "主文本大小",
          value: config.mainFontSize,
          min: 12.0,
          max: 48.0,
          onChanged: notifier.updateMainFontSize,
        ),
        _buildSliderRow(
          title: "翻译文本大小",
          value: config.transFontSize,
          min: 10.0,
          max: 36.0,
          onChanged: notifier.updateTransFontSize,
        ),
        _buildSliderRow(
          title: "高亮放大尺寸",
          value: config.activeFontSize,
          min: 14.0,
          max: 56.0,
          onChanged: notifier.updateActiveFontSize,
        ),
        const Divider(height: 32),
        _buildSliderRow(
          title: "行间距",
          value: config.lineGap,
          min: 0.0,
          max: 48.0,
          onChanged: notifier.updateLineGap,
        ),
        _buildSliderRow(
          title: "主副歌词间距",
          value: config.translationGap,
          min: 0.0,
          max: 32.0,
          onChanged: notifier.updateTransGap,
        ),
        const SizedBox(height: 16),

        // 新增：恢复默认配置按钮
        Center(
          child: FilledButton.tonalIcon(
            icon: const Icon(Icons.settings_backup_restore_rounded),
            label: const Text("恢复默认设置"),
            onPressed: () {
              notifier.resetToDefault();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}