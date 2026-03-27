import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../player/presentation/provider/player_controller_provider.dart';
import '../../data/model/lyrics_state.dart';
import '../../data/service/overly_lyrics_manager.dart';

final subtitleManagerProvider = Provider<SubtitleManager>((ref) {
  final manager = SubtitleManager();
  ref.onDispose(() {
    manager.dispose();
  });
  return manager;
});

final lyricsControllerProvider = NotifierProvider<LyricsController, LyricsState>(() {
  return LyricsController();
});

class LyricsController extends Notifier<LyricsState> {
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  @override
  LyricsState build() {
    final manager = ref.watch(subtitleManagerProvider);

    _initManager(manager);

    ref.onDispose(() {
      _eventSubscription?.cancel();
    });

    return const LyricsState();
  }

  Future<void> _initManager(SubtitleManager manager) async {
    await manager.init();

    _eventSubscription = manager.eventStream.listen((event) {
      final action = event['action'];
      final payload = event['payload'];
      switch (action) {
        case 'UPDATE_POSITION':
          if (payload is Offset) {
            state = state.copyWith(position: payload);
          } else if (payload is Map && payload['dx'] != null) {
            state = state.copyWith(
              position: Offset(payload['dx'] as double, payload['dy'] as double),
            );
          }
          break;
        case 'SYNC_BUSINESS_STATE':
          if (payload is Map) {
            state = state.copyWith(
              text: payload['text'] ?? state.text,
              isPlaying: payload['isPlaying'] ?? state.isPlaying,
            );
          }
          break;
      }
    });
  }

  SubtitleManager get _manager => ref.read(subtitleManagerProvider);

  Future<void> show() async {
    await _manager.showOverlay();
    state = state.copyWith(isShowing: true);
  }

  Future<void> hide() async {
    state = state.copyWith(isShowing: false);
    await _manager.hideOverlay();
  }

  Future<void> toggleLock() async {
    if (state.isLocked) {
      await _manager.unlock();
      state = state.copyWith(isLocked: false);
    } else {
      await _manager.lock();
      state = state.copyWith(isLocked: true);
    }
  }

  void updateFontSize(double size) {
    state = state.copyWith(fontSize: size);
    _manager.setFontSize(size);
  }

  void toggleOrientation() {
    final newOrientation = state.orientation == Axis.horizontal ? Axis.vertical : Axis.horizontal;
    state = state.copyWith(orientation: newOrientation);
    _manager.setLayoutOrientation(newOrientation);
  }

  Future<void> setOpacity(double opacity) async {
    await _manager.setBackgroundOpacity(opacity);
    state = state.copyWith(opacity: opacity);
  }

  Future<void> setWindowSize(Size size) async {
    await _manager.setWindowSize(size.width, size.height);
    state = state.copyWith(windowSize: size);
  }

  Future<void> setDraggable(bool isDraggable) async {
    await _manager.setDraggable(isDraggable);
    state = state.copyWith(isDraggable: isDraggable);
  }

  void setTextColor(Color color) {
    state = state.copyWith(textColor: color);
  }

  void setBackgroundColor(Color color) {
    state = state.copyWith(backgroundColor: color);
  }

  void sendPlayToggle() {
    _manager.sendCommand(state.isPlaying ? 'CMD_PAUSE' : 'CMD_PLAY');
  }

  void sendNext() {
    _manager.sendCommand('CMD_NEXT');
  }

  void sendPrevious() {
    _manager.sendCommand('CMD_PREVIOUS');
  }
}