import 'package:flutter/material.dart';

import '../widget/webdav_connection_form.dart';

class WebDavSettingsPage extends StatelessWidget {
  const WebDavSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV 设置')),
      body: const WebDavConnectionForm(showDisconnectAction: true),
    );
  }
}
