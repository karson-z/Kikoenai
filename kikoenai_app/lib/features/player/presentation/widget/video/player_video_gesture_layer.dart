import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/player_controller_provider.dart';

enum GestureFeedbackType { none, seek, volume, brightness }

class VideoGestureLayer extends ConsumerStatefulWidget {
  final Widget child;

  const VideoGestureLayer({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<VideoGestureLayer> createState() => _VideoGestureLayerState();
}

class _VideoGestureLayerState extends ConsumerState<VideoGestureLayer> {
  double _dragValue = 0;
  double _initialDragSeconds = 0;
  int _seekOffsetSeconds = 0;

  double _currentBrightness = 0.5;

  GestureFeedbackType _feedbackType = GestureFeedbackType.none;
  Timer? _feedbackTimer;

  bool get isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
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
      controller.seek(Duration(
          seconds: target.clamp(0, state.progressBarState.total.inSeconds)));
      _showFeedback(GestureFeedbackType.seek, seekOffset: deltaSeconds);
    }

    if (event.scrollDelta.dy != 0) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      final delta = event.scrollDelta.dy < 0 ? 0.05 : -0.05;

      if (event.localPosition.dx < screenWidth / 2) {
        _currentBrightness = (_currentBrightness + delta).clamp(0.0, 1.0);
        _showFeedback(GestureFeedbackType.brightness);
      } else {
        double newVolume = (state.volume + delta).clamp(0.0, 1.0);
        controller.setVolume(newVolume);
        _showFeedback(GestureFeedbackType.volume);
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
                  _dragValue = state.progressBarState.current.inSeconds.toDouble();
                  _initialDragSeconds = _dragValue;
                  _showFeedback(GestureFeedbackType.seek, seekOffset: 0);
                },
                onHorizontalDragUpdate: isDesktop
                    ? null
                    : (details) {
                  final total = state.progressBarState.total.inSeconds;
                  if (total <= 0) return;
                  final deltaSeconds = details.primaryDelta! /
                      (MediaQuery.sizeOf(context).width / total * 0.5);
                  _dragValue += deltaSeconds;
                  _dragValue = _dragValue.clamp(0, total.toDouble());

                  final offset = (_dragValue - _initialDragSeconds).toInt();
                  _showFeedback(GestureFeedbackType.seek, seekOffset: offset);
                },
                onHorizontalDragEnd: isDesktop
                    ? null
                    : (_) {
                  if (_feedbackType == GestureFeedbackType.seek) {
                    controller.seek(Duration(seconds: _dragValue.toInt()));
                  }
                },

                // 3. 实际的业务逻辑：调节音量和亮度
                onVerticalDragUpdate: isDesktop
                    ? null
                    : (details) {
                  final screenWidth = MediaQuery.sizeOf(context).width;
                  final localPosition = details.localPosition.dx;
                  final delta = -(details.primaryDelta ?? 0) / 200;

                  if (localPosition < screenWidth / 2) {
                    _currentBrightness = (_currentBrightness + delta).clamp(0.0, 1.0);
                    _showFeedback(GestureFeedbackType.brightness);
                  } else {
                    double newVolume = (state.volume + delta).clamp(0.0, 1.0);
                    controller.setVolume(newVolume);
                    _showFeedback(GestureFeedbackType.volume);
                  }
                },

                // 4. 宣告对拖拽结束感兴趣 (拦截关键)
                onVerticalDragEnd: isDesktop ? null : (_) {},

                // 5. 宣告对拖拽取消感兴趣 (拦截关键)
                onVerticalDragCancel: isDesktop ? null : () {},

                child: widget.child,
              ),
            ),
          ),
          if (_feedbackType != GestureFeedbackType.none)
            Center(
              child: _buildFeedbackWidget(state.volume),
            ),
        ],
      ),
    );
  }

  Widget _buildFeedbackWidget(double volume) {
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
        text = "亮度：${(_currentBrightness * 100).toInt()}%";
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