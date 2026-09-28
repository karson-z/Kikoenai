import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum VideoFloatingDock { left, right }

/// Presentation state only; playback remains in playerControllerProvider.
class VideoPresentationController extends ChangeNotifier {
  VideoPresentationController({
    required TickerProvider vsync,
    this.beforeCollapse,
  }) : _animation = AnimationController(
         vsync: vsync,
         duration: const Duration(milliseconds: 320),
       ),
       _floatingAnimation = AnimationController(
         vsync: vsync,
         duration: const Duration(milliseconds: 220),
       ) {
    _animation.addListener(notifyListeners);
    _floatingAnimation.addListener(_updateFloatingAnimation);
  }

  final AnimationController _animation;
  final AnimationController _floatingAnimation;
  final AsyncCallback? beforeCollapse;
  Offset _floatingOffset = Offset.zero;
  Animatable<Offset>? _floatingTween;
  VideoFloatingDock? _dockedSide;
  bool _isFloatingHidden = false;
  bool _isFloatingDragging = false;
  bool _isCollapsing = false;
  bool _disposed = false;
  int _transition = 0;
  int _floatingTransition = 0;

  double get progress => _animation.value;
  Offset get floatingOffset => _floatingOffset;
  VideoFloatingDock? get dockedSide => _dockedSide;
  bool get isFloatingHidden => _isFloatingHidden;
  bool get isFloatingDragging => _isFloatingDragging;
  bool get isFloatingSettling => _floatingTween != null;

  Future<void> expand() {
    _transition++;
    return _animation.animateTo(1, curve: Curves.easeOutCubic);
  }

  Future<void> collapse() async {
    if (_disposed || _isCollapsing) return;
    _isCollapsing = true;
    final transition = _transition;
    try {
      // Fullscreen pins the stage to its expanded rect. Let the host restore
      // its window/orientation before animating back to the floating rect.
      await beforeCollapse?.call();
      if (_disposed || transition != _transition) return;
      await _animation
          .animateTo(
            0,
            duration: const Duration(milliseconds: 240),
            curve: Curves.fastOutSlowIn,
          )
          .orCancel;
    } on TickerCanceled {
      // A media change, expansion or disposal superseded this transition.
    } finally {
      _isCollapsing = false;
    }
  }

  void reset({required bool expanded}) {
    _transition++;
    _floatingTransition++;
    _animation.stop();
    _floatingAnimation.stop();
    _animation.value = expanded ? 1 : 0;
    _floatingOffset = Offset.zero;
    _floatingTween = null;
    _dockedSide = null;
    _isFloatingHidden = false;
    _isFloatingDragging = false;
    notifyListeners();
  }

  void beginFloatingInteraction(Offset visibleOffset) {
    _floatingTransition++;
    _floatingAnimation.stop();
    _floatingTween = null;
    _dockedSide = null;
    _floatingOffset = visibleOffset;
    _isFloatingHidden = false;
    _isFloatingDragging = true;
    notifyListeners();
  }

  void setFloatingOffset(Offset offset) {
    if (_floatingOffset == offset) return;
    _floatingOffset = offset;
    notifyListeners();
  }

  Future<void> animateFloatingOffset({
    required Offset offset,
    required VideoFloatingDock dockedSide,
    required bool hidden,
    Duration duration = const Duration(milliseconds: 220),
    Curve curve = Curves.easeOutCubic,
  }) async {
    if (_disposed) return;
    _floatingTransition++;
    final transition = _floatingTransition;
    _floatingAnimation.stop();
    _floatingAnimation.duration = duration;
    _floatingTween = Tween(
      begin: _floatingOffset,
      end: offset,
    ).chain(CurveTween(curve: curve));
    _dockedSide = dockedSide;
    _isFloatingHidden = hidden;
    _isFloatingDragging = false;
    try {
      await _floatingAnimation.forward(from: 0).orCancel;
      if (_disposed || transition != _floatingTransition) return;
      _floatingOffset = offset;
      _dockedSide = dockedSide;
      _floatingTween = null;
      notifyListeners();
    } on TickerCanceled {
      // A new drag, resize, or presentation transition superseded the snap.
    }
  }

  void _updateFloatingAnimation() {
    final tween = _floatingTween;
    if (tween == null) return;
    _floatingOffset = tween.evaluate(_floatingAnimation);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _animation.removeListener(notifyListeners);
    _floatingAnimation.removeListener(_updateFloatingAnimation);
    _animation.dispose();
    _floatingAnimation.dispose();
    super.dispose();
  }
}
