import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/service/permission_service.dart';

class PermissionSettingsPage extends StatefulWidget {
  const PermissionSettingsPage({super.key});

  @override
  State<PermissionSettingsPage> createState() => _PermissionSettingsPageState();
}

class _PermissionSettingsPageState extends State<PermissionSettingsPage> {
  Map<String, Permission> _permissions = {};
  final Map<String, bool> _permStatus = {};
  bool _loading = true;
  int _androidSdk = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _androidSdk = await PermissionService.androidSdk;
    _permissions = await PermissionService.getAvailablePermissions();

    final results = await PermissionService.checkAllPermissions();
    _permStatus
      ..clear()
      ..addAll(results);

    _loading = false;
    if (mounted) setState(() {});
  }

  Future<void> _request(Permission p) async {
    await PermissionService.requestPermission(p);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const Scaffold(body: Center(child: Text("仅支持 Android")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("权限控制中心"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle("通知相关"),
          ..._buildCards(filter(["通知权限"])),

          const SizedBox(height: 20),
          if (_androidSdk >= 33) ...[
            _buildSectionTitle("媒体访问（Android 13+）"),
            ..._buildCards(filter(["读取音频", "读取图片", "读取视频"])),
          ],

          if (_androidSdk <= 32) ...[
            const SizedBox(height: 20),
            _buildSectionTitle("传统存储（Android 12−）"),
            ..._buildCards(filter(["读存储", "写存储"])),
          ],

          const SizedBox(height: 20),
          _buildSectionTitle("特殊权限"),
          ..._buildCards(filter(["悬浮窗"])),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Map<String, Permission> filter(List<String> keys) {
    final result = <String, Permission>{};
    for (final k in keys) {
      if (_permissions.containsKey(k)) {
        result[k] = _permissions[k]!;
      }
    }
    return result;
  }

  Widget _buildSectionTitle(String title) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  List<Widget> _buildCards(Map<String, Permission> items) {
    return items.entries.map((e) {
      final title = e.key;
      final granted = _permStatus[title] ?? false;

      return PermissionCard(
        title: title,
        granted: granted,
        onRequest: () => _request(e.value),
      );
    }).toList();
  }
}

// --------------------------------------------------------
// ✔ 权限卡片
// --------------------------------------------------------
class PermissionCard extends StatefulWidget {
  final String title;
  final bool granted;
  final VoidCallback onRequest;

  const PermissionCard({
    required this.title,
    required this.granted,
    required this.onRequest,
    super.key,
  });

  @override
  State<PermissionCard> createState() => _PermissionCardState();
}

class _PermissionCardState extends State<PermissionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    if (widget.granted) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant PermissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.granted != widget.granted) {
      widget.granted ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Row(
          children: [
            AnimatedIconWidget(controller: _controller),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            FilledButton(
              onPressed: widget.onRequest,
              child: Text(widget.granted ? "已授权" : "授权"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// --------------------------------------------------------
// ✔ 动画图标：红叉 → 勾
// --------------------------------------------------------
class AnimatedIconWidget extends StatelessWidget {
  final AnimationController controller;

  const AnimatedIconWidget({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        final icon = t > 0.5 ? Icons.check_circle : Icons.error_outline;
        final color = t > 0.5 ? Colors.green : Colors.redAccent;
        return Icon(icon, color: color, size: 28);
      },
    );
  }
}
