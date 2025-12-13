import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kikoenai/core/service/import_file_service.dart';
import 'package:permission_handler/permission_handler.dart';
// 确保引入你的 Service 和 Keys
import 'package:kikoenai/core/service/path_setting_service.dart';
import '../../../../core/storage/hive_key.dart';

class PathSettingsPage extends StatefulWidget {
  const PathSettingsPage({Key? key}) : super(key: key);

  @override
  State<PathSettingsPage> createState() => _PathSettingsPageState();
}

class _PathSettingsPageState extends State<PathSettingsPage> {
  final PathSettingsService _settingsService = PathSettingsService();

  Map<String, String> _pathMap = {};
  bool _isLoading = true;
  bool _isMigrating = false;

  final List<_PathConfigItem> _configItems = [
    _PathConfigItem(title: '字幕存储路径', key: StorageKeys.pathSubtitle, icon: Icons.subtitles),
    _PathConfigItem(title: '视频存储路径', key: StorageKeys.pathVideo, icon: Icons.movie),
    _PathConfigItem(title: '音频存储路径', key: StorageKeys.pathAudio, icon: Icons.audiotrack),
  ];

  @override
  void initState() {
    super.initState();
    _loadAllPaths();
  }

  Future<void> _loadAllPaths() async {
    setState(() => _isLoading = true);
    final Map<String, String> tempMap = {};
    for (var item in _configItems) {
      tempMap[item.key] = await _settingsService.getPath(item.key);
    }
    if (mounted) {
      setState(() {
        _pathMap = tempMap;
        _isLoading = false;
      });
    }
  }

  /// 选择新文件夹并保存 (包含迁移逻辑)
  Future<void> _pickNewPath(String key) async {
    if (Platform.isAndroid) {
      await Permission.manageExternalStorage.request();
    }

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '请选择存储文件夹',
      lockParentWindow: true,
    );

    if (selectedDirectory != null) {
      // 检查路径是否没变
      if (selectedDirectory == _pathMap[key]) return;

      setState(() => _isMigrating = true);
      try {
        // 1. 调用 Service 保存 (Service 内部应处理 migrateDirectory)
        await  FileImportService().migrateDirectory(_pathMap[key]!, selectedDirectory);
        await _settingsService.setPath(key, selectedDirectory);
        // 2. 更新本地状态
        setState(() {
          _pathMap[key] = selectedDirectory;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("路径更新成功，旧文件已迁移至: $selectedDirectory")),
          );
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog("迁移失败", e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _isMigrating = false);
        }
      }
    }
  }

  /// 恢复默认路径 (包含迁移逻辑)
  Future<void> _resetToDefault(String key, String title) async {
    // 弹窗确认
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("恢复默认"),
        content: Text("确定要将“$title”恢复为默认路径吗？\n\n当前路径下的文件将被迁移回默认文件夹。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("取消")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("确定")),
        ],
      ),
    );

    if (confirm != true) return;

    // 🔥 开启阻塞状态
    setState(() => _isMigrating = true);

    try {
      // 1. 调用 Service 的 reset 方法
      // 注意：你需要确保 SettingsService 里实现了 resetPath 方法
      final defaultPath = await _settingsService.resetPath(key);

      // 2. 更新 UI
      setState(() {
        _pathMap[key] = defaultPath;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("已恢复默认路径")),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("重置失败", e.toString());
      }
    } finally {
      // 🔥 关闭阻塞状态
      if (mounted) {
        setState(() => _isMigrating = false);
      }
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("关闭"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("存储路径设置")),
      // 使用 Stack 来实现全屏遮罩
      body: Stack(
        children: [
          // 1. 主内容列表
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
            itemCount: _configItems.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _configItems[index];
              final currentPath = _pathMap[item.key] ?? "读取中...";

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(item.icon, color: Colors.blue),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    currentPath,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                trailing: const Icon(Icons.edit, color: Colors.blueGrey),
                // 点击修改
                onTap: () => _pickNewPath(item.key),
                // 长按恢复默认
                onLongPress: () => _resetToDefault(item.key, item.title),
              );
            },
          ),

          // 2. 迁移时的遮罩层 (Loading Overlay)
          if (_isMigrating) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  /// 构建全屏遮罩，阻止用户操作
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54, // 半透明黑色背景
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              "正在迁移文件...",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "请勿关闭应用",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathConfigItem {
  final String title;
  final String key;
  final IconData icon;

  _PathConfigItem({required this.title, required this.key, required this.icon});
}