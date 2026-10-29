import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/cloud_drive/page/webdav_settings_page.dart';
import 'package:kikoenai/features/cloud_drive/provider/webdav_connection_controller.dart';

class _TestWebDavController extends WebDavController {
  @override
  WebDavSessionState build() => const WebDavSessionState(
    serverUrl: 'https://example.com/dav/',
    username: 'tester',
    rootPath: '/audio',
    isConnected: true,
  );

  @override
  Future<bool> connect(WebDavConnectionConfig rawConfig) async => true;

  @override
  Future<void> disconnect() async {
    state = state.copyWith(isConnected: false, clearError: true);
  }
}

void main() {
  testWidgets('shows connection settings and disconnects the active session', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          webDavConnectionControllerProvider.overrideWith(
            _TestWebDavController.new,
          ),
        ],
        child: const MaterialApp(home: WebDavSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WebDAV 设置'), findsOneWidget);
    expect(find.text('WebDAV 已连接'), findsOneWidget);
    expect(find.text('重新连接'), findsOneWidget);
    expect(find.text('断开连接'), findsOneWidget);

    await tester.ensureVisible(find.text('断开连接'));
    await tester.tap(find.text('断开连接'));
    await tester.pumpAndSettle();

    expect(find.text('连接 WebDAV'), findsOneWidget);
    expect(find.text('连接'), findsOneWidget);
    expect(find.text('断开连接'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
