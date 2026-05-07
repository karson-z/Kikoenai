import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/theme/app_font_preset.dart';
import '../../../../core/constants/app_player.dart';
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

final lyricsControllerProvider =
    NotifierProvider<LyricsController, LyricsState>(() {
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
    final isDesktopModeEnabled = setting.get(
      StorageKeys.desktopLyricsEnabled,
      defaultValue: false,
    );
    final isLocked = setting.get(
      StorageKeys.overlayLyricsIsLocked,
      defaultValue: false,
    );
    final fontSize = setting.get(
      StorageKeys.overlayLyricsFontSize,
      defaultValue: 24.0,
    );
    final fontColorInt = setting.get(
      StorageKeys.overlayLyricsFontColor,
      defaultValue: 0xFFFFFFFF,
    );
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
        case PlayerConstants.syncBusinessState:
          if (payload is Map) {
            final fontPresetKey = payload['fontPreset'] as String?;
            if (fontPresetKey != null && fontPresetKey.isNotEmpty) {
              setting.put(StorageKeys.themeFontPreset, fontPresetKey);
            }
            state = state.copyWith(
              isPlaying: payload['isPlaying'] ?? state.isPlaying,
              text: payload['text'] ?? state.text,
              isWindowVisible:
                  payload['isWindowVisible'] ?? state.isWindowVisible,
            );
          }
          break;
        case PlayerConstants.lockOverlay:
          state = state.copyWith(isLocked: true);
          _manager.lock();
          break;
        case PlayerConstants.unlockOverlay:
          state = state.copyWith(isLocked: false);
          _manager.unlock();
          break;
      }
    });
  }

  SubtitleManager get _manager => ref.read(subtitleManagerProvider);

  void saveCurrentPosition() async {
    final offset = await _manager.getOverlayPosition();
    _manager.sendCommand(PlayerConstants.savePosition, {
      'x': offset.dx,
      'y': offset.dy,
    });
  }

  Future<void> show() async {
    if (state.isDesktopModeEnabled && state.isWindowVisible) return;
    final isLocked = setting.get(
      StorageKeys.overlayLyricsIsLocked,
      defaultValue: false,
    );
    final posX = setting.get(
      StorageKeys.overlayLyricsPositionX,
      defaultValue: 0.0,
    );
    final posY = setting.get(
      StorageKeys.overlayLyricsPositionY,
      defaultValue: 0.0,
    );
    await _manager.showOverlay(isLocked: isLocked, posX: posX, posY: posY);
    state = state.copyWith(isDesktopModeEnabled: true, isWindowVisible: true);
    await setting.put(StorageKeys.desktopLyricsEnabled, true);
    ref.read(overlayLyricSyncProvider).startSync();
  }

  Future<void> hide({bool isUserAction = false}) async {
    if (isUserAction) {
      state = state.copyWith(isDesktopModeEnabled: false);
      await setting.put(StorageKeys.desktopLyricsEnabled, false);
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

  Future<void> toggleLock(bool isLock, {bool isMain = false}) async {
    updateLockState(isLock);
    if (isLock) {
      await _manager.lock(isMain: isMain);
    } else {
      await _manager.unlock(isMain: isMain);
    }
  }

  Future<void> hideFromOverly() async {
    await _manager.sendCommand(PlayerConstants.closeOverlay);
  }

  Future<void> sendToggleLock() async {
    await _manager.sendCommand(PlayerConstants.toggleLock);
  }

  void sendPlayToggle() {
    _manager.sendCommand(
      state.isPlaying ? PlayerConstants.pause : PlayerConstants.play,
    );
  }

  void sendNext() {
    _manager.sendCommand(PlayerConstants.next);
  }

  void sendPrevious() {
    _manager.sendCommand(PlayerConstants.previous);
  }

  void updateFontSize(double size) {
    state = state.copyWith(fontSize: size);
    _manager.sendCommand(PlayerConstants.updateFontSize, {'size': size});
  }

  void toggleOrientation() {
    final newOrientation = state.orientation == Axis.horizontal
        ? Axis.vertical
        : Axis.horizontal;
    state = state.copyWith(orientation: newOrientation);
  }

  void setTextColor(Color color) {
    state = state.copyWith(textColor: color);
    _manager.sendCommand(PlayerConstants.color, {'color': color.toARGB32()});
  }

  void updateFontPreset(AppFontPreset preset) {
    setting.put(StorageKeys.themeFontPreset, preset.storageKey);
    _manager.syncBusinessState({'fontPreset': preset.storageKey});
  }
}
