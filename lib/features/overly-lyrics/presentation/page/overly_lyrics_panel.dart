import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../../player/presentation/provider/player_lyrics_provider.dart';
import '../provider/overly_lyrics_provider.dart';

class LyricsOverlayContent extends ConsumerStatefulWidget {
  const LyricsOverlayContent({super.key});

  @override
  ConsumerState<LyricsOverlayContent> createState() => _LyricsOverlayContentState();
}

class _LyricsOverlayContentState extends ConsumerState<LyricsOverlayContent> {
  bool _showControls = false;
  Timer? _hideTimer;

  void _showControlsWithTimer() {
    setState(() => _showControls = true);
    _resetHideTimer();
  }

  void _hideControls() {
    if (mounted) setState(() => _showControls = false);
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), _hideControls);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyricsState = ref.watch(lyricsControllerProvider);
    final lyricsCtrl = ref.read(lyricsControllerProvider.notifier);
    final contentBox = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: _showControls ? Colors.black.withOpacity(0.6) : Colors.transparent,
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Text(
                lyricsState.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: lyricsState.fontSize,
                  color: lyricsState.textColor,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(offset: Offset(1, 1), blurRadius: 2.0, color: Colors.black87),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showControls ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white, size: 20),
                        onPressed: () {
                          lyricsCtrl.sendPrevious();
                          _resetHideTimer();
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          lyricsState.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          lyricsCtrl.sendPlayToggle();
                          _resetHideTimer();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white, size: 20),
                        onPressed: () {
                          lyricsCtrl.sendNext();
                          _resetHideTimer();
                        },
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.text_decrease, color: Colors.white, size: 20),
                        onPressed: () {
                          lyricsCtrl.updateFontSize((lyricsState.fontSize - 2).clamp(12.0, 72.0));
                          _resetHideTimer();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.text_increase, color: Colors.white, size: 20),
                        onPressed: () {
                          lyricsCtrl.updateFontSize((lyricsState.fontSize + 2).clamp(12.0, 72.0));
                          _resetHideTimer();
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          lyricsState.orientation == Axis.horizontal
                              ? Icons.view_agenda_outlined
                              : Icons.view_carousel_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          lyricsCtrl.toggleOrientation();
                          _resetHideTimer();
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                        onPressed: () => lyricsCtrl.hide(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (Platform.isWindows || Platform.isLinux) {
      return MouseRegion(
        onEnter: (_) => _showControlsWithTimer(),
        onHover: (_) => _resetHideTimer(),
        onExit: (_) => _hideControls(),
        child: lyricsState.isDraggable && !lyricsState.isLocked
            ? DragToMoveArea(child: contentBox)
            : contentBox,
      );
    } else {
      return GestureDetector(
        onLongPress: _showControlsWithTimer,
        onTapDown: (_) {
          if (_showControls) _resetHideTimer();
        },
        child: contentBox,
      );
    }
  }
}