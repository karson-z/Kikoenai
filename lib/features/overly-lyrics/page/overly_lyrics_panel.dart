import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/theme/theme_view_model.dart';
import 'package:window_manager/window_manager.dart';
import 'package:text_scroll/text_scroll.dart';
import '../provider/overly_lyrics_manager.dart';
import '../provider/overly_lyrics_provider.dart';

class LyricsOverlayContent extends ConsumerStatefulWidget {
  const LyricsOverlayContent({super.key});

  @override
  ConsumerState<LyricsOverlayContent> createState() =>
      _LyricsOverlayContentState();
}

class _LyricsOverlayContentState extends ConsumerState<LyricsOverlayContent>
    with SingleTickerProviderStateMixin {
  static const _settingsAnimationDuration = Duration(milliseconds: 300);

  bool _showControls = false;
  bool _showSettings = false;
  bool _settingsOpening = false;
  bool? _supportsPartialTouchRegion;
  int _nativeRevision = 0;
  int _settingsRevision = 0;
  late final AnimationController _settingsAnimation;
  late final CurvedAnimation _settingsProgress;
  StreamSubscription<void>? _windowShownSubscription;
  Future<void> _nativeChange = Future<void>.value();

  final List<Color> _presetColors = [
    Colors.white,
    Colors.greenAccent,
    Colors.pinkAccent,
    Colors.lightBlueAccent,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _settingsAnimation = AnimationController(
      vsync: this,
      duration: _settingsAnimationDuration,
    );
    _settingsProgress = CurvedAnimation(
      parent: _settingsAnimation,
      curve: Curves.easeInOut,
    )..addListener(_syncAnimatedTouchArea);
    _settingsAnimation.addStatusListener((status) {
      if (status == AnimationStatus.dismissed &&
          _supportsPartialTouchRegion == false) {
        unawaited(_setWindowHeight(SubtitleManager.defaultOverlayHeight));
      }
    });
    _windowShownSubscription = ref
        .read(subtitleManagerProvider)
        .windowShown
        .listen((_) {
          if (!mounted) return;
          _nativeRevision++;
          _settingsRevision++;
          setState(() {
            _showControls = false;
            _showSettings = false;
          });
          _settingsAnimation.reset();
        });
    unawaited(_loadTouchRegionSupport());
  }

  Future<void> _loadTouchRegionSupport() async {
    try {
      final supported = await ref
          .read(subtitleManagerProvider)
          .supportsPartialTouchRegion();
      if (mounted) setState(() => _supportsPartialTouchRegion = supported);
    } catch (error) {
      debugPrint('Failed to query subtitle overlay touch support: $error');
      if (mounted) setState(() => _supportsPartialTouchRegion = false);
    }
  }

  void _syncAnimatedTouchArea() {
    if (_supportsPartialTouchRegion != true) return;
    // Keep only the currently revealed area touchable, including mid-animation.
    final height =
        SubtitleManager.defaultOverlayHeight +
        SubtitleManager.settingsPanelHeight * _settingsProgress.value;
    unawaited(_setWindowHeight(height.roundToDouble()));
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (!_showControls) {
        _showSettings = false;
        _settingsRevision++;
      }
    });
    if (!_showControls) _settingsAnimation.reverse();
  }

  Future<void> _toggleSettings() async {
    if (_settingsOpening || _supportsPartialTouchRegion == null) return;
    final revision = ++_settingsRevision;
    if (_showSettings) {
      setState(() => _showSettings = false);
      _settingsAnimation.reverse();
      return;
    }

    // Older Android versions need room before the Flutter reveal starts.
    if (_supportsPartialTouchRegion == false) {
      _settingsOpening = true;
      // An unfinished close must not queue a shrink while reopening awaits
      // the native window update.
      _settingsAnimation.stop();
      await _setWindowHeight(SubtitleManager.expandedOverlayHeight);
      _settingsOpening = false;
    }
    if (!mounted || !_showControls || revision != _settingsRevision) {
      if (mounted) {
        unawaited(_setWindowHeight(SubtitleManager.defaultOverlayHeight));
      }
      return;
    }
    setState(() => _showSettings = true);
    _settingsAnimation.forward();
  }

  Future<void> _setWindowHeight(double height) {
    final revision = ++_nativeRevision;
    // Serialize native updates and discard obsolete requests after quick toggles.
    _nativeChange = _nativeChange
        .then((_) async {
          if (!mounted || revision != _nativeRevision) return;
          if (_supportsPartialTouchRegion == true) {
            await ref
                .read(subtitleManagerProvider)
                .setOverlayTouchableHeight(height);
          } else {
            await ref
                .read(lyricsControllerProvider.notifier)
                .resizeOverlayHeight(height);
          }
        })
        .catchError((Object error) {
          debugPrint('Failed to update subtitle overlay touch area: $error');
        });
    return _nativeChange;
  }

  @override
  void dispose() {
    _nativeRevision++;
    unawaited(_windowShownSubscription?.cancel());
    _settingsProgress.dispose();
    _settingsAnimation.dispose();
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
                  _buildBottomBar(lyricsCtrl, isLocked, isPlaying),
              ],
            ),
          ),
        ),
      ),
    );

    final overlay = SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          SizedBox(
            height: SubtitleManager.defaultOverlayHeight,
            width: double.infinity,
            child: contentBox,
          ),
          Positioned(
            top: SubtitleManager.defaultOverlayHeight,
            left: 0,
            right: 0,
            child: SizeTransition(
              sizeFactor: _settingsProgress,
              alignment: Alignment.topCenter,
              child: IgnorePointer(
                ignoring: !_showSettings,
                child: _buildSettingsPanel(lyricsCtrl, fontSize, textColor),
              ),
            ),
          ),
        ],
      ),
    );

    if (Platform.isWindows || Platform.isLinux) {
      return !isLocked ? DragToMoveArea(child: overlay) : overlay;
    }
    return overlay;
  }

  Widget _buildHeaderBar(LyricsController lyricsCtrl) {
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
    LyricsController lyricsCtrl,
    bool isLocked,
    bool isPlaying,
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
                onPressed: _supportsPartialTouchRegion == null
                    ? null
                    : _toggleSettings,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsPanel(
    LyricsController lyricsCtrl,
    double fontSize,
    Color textColor,
  ) {
    return SizedBox(
      height: SubtitleManager.settingsPanelHeight,
      width: double.infinity,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                final isSelected = color.toARGB32() == textColor.toARGB32();
                return GestureDetector(
                  onTap: () => lyricsCtrl.setTextColorAndSendToMain(color),
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
      ),
    );
  }
}
