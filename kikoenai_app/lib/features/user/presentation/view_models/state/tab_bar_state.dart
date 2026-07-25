import 'package:equatable/equatable.dart';

class TabBarState extends Equatable {
  final int currentIndex;
  final List<String> tabs;

  const TabBarState({
    this.currentIndex = 0,
    required this.tabs,
  });

  TabBarState copyWith({int? currentIndex}) {
    return TabBarState(
      currentIndex: currentIndex ?? this.currentIndex,
      tabs: tabs,
    );
  }

  @override
  List<Object?> get props => [currentIndex, tabs];
}
