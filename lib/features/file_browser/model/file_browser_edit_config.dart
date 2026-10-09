/// 传给 [FileNodeBrowser] 的一次构建配置。
///
/// 配置本身不保存状态。页面从自己的编辑 Notifier 读取状态后组装它。
class FileBrowserEditConfig {
  const FileBrowserEditConfig({
    required this.isEditing,
    required this.selectedKeys,
    required this.onToggle,
    required this.onRequestEdit,
  });

  final bool isEditing;
  final Set<String> selectedKeys;
  final void Function(String keyId) onToggle;
  final void Function(String keyId) onRequestEdit;
}
