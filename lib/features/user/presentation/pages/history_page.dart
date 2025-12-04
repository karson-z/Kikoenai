import 'package:flutter/material.dart';
import 'package:kikoenai/core/service/cache_service.dart';
import 'package:kikoenai/core/model/history_entry.dart';
import 'package:kikoenai/core/storage/hive_box.dart';
import 'package:kikoenai/core/widgets/card/work_card.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoryEntry> historyList = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await CacheService.instance.getHistoryList();
    setState(() {
      historyList = list;
    });
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
      await CacheService.instance.clearBoxFile(BoxNames.history);
      setState(() {
        historyList.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _clearHistory,
        tooltip: '清空历史记录',
        child: const Icon(Icons.delete_forever),
      ),
      body: historyList.isEmpty
          ? const Center(child: Text('暂无历史记录'))
          : LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final spacing = 2.0;

          // 保证至少两列
          final crossAxisCount = (width / 200).floor().clamp(2, 10);

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 0.75,
            ),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final history = historyList[index];
              return WorkCard(
                work: history.work,
                lastTrackTitle: history.currentTrackTitle,
                lastPlayedAt:
                DateTime.fromMillisecondsSinceEpoch(history.updatedAt),
              );
            },
          );
        },
      ),
    );
  }
}
