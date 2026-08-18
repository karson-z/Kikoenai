import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:kikoenai/core/constants/app_player.dart';
import 'package:kikoenai/core/storage/hive_storage.dart';
import 'package:kikoenai/core/theme/app_font_preset.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import '../../../../core/storage/hive_key.dart';
import 'overly_lyrics_manager.dart';
import 'overly_lyrics_sync_service.dart';

final subtitleEndpointProvider = Provider<SubtitleEndpoint>(
  (ref) => SubtitleEndpoint.main,
);

final subtitleManagerProvider = Provider<SubtitleManager>((ref) {
  final manager = SubtitleManager(ref.watch(subtitleEndpointProvider));
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
    final endpoint = ref.watch(subtitleEndpointProvider);
    if (endpoint == SubtitleEndpoint.overlay) {
      _listenToMessagesFromMain(manager);
    }
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

  void _listenToMessagesFromMain(SubtitleManager manager) {
    _eventSubscription = manager.messagesFromMain.listen((event) {
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
          _manager.setOverlayInteractionLocked(true);
          break;
        case PlayerConstants.unlockOverlay:
          state = state.copyWith(isLocked: false);
          _manager.setOverlayInteractionLocked(false);
          break;
      }
    });
    unawaited(manager.init());
  }

  SubtitleManager get _manager => ref.read(subtitleManagerProvider);
  void saveCurrentPositionToMain() async {
    final offset = await _manager.getOverlayPosition();
    _manager.sendToMain(PlayerConstants.savePosition, {
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

  Future<void> resizeOverlayHeight(double height) async {
    await _manager.resizeOverlay(-1, height);
  }

  Future<void> setLockFromMain(bool isLock) async {
    updateLockState(isLock);
    await _manager.sendToOverlay(
      isLock ? PlayerConstants.lockOverlay : PlayerConstants.unlockOverlay,
    );
  }

  Future<void> lockInsideOverlay() async {
    updateLockState(true);
    await _manager.setOverlayInteractionLocked(true);
  }

  Future<void> sendCloseToMain() async {
    await _manager.sendToMain(PlayerConstants.closeOverlay);
  }

  Future<void> sendToggleLockToMain() async {
    await _manager.sendToMain(PlayerConstants.toggleLock);
  }

  void sendPlayToggleToMain() {
    _manager.sendToMain(
      state.isPlaying ? PlayerConstants.pause : PlayerConstants.play,
    );
  }

  void sendNextToMain() {
    _manager.sendToMain(PlayerConstants.next);
  }

  void sendPreviousToMain() {
    _manager.sendToMain(PlayerConstants.previous);
  }

  void updateFontSizeAndSendToMain(double size) {
    state = state.copyWith(fontSize: size);
    _manager.sendToMain(PlayerConstants.updateFontSize, {'size': size});
  }

  void toggleOrientation() {
    final newOrientation = state.orientation == Axis.horizontal
        ? Axis.vertical
        : Axis.horizontal;
    state = state.copyWith(orientation: newOrientation);
  }

  void setTextColorAndSendToMain(Color color) {
    state = state.copyWith(textColor: color);
    _manager.sendToMain(PlayerConstants.color, {'color': color.toARGB32()});
  }

  void updateFontPresetAndSendToOverlay(AppFontPreset preset) {
    setting.put(StorageKeys.themeFontPreset, preset.storageKey);
    _manager.sendToOverlay(PlayerConstants.syncBusinessState, {
      'fontPreset': preset.storageKey,
    });
  }
}
