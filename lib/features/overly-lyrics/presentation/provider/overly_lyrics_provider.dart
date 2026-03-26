import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/service/overlay-lyrics/overly_lyrics_manager.dart';
import '../../data/model/lyrics_state.dart';



// 定义控制器
class LyricsController extends Notifier<LyricsState> {
  late final SubtitleManager _manager;

  @override
  LyricsState build() {
    _manager = SubtitleManager();
    return const LyricsState();
  }

  // 控制悬浮窗的显示与隐藏
  Future<void> toggleOverlay(bool show) async {
    if (show) {
      await _manager.init();
      await _manager.showOverlay();
    } else {
      await _manager.hideOverlay();
    }
    state = state.copyWith(isShowing: show);
  }

  void updateText(String text) {
    state = state.copyWith(text: text);
    _manager.updateText(text);
  }

  void updateFontSize(double size) {
    state = state.copyWith(fontSize: size);
    _manager.setFontSize(size);
  }

  void updateOpacity(double opacity) {
    state = state.copyWith(opacity: opacity);
    _manager.setBackgroundOpacity(opacity);
  }

  void toggleLock(bool lock) {
    state = state.copyWith(isLocked: lock);
    lock ? _manager.lock() : _manager.unlock();
  }

  void toggleDraggable(bool draggable) {
    state = state.copyWith(isDraggable: draggable);
    _manager.setDraggable(draggable);
  }
}

// 暴露 Provider 供 UI 层读取
final lyricsOverlayProvider = NotifierProvider<LyricsController, LyricsState>(() {
  return LyricsController();
});