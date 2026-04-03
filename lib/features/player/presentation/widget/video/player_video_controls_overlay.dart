import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/features/player/presentation/widget/video/video_bottom_bar.dart';
import 'package:kikoenai/features/player/presentation/widget/video/video_center_controls.dart';

class PlayerVideoControlsOverlay extends ConsumerStatefulWidget {
  const PlayerVideoControlsOverlay({super.key});

  @override
  ConsumerState<PlayerVideoControlsOverlay> createState() =>
      _PlayerVideoControlsOverlayState();
}

class _PlayerVideoControlsOverlayState extends ConsumerState<PlayerVideoControlsOverlay> {
  bool _isVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _isVisible = false);
      }
    });
  }

  void _toggleVisibility() {
    setState(() => _isVisible = !_isVisible);
    if (_isVisible) _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleVisibility,
      child: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          color: Colors.black38,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Center(
                child: VideoCenterControls(),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _startHideTimer(),
                  onPanDown: (_) => _hideTimer?.cancel(),
                  onPanEnd: (_) => _startHideTimer(),
                  child: const VideoBottomBar(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}