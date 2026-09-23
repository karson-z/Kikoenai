import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// View-only state. Playback and subtitle state remain in their providers.
class PlayerViewController extends ChangeNotifier {
  PlayerViewController({ValueListenable<double>? expandProgress}) {
    _expandProgress = expandProgress;
    pageController = PageController(
      keepPage: false,
      onAttach: (_) {
        _pageProgress = _selectedPage.toDouble();
        pageController.jumpToPage(_selectedPage);
      },
    );
    pageController.addListener(_handlePageScroll);
    _expandProgress?.addListener(notifyListeners);
  }

  ValueListenable<double>? _expandProgress;
  late final PageController pageController;
  int _selectedPage = 0;
  double _pageProgress = 0;

  double get expandValue => (_expandProgress?.value ?? 0).clamp(0.0, 1.0);
  double get pageProgress => _pageProgress;

  void updateExpandProgress(ValueListenable<double>? progress) {
    if (identical(progress, _expandProgress)) return;
    _expandProgress?.removeListener(notifyListeners);
    _expandProgress = progress;
    _expandProgress?.addListener(notifyListeners);
  }

  void rememberPage(int page) {
    _selectedPage = page;
  }

  void _handlePageScroll() {
    if (!pageController.hasClients ||
        !pageController.position.hasContentDimensions) {
      return;
    }
    final value = (pageController.page ?? _selectedPage.toDouble()).clamp(
      0.0,
      1.0,
    );
    if (_pageProgress == value) return;
    _pageProgress = value;
    notifyListeners();
  }

  /// Used while the PageView is absent (wide layout or video playback).
  double get restingPage => _selectedPage.toDouble();

  @override
  void dispose() {
    _expandProgress?.removeListener(notifyListeners);
    pageController.removeListener(_handlePageScroll);
    pageController.dispose();
    super.dispose();
  }
}
