import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kikoenai/core/theme/app_layout_tokens.dart';
import 'package:kikoenai/core/utils/window/display_util.dart';

/// Applies phone landscape status-bar visibility across all app routes.
class AppSystemUi extends StatefulWidget {
  const AppSystemUi({super.key, required this.child});

  final Widget child;

  @override
  State<AppSystemUi> createState() => _AppSystemUiState();
}

class _AppSystemUiState extends State<AppSystemUi> with WidgetsBindingObserver {
  bool? _phoneLandscape;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync({bool force = false}) {
    if (kIsWeb) return;
    final layout = context.layout;
    if (!layout.isPhone && _phoneLandscape == null) return;
    final landscape = layout.isPhoneLandscape;
    if (!force && _phoneLandscape == landscape) return;
    _phoneLandscape = landscape;
    unawaited(DisplayUtils.mobileSystemUi.setPhoneLandscape(landscape));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync(force: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_phoneLandscape == true) {
      unawaited(DisplayUtils.mobileSystemUi.setPhoneLandscape(false));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
