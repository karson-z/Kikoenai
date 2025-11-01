import 'package:flutter/material.dart';
import 'adaptive_app_bar_impl_stub.dart'
    if (dart.library.io) 'adaptive_app_bar_impl_desktop.dart';

class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final double? height; // allow custom height

  const AdaptiveAppBar({
    super.key,
    this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.height,
  });

  @override
  Size get preferredSize => Size.fromHeight(height ?? kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return buildAdaptiveAppBar(
      context,
      title: title,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      height: height,
    );
  }
}