import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/features/cloud_drive/widget/alist_server_form_dialog.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

void main() {
  testWidgets('AList domain form validates and normalizes the URL', (
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
                result = await showAlistServerFormDialog(context);
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
      find.widgetWithText(TextFormField, 'AList 地址'),
      'ftp://invalid.example',
    );
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(find.text('AList 地址仅支持 HTTP 或 HTTPS'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'AList 地址'),
      'https://alist.example.com/root/',
    );
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.baseUrl, 'https://alist.example.com/root');
    expect(result!.label, 'alist.example.com');
  });
}
