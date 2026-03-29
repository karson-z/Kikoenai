import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import '../../../../core/storage/hive_key.dart';
import '../../data/model/lyrics_state.dart';
import '../../data/service/overly_lyrics_manager.dart';
import '../../data/service/overly_lyrics_sync_service.dart';

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
  Box<dynamic> get setting => AppStorage.settingsBox;

  @override
  LyricsState build() {
    final manager = ref.watch(subtitleManagerProvider);
    _initManager(manager);
    ref.onDispose(() {
      _eventSubscription?.cancel();
    });

    final isDesktopModeEnabled = setting.get(StorageKeys.desktopLyricsEnabled, defaultValue: false);
    final isLocked = setting.get(StorageKeys.overlayLyricsIsLocked, defaultValue: false);
    final fontSize = setting.get(StorageKeys.overlayLyricsFontSize, defaultValue: 24.0);
    final fontColorInt = setting.get(StorageKeys.overlayLyricsFontColor, defaultValue: 0xFFFFFFFF);

    if (isDesktopModeEnabled) {
      Future.microtask(() async {
        await show();
        ref.read(overlayLyricSyncProvider).startSync();
      });
    }
    return LyricsState(
      isDesktopModeEnabled: isDesktopModeEnabled,
      isLocked: isLocked,
      fontSize: fontSize,
      textColor: Color(fontColorInt),
    );
  }

  Future<void> _initManager(SubtitleManager manager) async {
    await manager.init();

    _eventSubscription = manager.eventStream.listen((event) {
      final action = event['action'];
      final payload = event['payload'];

      switch (action) {
        case 'SYNC_BUSINESS_STATE':
          if (payload is Map) {
            state = state.copyWith(
              isPlaying: payload['isPlaying'] ?? state.isPlaying,
              text: payload['text'] ?? state.text,
              isWindowVisible: payload['isWindowVisible'] ?? state.isWindowVisible,
            );
          }
          break;
        case 'LOCK_OVERLAY':
          state = state.copyWith(isLocked: true);
          _manager.lock();
          break;
        case 'UNLOCK_OVERLAY':
          state = state.copyWith(isLocked: false);
          _manager.unlock();
          break;
      }
    });
  }

  SubtitleManager get _manager => ref.read(subtitleManagerProvider);

  Future<void> show() async {
    if (state.isDesktopModeEnabled && state.isWindowVisible) return;
    final isLocked = setting.get(StorageKeys.overlayLyricsIsLocked, defaultValue: false);
    await _manager.showOverlay(isLocked: isLocked);
    state = state.copyWith(isDesktopModeEnabled: true, isWindowVisible: true);
    setting.put(StorageKeys.desktopLyricsEnabled, true);
    ref.read(overlayLyricSyncProvider).startSync();
  }

  Future<void> hide({bool isUserAction = false}) async {
    if (isUserAction) {
      state = state.copyWith(isDesktopModeEnabled: false);
      setting.put(StorageKeys.desktopLyricsEnabled, false);
      ref.read(overlayLyricSyncProvider).stopSync();
    }
    state = state.copyWith(isWindowVisible: false);
    await _manager.hideOverlay();
  }

  void updateLockState(bool isLocked) {
    state = state.copyWith(isLocked: isLocked);
    setting.put(StorageKeys.overlayLyricsIsLocked, isLocked);
  }

  Future<void> resizeOverlay(double width, double height) async {
    await _manager.resizeOverlay(width, height);
  }

  Future<void> toggleLock({bool isMain = false}) async {
    if (state.isLocked) {
      updateLockState(false);
      await _manager.unlock(isMain: isMain);
      setting.put(StorageKeys.overlayLyricsIsLocked, false);
    } else {
      updateLockState(true);
      await _manager.lock(isMain: isMain);
      setting.put(StorageKeys.overlayLyricsIsLocked, true);
    }
  }

  Future<void> hideFromOverly() async {
    await _manager.sendCommand('CMD_CLOSE_OVERLAY');
  }

  Future<void> sendToggleLock() async {
    await _manager.sendCommand('CMD_TOGGLE_LOCK');
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

  void updateFontSize(double size) {
    state = state.copyWith(fontSize: size);
    setting.put(StorageKeys.overlayLyricsFontSize, size);
    debugPrint('updateFontSize: ${setting.get(StorageKeys.overlayLyricsFontSize, defaultValue: 24.0)}');
  }

  void toggleOrientation() {
    final newOrientation = state.orientation == Axis.horizontal ? Axis.vertical : Axis.horizontal;
    state = state.copyWith(orientation: newOrientation);
  }

  void setTextColor(Color color) {
    state = state.copyWith(textColor: color);
    setting.put(StorageKeys.overlayLyricsFontColor, color.value);
  }
}