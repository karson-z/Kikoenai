import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/enums/tag_enum.dart';
import 'package:kikoenai/core/widgets/filter/filter_widget.dart';
import '../../core/model/search_tag.dart';
import '../../core/widgets/filter/provider/filter_search_notifier.dart';

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildSectionCard(
                    title: '标签',
                    icon: Icons.local_offer,
                    iconColor: const Color(0xFF6B72FF),
                    subtitle: '管理作品相关的通用标签',
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
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: '声优',
                    icon: Icons.mic,
                    iconColor: const Color(0xFFA584FF),
                    subtitle: '管理声优相关标签',
                    content: _buildTagsContent(
                      '声优',
                      allTags
                          .where((t) => t.type == TagType.va.stringValue)
                          .toList(),
                          () => ref.read(searchFilterProvider(FilterModule.global).notifier)
                          .resetTagsByType(TagType.va.stringValue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: '社团',
                    icon: Icons.domain,
                    iconColor: const Color(0xFF5BA4D9),
                    subtitle: '管理社团/品牌相关标签',
                    content: _buildTagsContent(
                      '社团',
                      allTags
                          .where((t) => t.type == TagType.circle.stringValue)
                          .toList(),
                          () => ref.read(searchFilterProvider(FilterModule.global).notifier)
                          .resetTagsByType(TagType.circle.stringValue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: '特殊',
                    icon: Icons.star,
                    iconColor: const Color(0xFFF5B642),
                    subtitle: '管理特殊属性标签',
                    content: _buildTagsContent(
                      '特殊',
                      allTags
                          .where((t) => !mainTypes.contains(t.type))
                          .toList(),
                          () {
                        // 特殊分类包含多种 type，需要遍历清除
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

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '全局筛选标签',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E28),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '管理全局可用的筛选标签，标签将应用于全站内容筛选',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                ref.read(searchFilterProvider(FilterModule.global).notifier).resetSelected();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重置全部'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                showFilterBottomSheet(context, ref, FilterModule.global, isShowAction: false);
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新建标签'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
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
            blurRadius: 10,
            offset: const Offset(0, 4),
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
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 12.0,
          ),
          leading: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(subtitle, style: const TextStyle(fontSize: 13)),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 68.0,
                  right: 24.0,
                  bottom: 24.0,
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
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('暂无标签，请点击上方新建', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 重置当前分类按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.delete_sweep, size: 16),
              label: const Text('重置该类'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[500],
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                tag.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  decoration: textDecoration,
                  decorationColor: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
                    size: 16,
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
      padding: const EdgeInsets.only(top: 24.0),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb_outline, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Text(
              '提示：点击标签切换包含/排除状态，点击图标删除标签',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}