import 'dart:async';
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
  }

  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lyricsCtrl = ref.read(lyricsControllerProvider.notifier);

    final isLocked = ref.watch(lyricsControllerProvider.select((s) => s.isLocked));
    final text = ref.watch(lyricsControllerProvider.select((s) => s.text));
    final fontSize = ref.watch(lyricsControllerProvider.select((s) => s.fontSize));
    final textColor = ref.watch(lyricsControllerProvider.select((s) => s.textColor));
    final isPlaying = ref.watch(lyricsControllerProvider.select((s) => s.isPlaying));

    final contentBox = Material(
      color: Colors.transparent,
      child: Listener(
        onPointerUp: (event) {
          if (!isLocked) {
            lyricsCtrl.saveCurrentPosition();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _toggleControls,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: _showControls ? Colors.black.withOpacity(0.6) : Colors.transparent,
            child: Column(
              children: [
                if (_showControls) _buildHeaderBar(lyricsCtrl),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: AutoScrollText(
                        text: text,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(offset: Offset(1, 1), blurRadius: 3.0, color: Colors.black87),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_showControls)
                  _buildBottomBar(lyricsCtrl, isLocked, isPlaying, fontSize, textColor),
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
            onPressed: () => lyricsCtrl.hideFromOverly(),
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
                  lyricsCtrl.toggleLock(true);
                  lyricsCtrl.sendToggleLock();
                  _toggleControls();
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
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
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
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _showSettings
              ? GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => lyricsCtrl.updateFontSize((fontSize - 2).clamp(16.0, 24.0)),
                    child: const Text('A-', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  GestureDetector(
                    onTap: () => lyricsCtrl.updateFontSize((fontSize + 2).clamp(16.0, 24.0)),
                    child: const Text('A+', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.white38,
                  ),
                  ..._presetColors.map((color) {
                    final isSelected = color.toARGB32() == textColor.value;
                    return GestureDetector(
                      onTap: () => lyricsCtrl.setTextColor(color),
                      child: Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.all(4.0),
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
          )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

class AutoScrollText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const AutoScrollText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  State<AutoScrollText> createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<AutoScrollText> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant AutoScrollText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timer = Timer(const Duration(seconds: 2), _scroll);
    });
  }

  void _scroll() async {
    if (!mounted || !_scrollController.hasClients) return;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    if (maxScrollExtent > 0) {
      final duration = Duration(milliseconds: (maxScrollExtent * 25).toInt());

      await _scrollController.animateTo(
        maxScrollExtent,
        duration: duration,
        curve: Curves.linear,
      );

      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }

      _startAutoScroll();
    } else {
      _timer = Timer(const Duration(seconds: 1), _scroll);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      widget.text,
      style: widget.style,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: textWidget,
        );
      },
    );
  }
}