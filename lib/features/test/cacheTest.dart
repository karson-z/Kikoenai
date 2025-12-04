import 'package:flutter/material.dart';
import 'package:kikoenai/core/service/cache_service.dart';
import 'package:kikoenai/core/model/history_entry.dart';
import 'package:kikoenai/core/widgets/card/work_card.dart';

class HistoryTestPage extends StatefulWidget {
  const HistoryTestPage({super.key});

  @override
  _HistoryTestPageState createState() => _HistoryTestPageState();
}

class _HistoryTestPageState extends State<HistoryTestPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录网格布局'),
      ),
      body: historyList.isEmpty
          ? const Center(child: Text('暂无历史记录'))
          : LayoutBuilder(
        builder: (context, constraints) {
          // 根据屏幕宽度计算列数
          final width = constraints.maxWidth;
          final crossAxisCount = (width / 200).floor(); // 每个卡片最大 200 px
          const spacing = 8.0;

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
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
                lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(history.updatedAt),
              );
            },
          );
        },
      ),
    );
  }
}
