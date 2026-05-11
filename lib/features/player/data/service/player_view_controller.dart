import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

class PlayerViewController extends ChangeNotifier {
  // 1. 修改这里：类型改为 ValueListenable<double>
  final ValueListenable<double> expandProgress;

  late final AnimationController _lyricsCtrl;
  bool showLyrics = false;

  PlayerViewController({
    required TickerProvider vsync,
    required this.expandProgress,
  }) {
    _lyricsCtrl = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );
    _lyricsCtrl.addListener(notifyListeners);
    // ValueListenable 也有 addListener，完全兼容
    expandProgress.addListener(notifyListeners);
  }

  double get lyricsValue => _lyricsCtrl.value;
  double get expandValue => expandProgress.value;

  void toggleLyrics() {
    showLyrics = !showLyrics;
    if (showLyrics) {
      _lyricsCtrl.forward();
    } else {
      _lyricsCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _lyricsCtrl.removeListener(notifyListeners);
    expandProgress.removeListener(notifyListeners);
    _lyricsCtrl.dispose();
    super.dispose();
  }
}