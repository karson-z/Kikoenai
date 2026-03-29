import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../provider/overly_lyrics_provider.dart';

class LyricsOverlayContent extends ConsumerStatefulWidget {
  const LyricsOverlayContent({super.key});

  @override
  ConsumerState<LyricsOverlayContent> createState() => _LyricsOverlayContentState();
}

class _LyricsOverlayContentState extends ConsumerState<LyricsOverlayContent> {
  bool _showControls = false;
  bool _showSettings = false;

  final List<Color> _presetColors = [
    Colors.white,
    Colors.greenAccent,
    Colors.pinkAccent,
    Colors.lightBlueAccent,
    Colors.amber,
  ];

  void _toggleControls() async {
    setState(() {
      _showControls = !_showControls;
      if (!_showControls) {
        _showSettings = false;
      }
    });

    if (Platform.isAndroid) {
      final lyricsCtrl = ref.read(lyricsControllerProvider.notifier);
      if (_showControls) {
        await lyricsCtrl.resizeOverlay(-1, 200);
      } else {
        await lyricsCtrl.resizeOverlay(-1, 120);
      }
    }
  }

  void _toggleSettings() async {
    setState(() {
      _showSettings = !_showSettings;
    });

    if (Platform.isAndroid) {
      final lyricsCtrl = ref.read(lyricsControllerProvider.notifier);
      if (_showSettings) {
        await lyricsCtrl.resizeOverlay(-1, 250);
      } else {
        await lyricsCtrl.resizeOverlay(-1, 200);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lyricsState = ref.watch(lyricsControllerProvider);
    final lyricsCtrl = ref.read(lyricsControllerProvider.notifier);

    final contentBox = Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _toggleControls,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: _showControls ? Colors.black.withOpacity(0.6) : Colors.transparent,
          child: Stack(
            children: [
              // ================= 1. 居中歌词 =================
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    lyricsState.text,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      fontSize: lyricsState.fontSize,
                      color: lyricsState.textColor,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(offset: Offset(1, 1), blurRadius: 3.0, color: Colors.black87),
                      ],
                    ),
                  ),
                ),
              ),

              // ================= 2. 顶部栏 =================
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showControls ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 0.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.music_note, color: Colors.white, size: 24),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.close, color: Colors.redAccent, size: 24),
                            onPressed: () {
                              lyricsCtrl.hideFromOverly();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ================= 3. 底部播控与设置栏 =================
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _showControls ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 确保 Column 收缩到内容高度
                      children: [
                        // --- 播控按钮 ---
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0, top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  lyricsState.isLocked ? Icons.lock : Icons.lock_open,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () {
                                  lyricsCtrl.toggleLock();
                                  lyricsCtrl.sendToggleLock();
                                },
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
                                onPressed: () => lyricsCtrl.sendPrevious(),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  lyricsState.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 42,
                                ),
                                onPressed: () => lyricsCtrl.sendPlayToggle(),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                                onPressed: () => lyricsCtrl.sendNext(),
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

                        // --- 设置面板 (放在播控按钮正下方) ---
                        if (_showSettings)
                          GestureDetector(
                            onTap: () {}, // 吞噬点击事件
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              color: Colors.black87,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: () => lyricsCtrl.updateFontSize((lyricsState.fontSize - 2).clamp(16.0, 24.0)),
                                    child: const Text('A-', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                  GestureDetector(
                                    onTap: () => lyricsCtrl.updateFontSize((lyricsState.fontSize + 2).clamp(16.0, 24.0)),
                                    child: const Text('A+', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  ),
                                  Container(width: 1, height: 20, color: Colors.white38),
                                  ..._presetColors.map((color) {
                                    final isSelected = color.value == lyricsState.textColor.value;
                                    return GestureDetector(
                                      onTap: () => lyricsCtrl.setTextColor(color),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? Colors.white : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (Platform.isWindows || Platform.isLinux) {
      return !lyricsState.isLocked ? DragToMoveArea(child: contentBox) : contentBox;
    } else {
      return contentBox;
    }
  }
}