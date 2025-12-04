import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/common/login_dialog_manager.dart';
import '../../../../core/theme/theme_view_model.dart';
import '../../../auth/presentation/view_models/provider/auth_provider.dart';
import 'history_page.dart';

class UserPage extends ConsumerStatefulWidget {
  const UserPage({super.key});

  @override
  ConsumerState<UserPage> createState() => _UserPageState();
}

class _UserPageState extends ConsumerState<UserPage>
    with SingleTickerProviderStateMixin {
  final tabs = const ["观看历史", "正在追", "准备追", "已追完"];

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

    return Scaffold(
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

          // 其他 Tab 页面：可替换为自己的网格或列表页面
          Center(child: Text('正在追', style: const TextStyle(fontSize: 24))),
          Center(child: Text('准备追', style: const TextStyle(fontSize: 24))),
          Center(child: Text('已追完', style: const TextStyle(fontSize: 24))),
        ],
      ),
    );
  }
}
