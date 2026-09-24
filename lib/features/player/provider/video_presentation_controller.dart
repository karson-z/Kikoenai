import 'package:flutter/material.dart';

/// Presentation state only; playback remains in playerControllerProvider.
class VideoPresentationController extends ChangeNotifier {
  VideoPresentationController({required TickerProvider vsync})
      : _animation = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 320),
        ) {
    _animation.addListener(notifyListeners);
  }

  final AnimationController _animation;
  Offset _floatingOffset = Offset.zero;

  double get progress => _animation.value;
  Offset get floatingOffset => _floatingOffset;

  Future<void> expand() => _animation.animateTo(1, curve: Curves.easeOutCubic);

  Future<void> collapse() =>
      _animation.animateTo(0, curve: Curves.easeOutCubic);

  void reset({required bool expanded}) {
    _animation.stop();
    _animation.value = expanded ? 1 : 0;
    _floatingOffset = Offset.zero;
    notifyListeners();
  }

  void setFloatingOffset(Offset offset) {
    if (_floatingOffset == offset) return;
    _floatingOffset = offset;
    notifyListeners();
  }

  @override
  void dispose() {
    _animation.removeListener(notifyListeners);
    _animation.dispose();
    super.dispose();
  }
}
