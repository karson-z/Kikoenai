import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/utils/log/kikoenai_log.dart';
import 'package:kikoenai/features/log/page/logger_view.dart';

const _sample = '''[2026-10-29T12:30:00.000] [DEBUG  ] [Scanner] 开始扫描本地媒体
  │ 扫描目录：/Music/Voice

[2026-10-29T12:30:01.000] [INFO   ] [Player] 播放器初始化完成

[2026-10-29T12:30:02.000] [WARNING] [Download] 网络连接不稳定，正在重试

[2026-10-29T12:30:03.000] [ERROR  ] [Lyrics] 字幕加载失败
  │ 异常: SocketException: Connection timed out
  │ 堆栈:
  │ #0 loadLyrics (lyrics.dart:42)

''';

void main() {
  late _MemoryLogStore store;
  final clipboard = <String>[];
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    store = _MemoryLogStore(_sample);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    clipboard.clear();
  });

  Future<void> finishIo(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> showPage(
    WidgetTester tester, {
    bool dark = false,
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('preview'),
        child: MaterialApp(
          theme: ThemeData(
            fontFamily: 'PreviewChinese',
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: LogViewerPage(logStore: store),
        ),
      ),
    );
    await finishIo(tester);
  }

  Future<void> closePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  testWidgets(
    'search and level filters work together; details keep complete stack',
    (tester) async {
      await showPage(tester);
      expect(find.text('显示 4 条'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'lyrics');
      await tester.pumpAndSettle();
      expect(find.text('显示 1 条'), findsOneWidget);
      await tester.tap(find.textContaining('字幕加载失败').first);
      await tester.pumpAndSettle();
      expect(find.text('日志详情'), findsOneWidget);
      expect(find.textContaining('lyrics.dart:42'), findsWidgets);
      await tester.tap(find.byTooltip('复制此条日志'));
      await finishIo(tester);
      expect(clipboard.single, contains('lyrics.dart:42'));
      await tester.tap(find.byTooltip('关闭详情'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('警告'));
      await tester.pumpAndSettle();
      expect(find.text('没有匹配的日志'), findsOneWidget);
      await tester.tap(find.byTooltip('清除搜索'));
      await tester.pumpAndSettle();
      expect(find.text('显示 1 条'), findsOneWidget);
      expect(find.textContaining('网络连接不稳定'), findsOneWidget);
      await closePage(tester);
    },
  );

  testWidgets('copy all ignores active filters; clear requires confirmation', (
    tester,
  ) async {
    await showPage(tester);
    await tester.tap(find.text('警告'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('日志操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制筛选结果'));
    await finishIo(tester);
    expect(clipboard.last, contains('网络连接不稳定'));
    expect(clipboard.last, isNot(contains('开始扫描')));
    await tester.tap(find.byTooltip('日志操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全部复制'));
    await finishIo(tester);
    expect(clipboard.last, _sample);
    await tester.tap(find.byTooltip('日志操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清空日志'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(await store.readAll(), _sample);
    await tester.tap(find.byTooltip('日志操作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清空日志'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '清空日志'));
    await finishIo(tester);
    expect(await store.readAll(), isEmpty);
    expect(find.text('暂无日志记录'), findsOneWidget);
    await closePage(tester);
  });

  testWidgets('pause keeps the snapshot; resume loads newly written records', (
    tester,
  ) async {
    await showPage(tester);
    await tester.tap(find.widgetWithText(FilterChip, '实时更新'));
    await tester.pumpAndSettle();
    expect(find.text('已暂停'), findsOneWidget);
    store.content += '[2026-10-29T12:30:04.000] [INFO   ] [Test] 新记录\n\n';
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('显示 4 条'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, '实时更新'));
    await finishIo(tester);
    expect(find.text('显示 5 条'), findsOneWidget);
    expect(find.text('新记录'), findsOneWidget);
    await closePage(tester);
  });

  testWidgets('light, dark, landscape and keyboard layouts do not overflow', (
    tester,
  ) async {
    for (final size in [
      const Size(390, 844),
      const Size(320, 568),
      const Size(844, 390),
      const Size(1200, 800),
    ]) {
      for (final dark in [false, true]) {
        await showPage(tester, dark: dark, size: size);
        expect(tester.takeException(), isNull);
        await closePage(tester);
      }
    }
    await showPage(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    await closePage(tester);
  });

  testWidgets(
    'follow and jump to bottom reach the newest record in a long list',
    (tester) async {
      store.content = List.generate(
        500,
        (i) =>
            '[2026-10-29T12:30:00.000] [DEBUG  ] [Test] 记录 $i${i.isEven ? '\n  │ 多行详情\n  │ 额外详情' : ''}\n\n',
      ).join();
      await showPage(tester);
      expect(find.textContaining('记录 499'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, '跟随最新'))
            .selected,
        isFalse,
      );
      await tester.tap(find.byTooltip('滚动到底部'));
      await tester.pumpAndSettle();
      expect(find.textContaining('记录 499'), findsOneWidget);
      await closePage(tester);
    },
  );

  testWidgets('render phone previews with real Chinese glyphs', (tester) async {
    await tester.runAsync(() async {
      final font = File('/System/Library/Fonts/STHeiti Medium.ttc');
      if (await font.exists()) {
        final data = ByteData.sublistView(await font.readAsBytes());
        for (final family in ['PreviewChinese', 'monospace']) {
          await (FontLoader(family)..addFont(Future.value(data))).load();
        }
      }
    });
    await tester.runAsync(() async {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    for (final dark in [false, true]) {
      await showPage(tester, dark: dark);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final output = File('build/log_page_${dark ? 'dark' : 'light'}.png');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await closePage(tester);
    }
  });
}

class _MemoryLogStore extends KikoenaiLogStore {
  _MemoryLogStore(this.content);
  String content;

  @override
  Future<KikoenaiLogSnapshot> readSnapshot() async => KikoenaiLogSnapshot(
    KikoenaiLogRecord.parse(content),
    content.length,
    false,
  );

  @override
  Future<String> readAll() async => content;

  @override
  Future<bool> clear() async {
    content = '';
    return true;
  }
}
