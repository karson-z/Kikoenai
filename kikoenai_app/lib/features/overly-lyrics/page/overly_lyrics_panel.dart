import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/theme/theme_view_model.dart';
import 'package:window_manager/window_manager.dart';
import 'package:text_scroll/text_scroll.dart';
import '../provider/overly_lyrics_provider.dart';

class LyricsOverlayContent extends ConsumerStatefulWidget {
  const LyricsOverlayContent({super.key});

  @override
  ConsumerState<LyricsOverlayContent> createState() =>
      _LyricsOverlayContentState();
}

class _LyricsOverlayContentState extends ConsumerState<LyricsOverlayContent> {
  static const _resizeAnimationDuration = Duration(milliseconds: 300);
  static const double _lyricsOnlyHeight = 250;
  static const double _controlsHeight = 350;
  static const double _settingsHeight = 410;

  bool _showControls = false;
  bool _showSettings = false;
  int _resizeRevision = 0;

  final List<Color> _presetColors = [
    Colors.white,
    Colors.greenAccent,
    Colors.pinkAccent,
    Colors.lightBlueAccent,
    Colors.amber,
  ];

  void _toggleControls() {
    final willShowControls = !_showControls;
    if (willShowControls) {
      _requestOverlayHeight(_controlsHeight);
    }
    setState(() {
      _showControls = willShowControls;
      if (!_showControls) {
        _showSettings = false;
      }
    });
    if (!willShowControls) {
      _requestOverlayHeight(_lyricsOnlyHeight, afterAnimation: true);
    }
  }

  void _toggleSettings() {
    final willShowSettings = !_showSettings;
    if (willShowSettings) {
      _requestOverlayHeight(_settingsHeight);
    }
    setState(() {
      _showSettings = willShowSettings;
    });
    if (!willShowSettings) {
      _requestOverlayHeight(_controlsHeight, afterAnimation: true);
    }
  }

  void _requestOverlayHeight(double height, {bool afterAnimation = false}) {
    final revision = ++_resizeRevision;
    unawaited(
      Future<void>(() async {
        if (afterAnimation) {
          await Future<void>.delayed(_resizeAnimationDuration);
        }
        if (!mounted || revision != _resizeRevision) return;
        await ref
            .read(lyricsControllerProvider.notifier)
            .resizeOverlayHeight(height);
      }),
    );
  }

  @override
  void dispose() {
    _resizeRevision++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyricsCtrl = ref.read(lyricsControllerProvider.notifier);
    final fontPreset = ref.watch(
      themeNotifierProvider.select((s) => s.fontPreset),
    );

    final isLocked = ref.watch(
      lyricsControllerProvider.select((s) => s.isLocked),
    );
    final text = ref.watch(lyricsControllerProvider.select((s) => s.text));
    final fontSize = ref.watch(
      lyricsControllerProvider.select((s) => s.fontSize),
    );
    final textColor = ref.watch(
      lyricsControllerProvider.select((s) => s.textColor),
    );
    final isPlaying = ref.watch(
      lyricsControllerProvider.select((s) => s.isPlaying),
    );

    final contentBox = Material(
      color: Colors.transparent,
      child: Listener(
        onPointerUp: (event) {
          if (!isLocked) {
            lyricsCtrl.saveCurrentPositionToMain();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _toggleControls,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: _showControls
                ? Colors.black.withValues(alpha: 0.6)
                : Colors.transparent,
            child: Column(
              children: [
                if (_showControls) _buildHeaderBar(lyricsCtrl),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: TextScroll(
                        text,
                        mode: TextScrollMode.endless,
                        velocity: const Velocity(
                          pixelsPerSecond: Offset(40, 0),
                        ),
                        delayBefore: const Duration(seconds: 2),
                        pauseBetween: const Duration(seconds: 2),
                        style: fontPreset.applyToTextStyle(
                          TextStyle(
                            fontSize: fontSize,
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 3.0,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_showControls)
                  _buildBottomBar(
                    lyricsCtrl,
                    isLocked,
                    isPlaying,
                    fontSize,
                    textColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (Platform.isWindows || Platform.isLinux) {
      return !isLocked ? DragToMoveArea(child: contentBox) : contentBox;
    } else {
      return contentBox;
    }
  }

  Widget _buildHeaderBar(dynamic lyricsCtrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.music_note, color: Colors.white, size: 24),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 24),
            onPressed: () => lyricsCtrl.sendCloseToMain(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    dynamic lyricsCtrl,
    bool isLocked,
    bool isPlaying,
    double fontSize,
    Color textColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  isLocked ? Icons.lock : Icons.lock_open,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  lyricsCtrl.lockInsideOverlay();
                  lyricsCtrl.sendToggleLockToMain();
                  _toggleControls();
                },
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => lyricsCtrl.sendPreviousToMain(),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 42,
                ),
                onPressed: () => lyricsCtrl.sendPlayToggleToMain(),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => lyricsCtrl.sendNextToMain(),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.settings,
                  color: _showSettings ? Colors.blueAccent : Colors.white,
                  size: 24,
                ),
                onPressed: _toggleSettings,
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: _resizeAnimationDuration,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _showSettings
              ? GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    color: Colors.black87,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => lyricsCtrl.updateFontSizeAndSendToMain(
                            (fontSize - 2).clamp(16.0, 24.0),
                          ),
                          child: const Text(
                            'A-',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => lyricsCtrl.updateFontSizeAndSendToMain(
                            (fontSize + 2).clamp(16.0, 24.0),
                          ),
                          child: const Text(
                            'A+',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(width: 1, height: 20, color: Colors.white38),
                        ..._presetColors.map((color) {
                          final isSelected =
                              color.toARGB32() == textColor.toARGB32();
                          return GestureDetector(
                            onTap: () =>
                                lyricsCtrl.setTextColorAndSendToMain(color),
                            child: Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}
