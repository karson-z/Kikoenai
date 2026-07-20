import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/tag_enum.dart';
import 'package:kikoenai/core/widgets/filter/filter_widget.dart';
import '../../../../core/model/search_tag.dart';
import '../../../../core/widgets/filter/provider/filter_search_notifier.dart';

class GlobalFilterTagsPage extends ConsumerStatefulWidget {
  const GlobalFilterTagsPage({super.key});

  @override
  ConsumerState<GlobalFilterTagsPage> createState() =>
      _GlobalFilterTagsPageState();
}

class _GlobalFilterTagsPageState extends ConsumerState<GlobalFilterTagsPage> {
  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(searchFilterProvider(FilterModule.global));
    final allTags = filterState.selectedTags;
    final mainTypes = [
      TagType.tag.stringValue,
      TagType.va.stringValue,
      TagType.circle.stringValue,
    ];

    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildSectionCard(
                    title: '标签',
                    icon: Icons.local_offer,
                    iconColor: const Color(0xFF6B72FF),
                    subtitle: '通用标签',
                    initiallyExpanded: true,
                    content: _buildTagsContent(
                      '标签',
                      allTags
                          .where((t) => t.type == TagType.tag.stringValue)
                          .toList(),
                          () => ref.read(searchFilterProvider(FilterModule.global).notifier)
                          .resetTagsByType(TagType.tag.stringValue),
                    ),
                  ),
                  // 3. 【卡片间距】从 16 缩小到 12
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    title: '声优',
                    icon: Icons.mic,
                    iconColor: const Color(0xFFA584FF),
                    subtitle: '声优相关标签',
                    content: _buildTagsContent(
                      '声优',
                      allTags
                          .where((t) => t.type == TagType.va.stringValue)
                          .toList(),
                          () => ref.read(searchFilterProvider(FilterModule.global).notifier)
                          .resetTagsByType(TagType.va.stringValue),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    title: '社团',
                    icon: Icons.domain,
                    iconColor: const Color(0xFF5BA4D9),
                    subtitle: '社团/品牌相关标签',
                    content: _buildTagsContent(
                      '社团',
                      allTags
                          .where((t) => t.type == TagType.circle.stringValue)
                          .toList(),
                          () => ref.read(searchFilterProvider(FilterModule.global).notifier)
                          .resetTagsByType(TagType.circle.stringValue),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    title: '特殊',
                    icon: Icons.star,
                    iconColor: const Color(0xFFF5B642),
                    subtitle: '特殊属性标签',
                    content: _buildTagsContent(
                      '特殊',
                      allTags
                          .where((t) => !mainTypes.contains(t.type))
                          .toList(),
                          () {
                        final notifier = ref.read(searchFilterProvider(FilterModule.global).notifier);
                        final specialTags = allTags.where((t) => !mainTypes.contains(t.type)).toList();
                        for (var tag in specialTags) {
                          notifier.removeTag(tag.type, tag.name);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            _buildPageFooter(),
          ],
        ),
      ),
    );
  }

  // 4. 【AppBar瘦身】采用标准移动端高度、单行标题和紧凑按钮
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF7F8FC),
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: const Text(
        '全局筛选',
        style: TextStyle(
          fontSize: 18, // 标题字号 24 -> 18
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E1E28),
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            ref.read(searchFilterProvider(FilterModule.global).notifier).resetSelected();
          },
          icon: const Icon(Icons.refresh, size: 16), // 图标缩小
          label: const Text('重置', style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[700],
            side: BorderSide(color: Colors.grey[300]!),
            padding: const EdgeInsets.symmetric(horizontal: 12), // 按钮内边距减小
            minimumSize: const Size(0, 32), // 限制按钮高度
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {
            showFilterBottomSheet(context, ref, FilterModule.global, isShowAction: false);
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('新建', style: TextStyle(fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            elevation: 0,
          ),
        ),
        const SizedBox(width: 16), // 右侧边距 32 -> 16
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String subtitle,
    required Widget content,
    bool initiallyExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2), // 降低阴影强度
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          // 5. 【卡片头部紧凑】
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16.0, // 24 -> 16
            vertical: 4.0,    // 12 -> 4
          ),
          leading: Icon(icon, color: iconColor, size: 24), // 图标 28 -> 24
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // 字号 18 -> 16
          ),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)), // 字号 13 -> 12
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                // 6. 【内容区域缩进优化】取消原本 68 的超大左缩进，增加屏幕利用率
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                ),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsContent(String type, List<SearchTag> tags, VoidCallback onReset) {
    if (tags.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('暂无标签，请点击上方新建', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.delete_sweep, size: 14), // 图标 16 -> 14
              label: const Text('重置该类', style: TextStyle(fontSize: 12)), // 字号变小
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[500],
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // 间距 12 -> 8
        Wrap(
          // 7. 【标签间距】16 -> 10，让同一行能放下更多标签
          spacing: 10.0,
          runSpacing: 10.0,
          children: tags.map((tag) => _buildTagItem(tag)).toList(),
        ),
      ],
    );
  }

  Widget _buildTagItem(SearchTag tag) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final notifier = ref.read(
      searchFilterProvider(FilterModule.global).notifier,
    );

    final bgColor = tag.isExclude
        ? Colors.red.withOpacity(0.1)
        : primaryColor.withOpacity(0.1);

    final textColor = tag.isExclude ? Colors.red : primaryColor;

    final textDecoration = tag.isExclude
        ? TextDecoration.lineThrough
        : TextDecoration.none;

    return InkWell(
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () => notifier.toggleTag(tag.type, tag.name),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 32, // 8. 【标签高度】36 -> 32
        padding: const EdgeInsets.symmetric(horizontal: 12), // 内边距 16 -> 12
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6), // 圆角 8 -> 6
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                tag.name,
                style: TextStyle(
                  fontSize: 13, // 字号 14 -> 13
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  decoration: textDecoration,
                  decorationColor: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6), // 图标间距 8 -> 6
            Material(
              color: Colors.transparent,
              child: InkWell(
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                onTap: () => notifier.removeTag(tag.type, tag.name),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(
                    Icons.clear,
                    size: 14, // 图标 16 -> 14
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0), // 上边距 24 -> 16
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb_outline, size: 14, color: Colors.grey[500]), // 图标缩小
            const SizedBox(width: 6),
            Expanded( // 加 Expanded 防止小屏幕换行时文字溢出
              child: Text(
                '提示：点击标签切换包含/排除，点击图标删除', // 文案精简
                style: TextStyle(fontSize: 12, color: Colors.grey[500]), // 字号 13 -> 12
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}