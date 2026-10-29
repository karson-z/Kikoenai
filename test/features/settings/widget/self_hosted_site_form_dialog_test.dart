import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/settings/widget/self_hosted_site_form_dialog.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

void main() {
  testWidgets('self-hosted site form validates and normalizes the URL', (
    tester,
  ) async {
    ServerInfo? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => IconButton(
              tooltip: 'open',
              onPressed: () async {
                result = await showSelfHostedSiteFormDialog(context);
              },
              icon: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '站点地址'),
      'ftp://invalid.example',
    );
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('Kikoeru 服务器只支持 HTTP/HTTPS: ftp'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, '站点地址'),
      'https://kikoeru.example.com/api/',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.baseUrl, 'https://kikoeru.example.com');
    expect(result!.label, 'kikoeru.example.com');
    expect(result!.useProxy, isFalse);
  });
}
