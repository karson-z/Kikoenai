import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/test/provider/subtitle_view_controller.dart';
import 'package:kikoenai/features/test/state/subtitle_view_state.dart';
import 'package:path/path.dart' as p;

import 'package:kikoenai/features/test/provider/subtitles_provider.dart';
import 'package:kikoenai/features/test/state/improt_state.dart';
import '../../core/service/import_file_service.dart';
import '../../core/theme/theme_view_model.dart';


class SubtitleManagerPage extends ConsumerStatefulWidget {
  const SubtitleManagerPage({super.key});

  @override
  ConsumerState<SubtitleManagerPage> createState() => _SubtitleManagerPageState();
}

class _SubtitleManagerPageState extends ConsumerState<SubtitleManagerPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController(); // 用于搜索框
  bool _isLocalLoading = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 基础数据 Provider
    final rootPathAsync = ref.watch(subtitleRootProvider);
    final currentPath = ref.watch(currentPathProvider);

    // 2. 视图状态 & 控制器
    final viewState = ref.watch(subtitleViewProvider);
    final viewController = ref.read(subtitleViewProvider.notifier);

    // 同时我们也需要原始 provider 的 loading 状态
    final rawFilesAsync = ref.watch(directoryContentsProvider);
    final filteredFiles = ref.watch(filteredFilesProvider);

    // 4. 导入状态
    final importAsync = ref.watch(fileImportProvider);
    final isGlobalLoading = _isLocalLoading || importAsync.isLoading;
    // 5. 主题状态
    final isDark = ref.watch(explicitDarkModeProvider);
    // 监听导入副作用
    ref.listen(fileImportProvider, (_, next) {
      next.whenOrNull(
        error: (err, stack) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$err'), backgroundColor: Colors.red)
        ),
        data: (state) {
          if (state.progress >= 1.0 && state.currentFile == "完成") {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('导入成功'), backgroundColor: Colors.green)
            );
          }
        },
      );
    });

    return Stack(
      children: [
        PopScope(
          // 拦截返回键逻辑
          canPop: !isGlobalLoading &&
              (currentPath == null || currentPath == rootPathAsync.value) &&
              !viewState.isSearchMode &&
              !viewState.isSelectionMode,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (isGlobalLoading) return;

            // 优先退出特殊模式
            if (viewState.isSearchMode || viewState.isSelectionMode) {
              viewController.exitModes();
              _searchController.clear();
              return;
            }
            // 其次返回上一级目录
            _navigateUp();
          },
          child: Scaffold(
            appBar: _buildDynamicAppBar(context, viewState, viewController, filteredFiles,isDark),

            body: rootPathAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('无法读取路径配置: $err')),
              data: (rootPath) {
                if (currentPath == null) {
                  Future.microtask(() => ref.read(currentPathProvider.notifier).state = rootPath);
                  return const SizedBox();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 非搜索模式下显示面包屑
                    if (!viewState.isSearchMode)
                      _buildBreadcrumbs(rootPath, currentPath,isDark),
                    if (!viewState.isSearchMode)
                      const Divider(height: 1, thickness: 1),

                    Expanded(
                      child: rawFilesAsync.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredFiles.isEmpty
                          ? _buildEmptyState(viewState.isSearchMode)
                          : RefreshIndicator(
                        onRefresh: () async => ref.refresh(directoryContentsProvider),
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: filteredFiles.length,
                          padding: const EdgeInsets.only(bottom: 80),
                          itemBuilder: (context, index) {
                            // 使用新的 Item 构建方法，传入视图状态
                            return _buildFileItem(
                                filteredFiles[index],
                                rootPath,
                                viewState,
                                viewController
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: isGlobalLoading ? null : () => _showImportBottomSheet(context),
              tooltip: '添加字幕',
              child: const Icon(Icons.add),
            ),
          ),
        ),

        // Layer 2: 全局遮罩
        if (isGlobalLoading)
          _buildLoadingOverlay(importAsync),
      ],
    );
  }

  // ==========================================
  // 1. 动态 AppBar 实现
  // ==========================================
  PreferredSizeWidget _buildDynamicAppBar(
      BuildContext context,
      SubtitleViewState state,
      SubtitleViewController controller,
      List<FileSystemEntity> currentFiles,
      bool isDark
      ) {
    // A. 搜索模式
    if (state.isSearchMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            controller.toggleSearchMode();
            _searchController.clear();
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "输入文件名搜索...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          cursorColor: Colors.white,
          onChanged: (val) => controller.updateSearchQuery(val),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _searchController.clear();
                controller.updateSearchQuery('');
              },
            )
        ],
      );
    }

    // B. 多选模式
    if (state.isSelectionMode) {
      final count = state.selectedPaths.length;
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => controller.toggleSelectionMode(),
        ),
        title: Text("已选 $count 项"),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: "全选/反选",
            onPressed: () => controller.selectAll(currentFiles),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "批量删除",
            onPressed: count == 0 ? null : () {
              // TODO: 这里可以实现批量删除逻辑
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("待实现批量删除 $count 个文件")));
            },
          ),
        ],
      );
    }

    // C. 普通模式
    return AppBar(
      centerTitle: false,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 搜索
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: '搜索文件',
              onPressed: () => controller.toggleSearchMode(),
            ),
            // 2. 排序
            PopupMenuButton<SortType>(
              icon: const Icon(Icons.sort),
              tooltip: '排序方式',
              initialValue: state.sortType,
              onSelected: (type) => controller.setSortType(type),
              itemBuilder: (context) => [
                _buildSortMenuItem(SortType.name, "名称", state),
                _buildSortMenuItem(SortType.date, "日期", state),
                _buildSortMenuItem(SortType.size, "大小", state),
              ],
            ),
            // 3. 批量管理 (进入多选)
            IconButton(
              icon: const Icon(Icons.checklist_rtl),
              tooltip: '批量管理',
              onPressed: () => controller.toggleSelectionMode(),
            ),
            // 4. 说明
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: '使用说明',
              onPressed: () => _showHelpDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<SortType> _buildSortMenuItem(SortType type, String text, SubtitleViewState state) {
    final isSelected = state.sortType == type;
    return PopupMenuItem(
      value: type,
      child: Row(
        children: [
          Text(text, style: TextStyle(
              color: isSelected ? Theme.of(context).primaryColor : null,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          )),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Icon(state.isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
          ]
        ],
      ),
    );
  }

  Widget _buildFileItem(
      FileSystemEntity entity,
      String rootPath,
      SubtitleViewState viewState,
      SubtitleViewController viewController,
      ) {
    final isDir = FileSystemEntity.isDirectorySync(entity.path);
    final name = p.basename(entity.path);
    final timeStr = _getFileTimeStr(entity);
    final sizeStr = isDir ? "" : _formatFileSize(File(entity.path));

    final isSelected = viewState.selectedPaths.contains(entity.path);

    return ListTile(
      // 交互逻辑根据模式不同而改变
      onTap: () {
        if (viewState.isSelectionMode) {
          viewController.toggleFileSelection(entity.path);
        } else {
          if (isDir) {
            if (viewState.isSearchMode) {
              // 1. 更新状态：关闭搜索模式，清空搜索词
              viewController.toggleSearchMode();
              // 2. UI层：清空输入框文字 (前提是 _buildFileItem 在 State 类中，能访问到 _searchController)
              _searchController.clear();
            }
            ref.read(currentPathProvider.notifier).state = entity.path;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("选中文件: $name")));
          }
        }
      },
      onLongPress: () {
        // 长按进入多选模式并选中当前项
        if (!viewState.isSelectionMode) {
          viewController.toggleSelectionMode();
          viewController.toggleFileSelection(entity.path);
        }
      },

      // 样式
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
      leading: viewState.isSelectionMode
          ? Checkbox(
        value: isSelected,
        onChanged: (val) => viewController.toggleFileSelection(entity.path),
      )
          : Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDir ? Colors.amber.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isDir ? Icons.folder_rounded : Icons.description_outlined,
          color: isDir ? Colors.amber[800] : Colors.blue[700],
        ),
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        isDir ? "$timeStr · 文件夹" : "$timeStr · $sizeStr",
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      // 多选模式下隐藏右侧菜单
      trailing: viewState.isSelectionMode
          ? null
          : PopupMenuButton<String>(
        onSelected: (value) => _handleMenuAction(value, entity, rootPath),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('重命名')])),
          if (isDir) const PopupMenuItem(value: 'migrate', child: Row(children: [Icon(Icons.drive_file_move, size: 18), SizedBox(width: 8), Text('迁移至...')])),
          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('删除', style: TextStyle(color: Colors.red))])),
        ],
      ),
    );
  }

  // ==========================================
  // 3. 辅助方法 & 旧逻辑保留
  // ==========================================

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const AlertDialog(
        title: Text("使用说明"),
        content: Text("1. 搜索：支持模糊搜索文件名\n2. 排序：支持名称、日期、大小排序\n3. 导入：支持文件或文件夹导入\n4. 长按列表项可进入多选模式"),
      ),
    );
  }

  String _getFileTimeStr(FileSystemEntity entity) {
    try {
      final stat = entity.statSync();
      return "${stat.modified.year}-${stat.modified.month}-${stat.modified.day}";
    } catch (e) {
      return "";
    }
  }
  Widget _buildLoadingOverlay(AsyncValue<ImportState> importState) {
    final progress = importState.value?.progress ?? 0.0;
    final currentFile = importState.value?.currentFile ?? "";
    final isImporting = importState.isLoading;

    return Container(
      color: Colors.black54,
      width: double.infinity, height: double.infinity,
      child: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isImporting && progress > 0) ...[
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(currentFile, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                    const SizedBox(width: 8),
                    Text("${(progress * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ])
                ] else ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_isLocalLoading ? "正在处理..." : "准备导入...", style: const TextStyle(fontSize: 16)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildBreadcrumbs(String rootPath, String currentPath, bool isDark) {
    final relative = p.relative(currentPath, from: rootPath);
    final parts = relative == '.' ? [] : p.split(relative);
    List<Widget> crumbs = [];
    crumbs.add(InkWell(
      onTap: () => ref.read(currentPathProvider.notifier).state = rootPath,
      borderRadius: BorderRadius.circular(4),
      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0), child: Icon(Icons.home_outlined)),
    ));
    String tempPath = rootPath;
    for (int i = 0; i < parts.length; i++) {
      tempPath = p.join(tempPath, parts[i]);
      final targetPath = tempPath;
      crumbs.add(const Icon(Icons.chevron_right, size: 18, color: Colors.grey));
      final isLast = i == parts.length - 1;
      crumbs.add(InkWell(
        onTap: isLast ? null : () => ref.read(currentPathProvider.notifier).state = targetPath,
        borderRadius: BorderRadius.circular(4),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0), child: Text(parts[i], style: TextStyle(fontWeight: isLast ? FontWeight.bold : FontWeight.normal, color: isLast ? (isDark ? Colors.white : Colors.black) : Colors.blueGrey, fontSize: 16))),
      ));
    }
    return SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: crumbs));
  }

  Widget _buildEmptyState(bool isSearch) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isSearch ? Icons.search_off : Icons.folder_open_rounded, size: 80, color: Colors.grey.withOpacity(0.3)), const SizedBox(height: 16), Text(isSearch ? "未找到相关文件" : "文件夹为空", style: TextStyle(color: Colors.grey[500], fontSize: 16))]));
  }

  void _showImportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.create_new_folder_outlined)),
                  title: const Text('新建文件夹'),
                  onTap: () { Navigator.pop(ctx); _showNewFolderDialog(); },
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green, foregroundColor: Colors.white, child: Icon(Icons.file_upload_outlined)),
                  title: const Text('导入文件'),
                  subtitle: const Text('支持 .zip, .srt, .ass 等'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleImportByProvider(ImportFileType.multipleFiles);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.orange, foregroundColor: Colors.white, child: Icon(Icons.drive_folder_upload_outlined)),
                  title: const Text('导入整个文件夹'),
                  subtitle: const Text('保持原有结构'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleImportByProvider(ImportFileType.folder);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
  void _handleImportByProvider(ImportFileType type) {
    ref.read(fileImportProvider.notifier).importFiles(type);
  }

  Future<void> _handleMenuAction(String action, FileSystemEntity entity, String rootPath) async {
    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("确认删除"),
          content: Text("确定要永久删除 \"${p.basename(entity.path)}\" 吗？"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("取消")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("删除", style: TextStyle(color: Colors.red))),
          ],
        ),
      );

      if (confirm == true) {
        try {
          await entity.delete(recursive: true);
          ref.refresh(directoryContentsProvider);
        } catch(e) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("删除失败: $e")));
        }
      }
    } else if (action == 'migrate') {
      ref.read(fileImportProvider.notifier).migrateDirectory(entity);
    } else if (action == 'rename') {
      _showRenameDialog(entity);
    }
  }

  void _showNewFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("新建文件夹"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "文件夹名称", border: OutlineInputBorder()), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final currentDir = ref.read(currentPathProvider);
                try {
                  await Directory(p.join(currentDir!, name)).create();
                  ref.refresh(directoryContentsProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("创建失败: $e")));
                }
              }
            },
            child: const Text("创建"),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(FileSystemEntity entity) {
    final controller = TextEditingController(text: p.basename(entity.path));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("重命名"),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("取消")),
          TextButton(onPressed: () async {
            final newName = controller.text.trim();
            if (newName.isNotEmpty && newName != p.basename(entity.path)) {
              try {
                await entity.rename(p.join(p.dirname(entity.path), newName));
                ref.refresh(directoryContentsProvider);
                if(ctx.mounted) Navigator.pop(ctx);
              } catch(e) {/*handle error*/}
            }
          }, child: const Text("确认")),
        ],
      ),
    );
  }

  void _navigateUp() {
    final current = ref.read(currentPathProvider);
    final root = ref.read(subtitleRootProvider).value;
    if (current != null && current != root) {
      ref.read(currentPathProvider.notifier).state = p.dirname(current);
    }
  }

  String _formatFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return "$bytes B";
      if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
      return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    } catch (e) { return ""; }
  }
}