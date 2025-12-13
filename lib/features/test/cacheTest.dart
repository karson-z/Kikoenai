import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kikoenai/core/service/path_setting_service.dart';
import 'package:kikoenai/core/storage/hive_key.dart';
import '../../core/constants/app_file_extensions.dart';
import '../../core/constants/app_regex_str.dart';
import '../../core/service/import_file_service.dart';

class ImportTestPage extends StatefulWidget {
  const ImportTestPage({super.key});

  @override
  State<ImportTestPage> createState() => _ImportTestPageState();
}

class _ImportTestPageState extends State<ImportTestPage> {
  final FileImportService _service = FileImportService();

  // UI 状态变量
  final List<String> _logs = [];
  double _progress = 0.0;
  bool _isProcessing = false;
  String _currentProcessingFile = "";
  final ScrollController _scrollController = ScrollController();

  /// 添加日志并自动滚动到底部
  void _addLog(String message) {
    if (!mounted) return;
    setState(() {
      _logs.add("[${DateTime.now().hour.toString().padLeft(2,'0')}:${DateTime.now().minute.toString().padLeft(2,'0')}:${DateTime.now().second.toString().padLeft(2,'0')}] $message");
    });

    // 延时滚动
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 通用的导入流程测试函数
  /// [pickDirectory]: 是否选择文件夹
  /// [allowMultiple]: 是否允许多选 (仅针对文件)
  Future<void> _runImportProcess({bool pickDirectory = false, bool allowMultiple = false}) async {
    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _logs.clear();
      _currentProcessingFile = "";
    });

    try {
      // 1. 权限检查
      _addLog("1. 正在检查/申请权限...");
      final hasPermission = await _service.requestPermissions();
      if (!hasPermission) {
        _addLog("❌ 权限被拒绝，无法继续。");
        return;
      }
      _addLog("✅ 权限获取成功。");

      // 2. 选择文件或文件夹
      List<String> selectedPaths = [];

      if (pickDirectory) {
        final path = await FilePicker.platform.getDirectoryPath();
        if (path != null) selectedPaths.add(path);
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: allowMultiple,
          // 可以在这里限制 picker 显示的文件类型，但我们为了测试 Service 的过滤功能，允许所有
          type: FileType.any,
        );
        if (result != null) {
          // 过滤掉可能的 null 路径
          selectedPaths = result.paths.whereType<String>().toList();
        }
      }

      if (selectedPaths.isEmpty) {
        _addLog("⚠️ 用户取消了选择。");
        return;
      }

      _addLog("📂 选中对象数量: ${selectedPaths.length}");
      if (selectedPaths.length == 1) {
        _addLog("📂 路径: ${selectedPaths.first}");
      } else {
        _addLog("📂 首个路径: ${selectedPaths.first} ...");
      }

      // 3. 识别导入类型
      _addLog("2. 识别导入类型...");
      final type = await _service.identifyImportType(selectedPaths);
      _addLog("ℹ️ 识别结果: ${type.toString().split('.').last}");

      if (type == ImportFileType.unknown) {
        _addLog("❌ 不支持的文件类型。");
        return;
      }

      // 4. 检查文件大小
      _addLog("3. 检查文件大小...");
      final isSizeOk = await _service.checkFileSize(selectedPaths);
      if (!isSizeOk) {
        _addLog("⚠️ 文件过大 (超过阈值)，实际业务中可能需要弹窗确认。");
      } else {
        _addLog("✅ 文件大小在阈值内。");
      }

      // 定义我们想要导入的文件类型 (例如：视频 + 字幕)
      // 使用之前定义的 FileExtensions 常量
      final targetExtensions = FileExtensions.merge([
        FileExtensions.video,
        FileExtensions.subtitles,
        // 如果你想测试图片，可以把下面这行解注
        // FileExtensions.images,
      ]);
      final pathService = PathSettingsService();
      final targetPath = await pathService.getPath(StorageKeys.pathSubtitle);
      _addLog("🎯 预计根保存路径: $targetPath");
      final targetPathSub = await _service.generateTargetPath(selectedPaths.first, targetPath, type);
      // 7. 执行导入
      _addLog("5. 开始导入...");
      final startTime = DateTime.now();

      await _service.importFile(
        sourcePaths: selectedPaths, // 传入 List
        destinationPath: targetPathSub,
        type: type,
        allowedExtensions: targetExtensions, // 传入允许的后缀集合
        idRegexPattern: RegexPatterns.workId, // 传入正则用于解压时的智能路由
        onProgress: (progress, currentFile) {
          // 更新 UI
          if (mounted) {
            setState(() {
              _progress = progress;
              _currentProcessingFile = currentFile;
            });
          }
        },
      );

      final endTime = DateTime.now();
      _addLog("✅ 导入完成！耗时: ${endTime.difference(startTime).inMilliseconds}ms");
      _addLog("💾 检查位置: $targetPath");

      // 简单验证
      if (await Directory(targetPath).exists()) {
        _addLog("✅ 根目录已创建。");
      }

    } catch (e, stack) {
      _addLog("❌ 发生错误: $e");
      debugPrintStack(stackTrace: stack);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _currentProcessingFile = "";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("智能导入服务测试"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- 控制区 ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("选择导入方式:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // 按钮 1: 导入文件夹
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.folder_open,
                        label: "文件夹",
                        onTap: () => _runImportProcess(pickDirectory: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 按钮 2: 导入单文件
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.insert_drive_file_outlined,
                        label: "单文件",
                        onTap: () => _runImportProcess(pickDirectory: false, allowMultiple: false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 按钮 3: 导入多文件
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.file_copy_outlined,
                        label: "多文件",
                        onTap: () => _runImportProcess(pickDirectory: false, allowMultiple: true),
                      ),
                    ),
                  ],
                ),
                // --- 进度条 ---
                if (_isProcessing) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(value: _progress, backgroundColor: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "处理中: $_currentProcessingFile",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.indigo),
                        ),
                      ),
                      Text(
                        "${(_progress * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // --- 日志区 ---
          Expanded(
            child: Container(
              color: const Color(0xFF1E1E1E), // 深色背景类似终端
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return _buildLogItem(log);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: _isProcessing ? null : onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLogItem(String log) {
    Color color = const Color(0xFFAAAAAA); // 默认灰色
    FontWeight weight = FontWeight.normal;

    if (log.contains("❌") || log.contains("Error")) {
      color = const Color(0xFFFF5252); // 红色
      weight = FontWeight.bold;
    } else if (log.contains("⚠️")) {
      color = const Color(0xFFFFD740); // 黄色
    } else if (log.contains("✅")) {
      color = const Color(0xFF69F0AE); // 绿色
    } else if (log.contains("ℹ️")) {
      color = const Color(0xFF40C4FF); // 蓝色
    } else if (log.contains("📂") || log.contains("🎯")) {
      color = Colors.white; // 高亮重要路径信息
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Text(
        log,
        style: TextStyle(color: color, fontFamily: 'Courier New', fontSize: 13, fontWeight: weight),
      ),
    );
  }
}