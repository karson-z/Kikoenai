import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/player_controller_provider.dart';

enum GestureFeedbackType { none, seek, volume, brightness }

class VideoGestureLayer extends ConsumerStatefulWidget {
  final Widget child;

  const VideoGestureLayer({super.key, required this.child});

  @override
  ConsumerState<VideoGestureLayer> createState() => _VideoGestureLayerState();
}

class _VideoGestureLayerState extends ConsumerState<VideoGestureLayer> {
  double _dragValue = 0;
  double _initialDragSeconds = 0;
  int _seekOffsetSeconds = 0;

  double _pendingBrightnessDelta = 0;
  bool _brightnessReady = false;
  bool _brightnessUnavailable = false;
  bool _brightnessAdjusted = false;
  GestureFeedbackType? _verticalDragType;
  late final PlayerController _playerController;

  GestureFeedbackType _feedbackType = GestureFeedbackType.none;
  Timer? _feedbackTimer;

  bool get isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    _playerController = ref.read(playerControllerProvider.notifier);
    unawaited(_loadBrightness());
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    if (_brightnessAdjusted) {
      unawaited(_playerController.resetScreenBrightness());
    }
    super.dispose();
  }

  Future<void> _loadBrightness() async {
    final loaded = await _playerController.loadScreenBrightness();
    if (!mounted) return;
    if (!loaded) {
      _brightnessUnavailable = true;
      _pendingBrightnessDelta = 0;
      return;
    }
    _brightnessReady = true;
    final pendingDelta = _pendingBrightnessDelta;
    _pendingBrightnessDelta = 0;
    if (pendingDelta != 0) _adjustBrightness(pendingDelta);
  }

  void _adjustVolume(double delta) {
    final volume = ref.read(playerControllerProvider).volume;
    _playerController.setVolume(volume + delta);
    _showFeedback(GestureFeedbackType.volume);
  }

  void _adjustBrightness(double delta) {
    if (_brightnessUnavailable) return;
    if (!_brightnessReady) {
      _pendingBrightnessDelta = (_pendingBrightnessDelta + delta)
          .clamp(-1.0, 1.0)
          .toDouble();
      return;
    }

    final brightness = ref.read(playerControllerProvider).screenBrightness;
    final next = (brightness + delta).clamp(0.0, 1.0).toDouble();
    if (next == brightness) return;
    _brightnessAdjusted = true;
    unawaited(_playerController.setScreenBrightness(next));
    _showFeedback(GestureFeedbackType.brightness);
  }

  void _showFeedback(GestureFeedbackType type, {int? seekOffset}) {
    setState(() {
      _feedbackType = type;
      if (seekOffset != null) {
        _seekOffsetSeconds = seekOffset;
      }
    });

    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _feedbackType = GestureFeedbackType.none;
        });
      }
    });
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (!isDesktop || event is! PointerScrollEvent) return;

    final state = ref.read(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);

    if (event.scrollDelta.dx != 0) {
      final deltaSeconds = event.scrollDelta.dx > 0 ? 5 : -5;
      final target = state.progressBarState.current.inSeconds + deltaSeconds;
      controller.seek(
        Duration(
          seconds: target.clamp(0, state.progressBarState.total.inSeconds),
        ),
      );
      _showFeedback(GestureFeedbackType.seek, seekOffset: deltaSeconds);
    }

    if (event.scrollDelta.dy != 0) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      final delta = event.scrollDelta.dy < 0 ? 0.05 : -0.05;

      if (event.localPosition.dx < screenWidth / 2) {
        _adjustBrightness(delta);
      } else {
        _adjustVolume(delta);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);

    return MouseRegion(
      onHover: (_) {
        if (isDesktop) {
          controller.showControlsAndResetTimer();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Listener(
              onPointerSignal: _handlePointerSignal,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (isDesktop) {
                    state.playing ? controller.pause() : controller.play();
                  } else {
                    controller.toggleControlsVisibility();
                  }
                },
                onDoubleTap: () {
                  if (isDesktop) {
                    controller.toggleVideoFullScreen();
                  } else {
                    state.playing ? controller.pause() : controller.play();
                  }
                },
                onHorizontalDragStart: isDesktop
                    ? null
                    : (_) {
                        _dragValue = state.progressBarState.current.inSeconds
                            .toDouble();
                        _initialDragSeconds = _dragValue;
                        _showFeedback(GestureFeedbackType.seek, seekOffset: 0);
                      },
                onHorizontalDragUpdate: isDesktop
                    ? null
                    : (details) {
                        final total = state.progressBarState.total.inSeconds;
                        if (total <= 0) return;
                        final deltaSeconds =
                            details.primaryDelta! /
                            (MediaQuery.sizeOf(context).width / total * 0.5);
                        _dragValue += deltaSeconds;
                        _dragValue = _dragValue.clamp(0, total.toDouble());

                        final offset = (_dragValue - _initialDragSeconds)
                            .toInt();
                        _showFeedback(
                          GestureFeedbackType.seek,
                          seekOffset: offset,
                        );
                      },
                onHorizontalDragEnd: isDesktop
                    ? null
                    : (_) {
                        if (_feedbackType == GestureFeedbackType.seek) {
                          controller.seek(
                            Duration(seconds: _dragValue.toInt()),
                          );
                        }
                      },

                // 3. 实际的业务逻辑：调节音量和亮度
                dragStartBehavior: DragStartBehavior.down,
                onVerticalDragUpdate: isDesktop
                    ? null
                    : (details) {
                        final delta = -(details.primaryDelta ?? 0) / 200;

                        if (_verticalDragType ==
                            GestureFeedbackType.brightness) {
                          _adjustBrightness(delta);
                        } else {
                          _adjustVolume(delta);
                        }
                      },
                onVerticalDragStart: isDesktop
                    ? null
                    : (details) {
                        final screenWidth = MediaQuery.sizeOf(context).width;
                        final isBrightness =
                            details.localPosition.dx < screenWidth / 2;
                        _verticalDragType = isBrightness
                            ? GestureFeedbackType.brightness
                            : GestureFeedbackType.volume;
                      },
                onVerticalDragEnd: isDesktop
                    ? null
                    : (_) => _verticalDragType = null,
                onVerticalDragCancel: isDesktop
                    ? null
                    : () => _verticalDragType = null,

                child: widget.child,
              ),
            ),
          ),
          if (_feedbackType != GestureFeedbackType.none)
            Center(
              child: _buildFeedbackWidget(
                state.volume,
                state.screenBrightness,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedbackWidget(double volume, double brightness) {
    String text = '';

    switch (_feedbackType) {
      case GestureFeedbackType.seek:
        if (_seekOffsetSeconds == 0) return const SizedBox.shrink();
        text = "${_seekOffsetSeconds > 0 ? '+' : ''}$_seekOffsetSeconds 秒";
        break;
      case GestureFeedbackType.volume:
        text = "音量：${(volume * 100).toInt()}%";
        break;
      case GestureFeedbackType.brightness:
        text = "亮度：${(brightness * 100).toInt()}%";
        break;
      case GestureFeedbackType.none:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none, // 防止被上层组件强制覆盖样式
        ),
      ),
    );
  }
}
