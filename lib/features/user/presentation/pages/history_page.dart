import 'package:flutter/material.dart';
import 'package:kikoenai/core/model/history_entry.dart';
import 'package:kikoenai/core/widgets/card/work_card.dart';
import '../../../../core/service/cache/cache_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // 缓存列表数据
  List<HistoryEntry> historyList = [];
  final CacheService _cacheService = CacheService.instance;

  @override
  void initState() {
    super.initState();
    // 1. 初始化时直接同步读取，不需要 await
    _loadHistory();
  }

  /// 同步加载历史记录
  void _loadHistory() {
    final list = _cacheService.getHistoryList();
    if (mounted) {
      setState(() {
        historyList = list;
      });
    }
  }

  /// 清空历史记录
  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史记录'),
        content: const Text('确定要清空所有历史记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 2. 调用 Service 的清理方法
      await _cacheService.clearHistory();

      if (mounted) {
        setState(() {
          historyList.clear(); // 清空 UI 列表
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 3. 将 FAB 放在 Scaffold 中
      floatingActionButton: historyList.isNotEmpty
          ? FloatingActionButton(
        onPressed: _clearHistory,
        tooltip: '清空历史记录',
        child: const Icon(Icons.delete_forever),
      )
          : null, // 没数据时不显示删除按钮

      body: historyList.isEmpty
          ? const Center(child: Text('暂无历史记录'))
          : LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const spacing = 8.0; // 稍微增加一点间距美观度

          // 动态计算列数：最小宽度 160，防止卡片太挤
          final crossAxisCount = (width / 160).floor().clamp(2, 6);

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 0.75, // 调整比例适配封面图
            ),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final history = historyList[index];
              return WorkCard(
                work: history.work,
                // 如果有进度，可以显示具体进度信息
                lastTrackTitle: history.currentTrackTitle,
                lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(
                  history.updatedAt,
                ),
                // 可以在这里加点击事件跳转播放
                // onTap: () => PlayerController.restoreHistory(...)
              );
            },
          );
        },
      ),
    );
  }
}