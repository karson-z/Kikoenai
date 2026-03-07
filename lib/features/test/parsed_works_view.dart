import 'package:flutter/material.dart';
import 'package:kikoenai/config/work_layout_strategy.dart';
import 'package:kikoenai/core/model/file_node.dart';
import 'package:kikoenai/features/album/data/model/work.dart';
import 'package:kikoenai/core/widgets/card/work_card.dart';
// 请确认你实际的存储类路径
import '../../core/utils/scraper/scraper_storage.dart';

class ParseWorksView extends StatefulWidget {
  final List<Work> work;
  final List<FileNode>? nodes;

  const ParseWorksView({
    super.key,
    required this.work,
    this.nodes
  });

  @override
  State<ParseWorksView> createState() => _ParseWorksViewState();
}

class _ParseWorksViewState extends State<ParseWorksView> {
  // 控制是否处于编辑模式
  bool _isEditing = false;

  late List<Work> _localWorks;

  @override
  void initState() {
    super.initState();
    // 初始化时，将外部传入的静态数据拷贝一份给本地状态
    _localWorks = List.from(widget.work);
  }

  @override
  void didUpdateWidget(covariant ParseWorksView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果父组件传入的数据发生了实质性改变，重新同步到本地
    if (widget.work != oldWidget.work) {
      _localWorks = List.from(widget.work);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_localWorks.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyView(),
          ),
        ],
      );
    }

    const layoutStrategy = WorkListLayout(layoutType: WorkListLayoutType.card);
    final horizontalSpacing = layoutStrategy.getColumnSpacing(context);
    final verticalSpacing = layoutStrategy.getRowSpacing(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildActionBar(context),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          sliver: SliverGrid.builder(
            itemCount: _localWorks.length,
            gridDelegate: _getGridDelegate(horizontalSpacing, verticalSpacing),
            itemBuilder: (context, index) {
              final currentWork = _localWorks[index];
              return _buildEditableCard(currentWork);
            },
          ),
        ),

        // 3. 底部 Footer
        SliverToBoxAdapter(
          child: _buildFooter(context),
        ),
      ],
    );
  }

  /// 顶部操作栏
  Widget _buildActionBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "共 ${_localWorks.length} 个作品",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 处于编辑模式时，显示“全部清空”按钮
              if (_isEditing)
                TextButton.icon(
                  onPressed: _handleClearAll,
                  icon: const Icon(Icons.delete_sweep, color: Colors.red),
                  label: const Text("全部清空", style: TextStyle(color: Colors.red)),
                ),
              // 编辑/完成 切换按钮
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
                icon: Icon(_isEditing ? Icons.check : Icons.edit),
                label: Text(_isEditing ? "完成" : "编辑"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建带有删除遮罩的卡片
  Widget _buildEditableCard(Work currentWork) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 底层：原来的作品卡片。如果是编辑模式，屏蔽其点击事件防止误触播放
        IgnorePointer(
          ignoring: _isEditing,
          child: WorkCard(work: currentWork,isLocalMedia: true),
        ),

        // 顶层：编辑模式下的删除按钮
        if (_isEditing)
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.black.withOpacity(0.6), // 半透明黑色背景让白色图标更清晰
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _handleDeleteSingle(currentWork),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 处理单个删除
  void _handleDeleteSingle(Work work) {
    if (work.id != null) {
      // 1. 删底层数据库
      ScraperStorage().deleteWork(work.id.toString());
      setState(() {
        _localWorks.removeWhere((w) => w.id == work.id);

        // 可选：如果删光了，自动退出编辑模式
        if (_localWorks.isEmpty) {
          _isEditing = false;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已移除 ${work.id} 的缓存数据'),
            duration: const Duration(seconds: 2),
          )
      );
    }
  }

  /// 处理全部清空
  Future<void> _handleClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("全部清空"),
        content: const Text("确定要删除本地所有已解析的作品元数据缓存吗？此操作不可恢复。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("确认清空"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. 删底层数据库
      await ScraperStorage().clearAll();

      if (mounted) {
        // 2. 【核心修复 6】：清空内存里的 UI 列表，并退出编辑模式
        setState(() {
          _localWorks.clear();
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已清空全部解析缓存'))
        );
      }
    }
  }

  SliverGridDelegate _getGridDelegate(double horizontalSpacing, double verticalSpacing) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 240,
      crossAxisSpacing: horizontalSpacing,
      mainAxisSpacing: verticalSpacing,
      childAspectRatio: 0.75,
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 54, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "这里什么都没有哦",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          "内容もうないから、無理無理(ヾﾉ･∀･`)ﾑﾘﾑﾘ",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ),
    );
  }
}