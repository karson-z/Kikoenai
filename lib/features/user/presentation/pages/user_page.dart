import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/local_media/presentation/page/scanner_page.dart';
import 'package:kikoenai/features/marked/presentation/page/review_page.dart';
import 'package:kikoenai/features/playlist/presentation/page/playlist_page.dart';
import '../../../download/presentation/page/download_page.dart';
import 'history_page.dart';

class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  ConsumerState<UserPage> createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage>
    with SingleTickerProviderStateMixin {
  final tabs = const ["观看历史", "本地媒体","我的收藏","播放列表","下载列表"];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: TabBar(
            tabAlignment: TabAlignment.start,
            controller: _tabController,
            isScrollable: true,
            tabs: tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        body:TabBarView(
          controller: _tabController,
          children: [
            // 第一个 Tab 页面：观看历史
            const HistoryPage(),
            const ScannerPage(),
            const ReviewPage(),
            const PlaylistPage(),
            const RiverpodDownloadPage(),
          ],
        ),
      ),
    );
  }
}
