import 'package:flutter/material.dart';

PreferredSizeWidget buildAdaptiveAppBar(
  BuildContext context, {
  Widget? title,
  List<Widget>? actions,
  bool automaticallyImplyLeading = true,
  double? height,
}) {
  return AppBar(
    title: title,
    actions: actions,
    automaticallyImplyLeading: automaticallyImplyLeading,
    toolbarHeight: height,
  );
}