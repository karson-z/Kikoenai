import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/constants/app_file_extensions.dart';
import 'package:kikoenai/features/test/provider/subtitles_provider.dart';
import '../../core/constants/app_regex_str.dart';
import '../../core/service/import_file_service.dart';
import 'package:path/path.dart' as p;
class SubtitleManagerPage extends ConsumerStatefulWidget {
  const SubtitleManagerPage({super.key});

  @override
  ConsumerState<SubtitleManagerPage> createState() => _SubtitleManagerPageState();
}

class _SubtitleManagerPageState extends ConsumerState<SubtitleManagerPage> {
  final ScrollController _scrollController = ScrollController();

  // 【核心修改】增加 Loading 状态变量
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final rootPathAsync = ref.watch(subtitleRootProvider);
    final currentPath = ref.watch(currentPathProvider);
    final filesAsync = ref.watch(directoryContentsProvider);

    // 【核心修改】使用 Stack 包裹整个页面
    return Stack(
      children: [
        // --- Layer 1: 主页面内容 ---
        PopScope(
          // 当 loading 时或者在根目录时，根据逻辑处理返回键
          canPop: !_isLoading && (currentPath == null || currentPath == rootPathAsync.value),
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            // 如果正在加载，禁止任何操作
            if (_isLoading) return;
            // 否则执行向上导航
            _navigateUp();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('字幕库管理'),
              centerTitle: true,
              elevation: 0,
            ),
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
                    _buildBreadcrumbs(rootPath, currentPath),
                    const Divider(height: 1, thickness: 1),
                    Expanded(
                      child: filesAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Center(child: Text('加载文件失败: $e')),
                        data: (entities) {
                          if (entities.isEmpty) return _buildEmptyState();
                          return RefreshIndicator(
                            onRefresh: () async => ref.refresh(directoryContentsProvider),
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: entities.length,
                              padding: const EdgeInsets.only(bottom: 80),
                              itemBuilder: (context, index) {
                                return _buildFileItem(entities[index], rootPath);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _isLoading ? null : () => _showImportBottomSheet(context), // 加载时禁用按钮
              tooltip: '添加字幕',
              child: const Icon(Icons.add),
            ),
          ),
        ),

        // --- Layer 2: 全局 Loading 遮罩 ---
        // 【核心修改】根据 _isLoading 状态显示遮罩
        if (_isLoading)
          Container(
            color: Colors.black54, // 半透明黑色背景
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "处理中...",
                    style: TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.none),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // --- 组件：面包屑 ---
  Widget _buildBreadcrumbs(String rootPath, String currentPath) {
    final relative = p.relative(currentPath, from: rootPath);
    final parts = relative == '.' ? [] : p.split(relative);

    List<Widget> crumbs = [];

    crumbs.add(InkWell(
      onTap: () => ref.read(currentPathProvider.notifier).state = rootPath,
      borderRadius: BorderRadius.circular(4),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Icon(Icons.home_filled, color: Colors.blue),
      ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
          child: Text(
            parts[i],
            style: TextStyle(
              fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
              color: isLast ? Colors.black87 : Colors.blueGrey,
              fontSize: 16,
            ),
          ),
        ),
      ));
    }

    return Container(
      color: Theme.of(context).cardColor,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: crumbs),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("文件夹为空", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildFileItem(FileSystemEntity entity, String rootPath) {
    final isDir = FileSystemEntity.isDirectorySync(entity.path);
    final name = p.basename(entity.path);
    String timeStr = "";
    try {
      final stat = entity.statSync();
      timeStr = "${stat.modified.year}-${stat.modified.month}-${stat.modified.day}";
    } catch(e) {
      // ignore error
    }

    return ListTile(
      leading: Container(
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
        isDir ? "$timeStr · 文件夹" : "$timeStr · ${_formatFileSize(File(entity.path))}",
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleMenuAction(value, entity, rootPath),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('重命名')])),
          if (isDir)
            const PopupMenuItem(value: 'migrate', child: Row(children: [Icon(Icons.drive_file_move, size: 18), SizedBox(width: 8), Text('迁移至...')])),
          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('删除', style: TextStyle(color: Colors.red))])),
        ],
      ),
      onTap: () {
        if (isDir) {
          ref.read(currentPathProvider.notifier).state = entity.path;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("已选中: $name")));
        }
      },
    );
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.create_new_folder_outlined)),
                  title: const Text('新建文件夹'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showNewFolderDialog();
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green, foregroundColor: Colors.white, child: Icon(Icons.file_upload_outlined)),
                  title: const Text('导入文件'),
                  subtitle: const Text('支持 .zip, .srt, .ass 等'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleImport(ImportFileType.multipleFiles);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.orange, foregroundColor: Colors.white, child: Icon(Icons.drive_folder_upload_outlined)),
                  title: const Text('导入整个文件夹'),
                  subtitle: const Text('保持原有结构'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleImport(ImportFileType.folder);
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

  // ==========================================
  // 4. 业务逻辑 (State 更新版)
  // ==========================================

  Future<void> _handleImport(ImportFileType type) async {
    // 1. 获取权限
    final hasPermission = await FileImportService().requestPermissions();
    if (!hasPermission) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("无文件访问权限")));
      return;
    }

    // 2. 只有在用户完成选择后，再决定是否开启 loading
    String? selectedPath;
    List<String> paths = [];

    if (type == ImportFileType.folder) {
      selectedPath = await FilePicker.platform.getDirectoryPath();
      if (selectedPath != null) paths.add(selectedPath);
    } else {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null) {
        paths = result.paths.whereType<String>().toList();
      }
    }

    // 用户取消了选择
    if (paths.isEmpty) return;

    final currentDir = ref.read(currentPathProvider);
    if (currentDir == null) return;

    // 【核心修改】开启 Loading 遮罩，不再使用 showDialog
    setState(() {
      _isLoading = true;
    });

    try {
      final actualType = type == ImportFileType.folder
          ? ImportFileType.folder
          : FileImportService().identifyImportType(paths);
      final targetPath = FileImportService().generateTargetPath(paths.first, currentDir, type,idRegexPattern: RegexPatterns.workId);
      await FileImportService().importFile(
        sourcePaths: paths,
        destinationPath: targetPath,
        type: actualType,
        // 请替换为你实际的后缀列表，例如 FileExtensions.subtitles
        allowedExtensions: FileExtensions.subtitles,
        idRegexPattern: RegexPatterns.workId,
        onProgress: (progress, file) {
          // 这里可以扩展为更新 state 中的 progress 变量来显示进度条
          debugPrint("Progress: $progress");
        },
      );

      // 成功逻辑
      ref.refresh(directoryContentsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("导入成功")));
    } catch (e) {
      // 失败逻辑
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("导入失败: $e")));
    } finally {
      // 【核心修改】无论成功或失败，都在这里关闭遮罩
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        // 删除操作很快，一般不需要全局 Loading，或者你可以加上
        try {
          await entity.delete(recursive: true);
          ref.refresh(directoryContentsProvider);
        } catch(e) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("删除失败: $e")));
        }
      }
    } else if (action == 'migrate') {
      // 1. 获取当前的字幕根目录路径
      final rootPath = ref.read(subtitleRootProvider).value;

      // 如果根目录还没加载出来，直接返回
      if (rootPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("根目录未就绪，无法迁移")));
        return;
      }

      // 2. 打开文件夹选择器
      String? targetDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: "选择迁移目标位置",
        initialDirectory: rootPath, // 【尝试】设置初始目录为根目录
        lockParentWindow: true,
      );

      if (targetDir != null) {
        // 3. 检查选中的路径是否位于根目录下
        // p.isWithin(parent, child) 会判断 child 是否在 parent 内部
        // p.equals(path1, path2) 判断是否是同一个目录 (允许迁移到根目录本身)
        final bool isInsideRoot = p.isWithin(rootPath, targetDir);
        final bool isRootItSelf = p.equals(rootPath, targetDir);

        if (!isInsideRoot && !isRootItSelf) {
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("禁止操作：只能迁移到字幕库目录内部！要整体迁移的话请前往设置中进行迁移！！！！"),
              backgroundColor: Colors.red,
            ));
          }
          return; // 直接终止操作
        }

        // 4. 防止迁移到自己内部 (死循环)
        if (p.isWithin(entity.path, targetDir) || p.equals(entity.path, targetDir)) {
          if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("无效操作：不能迁移到自己或自己的子文件夹中"),
            ));
          }
          return;
        }

        // --- 校验通过，开始执行逻辑 ---

        final newPath = p.join(targetDir, p.basename(entity.path));

        setState(() => _isLoading = true);

        try {
          await FileImportService().migrateDirectory(
            entity.path,
            newPath,
          );
          ref.refresh(directoryContentsProvider);
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("迁移完成")));
        } catch (e) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("迁移失败: $e")));
        } finally {
          if(mounted) setState(() => _isLoading = false);
        }
      }
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
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "文件夹名称", border: OutlineInputBorder()),
          autofocus: true,
        ),
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
              } catch(e) {
                // handle error
              }
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
    } catch (e) {
      return "";
    }
  }
}