import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cloud_drive_mode.dart';
import '../provider/webdav_connection_controller.dart';
import '../widget/cloud_drive_mode_switch.dart';
import '../widget/webdav_connection_form.dart';
import 'alist_server_management_page.dart';
import 'cloud_drive_browser_page.dart';

class CloudDrivePage extends ConsumerStatefulWidget {
  const CloudDrivePage({super.key});

  @override
  ConsumerState<CloudDrivePage> createState() => _CloudDrivePageState();
}

class _CloudDrivePageState extends ConsumerState<CloudDrivePage> {
  CloudDriveMode _mode = CloudDriveMode.alistApi;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final webDavState = ref.watch(webDavConnectionControllerProvider);
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CloudDriveModeSwitch(
              value: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
            Expanded(
              child: IndexedStack(
                index: _mode.index,
                children: [
                  CloudDriveBrowserPage(
                    mode: CloudDriveMode.alistApi,
                    isRoot: true,
                    embedded: true,
                    manageTooltip: '管理 AList 域名',
                    onManageSource: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AlistServerManagementPage(),
                      ),
                    ),
                  ),
                  webDavState.isConnected
                      ? CloudDriveBrowserPage(
                          key: ValueKey(webDavState.revision),
                          mode: CloudDriveMode.webDav,
                          initialPath: webDavState.rootPath,
                          rootPath: webDavState.rootPath,
                          isRoot: true,
                          embedded: true,
                          manageTooltip: 'WebDAV 连接设置',
                          onManageSource: () => ref
                              .read(webDavConnectionControllerProvider.notifier)
                              .disconnect(),
                        )
                      : const WebDavConnectionForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
