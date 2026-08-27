import 'package:flutter/material.dart';
import 'package:kikoenai/core/widgets/layout/scroll_aware_toolbar_layout.dart';

class CloudDriveScrollAwareLayout extends StatelessWidget {
  const CloudDriveScrollAwareLayout({
    super.key,
    required this.toolbar,
    required this.child,
  });

  final Widget toolbar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScrollAwareToolbarLayout(toolbar: toolbar, child: child);
  }
}
