import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/log/kikoenai_log.dart';

class LogViewerPage extends StatefulWidget {
  const LogViewerPage({Key? key}) : super(key: key);

  @override
  State<LogViewerPage> createState() => _LogViewerPageState();
}

class _LogViewerPageState extends State<LogViewerPage> {
  String _logContent = '';
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final file = await getLogsPath();
      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() {
          _logContent = content;
        });
      } else {
        setState(() {
          _logContent = '日志文件不存在';
        });
      }
    } catch (e) {
      setState(() {
        _logContent = '读取日志失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _clearLogs() async {
    final success = await clearLogs();
    if (success) {
      await _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日志已清空')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('清空日志失败')),
        );
      }
    }
  }

  void _copyToClipboard() {
    if (_logContent.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _logContent));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('日志已复制到剪贴板')),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _logContent.isNotEmpty ? _copyToClipboard : null,
            tooltip: '全部复制',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearLogs,
            tooltip: '清空',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        color: const Color(0xFF1E1E1E),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: SelectableText(
            _logContent.isEmpty ? '暂无日志记录' : _logContent,
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontFamily: 'monospace',
              fontSize: 13.0,
              height: 1.5,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: _scrollToBottom,
        tooltip: '滚动到底部',
        child: const Icon(Icons.arrow_downward),
      ),
    );
  }
}