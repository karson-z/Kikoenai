import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/theme/app_font_preset.dart';
import 'package:kikoenai/core/theme/theme_view_model.dart';
import 'package:kikoenai/features/overly-lyrics/page/overly_lyrics_panel.dart';
import 'package:kikoenai/features/overly-lyrics/provider/overly_lyrics_manager.dart';
import 'package:kikoenai/features/overly-lyrics/provider/overly_lyrics_provider.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:text_scroll/text_scroll.dart';

class _Theme extends ThemeNotifier {
  @override
  ThemeState build() => const ThemeState(fontPreset: AppFontPreset.system);
}

class _Lyrics extends LyricsController {
  int playToggles = 0;
  int nextTracks = 0;
  int previousTracks = 0;
  bool closeSent = false;
  bool lockSent = false;

  @override
  LyricsState build() => const LyricsState(text: '字幕', fontSize: 20);

  @override
  void saveCurrentPositionToMain() {}

  @override
  void updateFontSizeAndSendToMain(double size) {
    state = state.copyWith(fontSize: size);
  }

  @override
  void setTextColorAndSendToMain(Color color) {
    state = state.copyWith(textColor: color);
  }

  @override
  void sendPlayToggleToMain() => playToggles++;

  @override
  void sendNextToMain() => nextTracks++;

  @override
  void sendPreviousToMain() => previousTracks++;

  @override
  Future<void> sendCloseToMain() async => closeSent = true;

  @override
  Future<void> lockInsideOverlay() async {
    state = state.copyWith(isLocked: true);
  }

  @override
  Future<void> sendToggleLockToMain() async => lockSent = true;
}

void main() {
  const controlChannel = MethodChannel('x-slayer/overlay_channel');
  const overlayChannel = MethodChannel('x-slayer/overlay');
  const animation = Duration(milliseconds: 300);
  final calls = <MethodCall>[];
  late _Lyrics lyrics;

  Future<void> mount(
    WidgetTester tester, {
    bool partialTouch = true,
    Future<void> Function(MethodCall)? beforeNativeReply,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(430, partialTouch ? 250 : 190);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(controlChannel, (call) async {
      if (call.method == 'supportsPartialTouchRegion') return partialTouch;
      return null;
    });
    messenger.setMockMethodCallHandler(overlayChannel, (call) async {
      calls.add(call);
      await beforeNativeReply?.call(call);
      if (call.method == 'resizeOverlay') {
        final height = (call.arguments as Map)['height'] as int;
        tester.view.physicalSize = Size(430, height.toDouble());
      }
      return true;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(controlChannel, null);
      messenger.setMockMethodCallHandler(overlayChannel, null);
    });
    calls.clear();
    lyrics = _Lyrics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lyricsControllerProvider.overrideWith(() => lyrics),
          themeNotifierProvider.overrideWith(_Theme.new),
          subtitleManagerProvider.overrideWithValue(
            AndroidSubtitleManager(SubtitleEndpoint.overlay),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Scaffold(body: LyricsOverlayContent()),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(TextScroll));
    await tester.pumpAndSettle();
  }

  Future<void> toggle(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  }

  int lastHeight(String method) =>
      (calls.lastWhere((c) => c.method == method).arguments as Map)['height']
          as int;

  testWidgets(
    'reveals below a fixed subtitle and updates only the touch region',
    (tester) async {
      await mount(tester);
      final subtitleRect = tester.getRect(find.byType(TextScroll));
      final settingsButton = tester.getRect(find.byIcon(Icons.settings));
      await toggle(tester);
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getRect(find.byType(TextScroll)), subtitleRect);
      expect(lastHeight('updateTouchableHeight'), inExclusiveRange(190, 250));
      await tester.pumpAndSettle();
      expect(lastHeight('updateTouchableHeight'), 250);
      expect(tester.getRect(find.byIcon(Icons.settings)), settingsButton);
      expect(tester.getTopLeft(find.text('A+')).dy, greaterThanOrEqualTo(190));
      await toggle(tester);
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getRect(find.byType(TextScroll)), subtitleRect);
      expect(lastHeight('updateTouchableHeight'), inExclusiveRange(190, 250));
      await tester.pumpAndSettle();
      expect(lastHeight('updateTouchableHeight'), 190);
      expect(calls.where((c) => c.method == 'resizeOverlay'), isEmpty);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'quick toggles and window reattachment restore the matching touch area',
    (tester) async {
      await mount(tester);
      await toggle(tester);
      await tester.pump(const Duration(milliseconds: 80));
      await toggle(tester);
      await tester.pump(const Duration(milliseconds: 30));
      await toggle(tester);
      await tester.pumpAndSettle();
      expect(lastHeight('updateTouchableHeight'), 250);

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        overlayChannel.name,
        overlayChannel.codec.encodeMethodCall(const MethodCall('windowShown')),
        (_) {},
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.settings), findsNothing);
      expect(lastHeight('updateTouchableHeight'), 190);
      expect(calls.where((c) => c.method == 'resizeOverlay'), isEmpty);
      await finish(tester);
    },
  );

  testWidgets(
    'preserves settings and playback controls, then collapses on lock',
    (tester) async {
      await mount(tester);
      await toggle(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('A+'));
      await tester.pump();
      expect(
        tester.widget<TextScroll>(find.byType(TextScroll)).style?.fontSize,
        22,
      );
      await tester.tap(find.text('A-'));
      await tester.pump();
      expect(
        tester.widget<TextScroll>(find.byType(TextScroll)).style?.fontSize,
        20,
      );
      final green = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == Colors.greenAccent,
      );
      await tester.tap(green);
      await tester.pump();
      expect(
        tester.widget<TextScroll>(find.byType(TextScroll)).style?.color,
        Colors.greenAccent,
      );
      await tester.tap(find.byIcon(Icons.play_circle_filled));
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.tap(find.byIcon(Icons.skip_previous));
      expect(
        [lyrics.playToggles, lyrics.nextTracks, lyrics.previousTracks],
        [1, 1, 1],
      );
      await tester.tap(find.byIcon(Icons.close));
      expect(lyrics.closeSent, isTrue);
      await tester.tap(find.byIcon(Icons.lock_open));
      await tester.pumpAndSettle();
      expect(lyrics.lockSent, isTrue);
      expect(lastHeight('updateTouchableHeight'), 190);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets('older Android resizes only before opening and after closing', (
    tester,
  ) async {
    await mount(tester, partialTouch: false);
    final subtitleRect = tester.getRect(find.byType(TextScroll));
    await toggle(tester);
    expect(lastHeight('resizeOverlay'), 250);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(TextScroll)), subtitleRect);
    await toggle(tester);
    await tester.pump(const Duration(milliseconds: 150));
    expect(lastHeight('resizeOverlay'), 250);
    await tester.pump(animation);
    expect(lastHeight('resizeOverlay'), 190);
    expect(calls.where((c) => c.method == 'resizeOverlay'), hasLength(2));
    expect(calls.where((c) => c.method == 'updateTouchableHeight'), isEmpty);
    expect(tester.getRect(find.byType(TextScroll)), subtitleRect);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('legacy reopening cancels the pending collapse animation', (
    tester,
  ) async {
    Completer<void>? pendingResize;
    await mount(
      tester,
      partialTouch: false,
      beforeNativeReply: (call) async {
        if (call.method == 'resizeOverlay') await pendingResize?.future;
      },
    );
    await toggle(tester);
    await tester.pumpAndSettle();
    await toggle(tester);
    await tester.pump(const Duration(milliseconds: 100));
    pendingResize = Completer<void>();
    await toggle(tester);
    await tester.pump(const Duration(milliseconds: 400));
    expect(lastHeight('resizeOverlay'), 250);
    pendingResize.complete();
    pendingResize = null;
    await tester.pumpAndSettle();
    expect(lastHeight('resizeOverlay'), 250);
    expect(calls.where((c) => c.method == 'resizeOverlay'), hasLength(2));
    expect(tester.getRect(find.text('A+')).bottom, lessThanOrEqualTo(250));
    expect(tester.takeException(), isNull);
    await finish(tester);
  });
}
