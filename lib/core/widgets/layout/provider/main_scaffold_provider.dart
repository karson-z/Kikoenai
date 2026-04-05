import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class MainScaffoldState {
  final bool isPlayerExpanded;
  final bool showBottomNav;
  final bool isFullScreen;

  const MainScaffoldState({
    this.isPlayerExpanded = false,
    this.showBottomNav = true,
    this.isFullScreen = false,
  });

  MainScaffoldState copyWith({
    bool? isPlayerExpanded,
    bool? showBottomNav,
    bool? isFullScreen,
  }) {
    return MainScaffoldState(
      isPlayerExpanded: isPlayerExpanded ?? this.isPlayerExpanded,
      showBottomNav: showBottomNav ?? this.showBottomNav,
      isFullScreen: isFullScreen ?? this.isFullScreen,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MainScaffoldState &&
        other.isPlayerExpanded == isPlayerExpanded &&
        other.showBottomNav == showBottomNav &&
        other.isFullScreen == isFullScreen;
  }

  @override
  int get hashCode {
    return isPlayerExpanded.hashCode ^
    showBottomNav.hashCode ^
    isFullScreen.hashCode;
  }
}

class MainScaffoldNotifier extends Notifier<MainScaffoldState> {
  @override
  MainScaffoldState build() {
    return const MainScaffoldState();
  }

  void expandPlayer() => state = state.copyWith(isPlayerExpanded: true);

  void collapsePlayer() => state = state.copyWith(isPlayerExpanded: false);

  void setBottomNav(bool visible) => state = state.copyWith(showBottomNav: visible);

  void setFullScreen(bool isFullScreen) => state = state.copyWith(isFullScreen: isFullScreen);
}

final mainScaffoldProvider =
NotifierProvider<MainScaffoldNotifier, MainScaffoldState>(() => MainScaffoldNotifier());