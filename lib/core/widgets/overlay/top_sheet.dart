import 'package:flutter/material.dart';

/// Shows a modal sheet that enters from the top of the root navigator.
///
/// The sheet is visually a top-aligned panel, while the route owns the modal
/// barrier. This lets it cover sibling UI such as a bottom navigation bar and
/// keeps back-button and barrier-dismissal behavior consistent.
Future<T?> showTopSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double topOffset = 0,
  Color barrierColor = Colors.black26,
  bool barrierDismissible = true,
  String barrierLabel = '关闭',
  Duration transitionDuration = const Duration(milliseconds: 220),
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    TopSheetRoute<T>(
      builder: builder,
      topOffset: topOffset,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      transitionDuration: transitionDuration,
    ),
  );
}

/// A reusable top-aligned modal route with a downward slide transition.
class TopSheetRoute<T> extends PopupRoute<T> {
  TopSheetRoute({
    required this.builder,
    this.topOffset = 0,
    this.barrierColor = Colors.black26,
    this.barrierDismissible = true,
    this.barrierLabel = '关闭',
    this.transitionDuration = const Duration(milliseconds: 220),
  }) : assert(topOffset >= 0);

  final WidgetBuilder builder;

  /// Extra space between the safe-area top edge and the sheet.
  ///
  /// This is useful when a host wants to keep a page-level toolbar visible
  /// while still using the route-owned modal barrier.
  final double topOffset;

  @override
  final Color barrierColor;

  @override
  final bool barrierDismissible;

  @override
  final String barrierLabel;

  @override
  final Duration transitionDuration;

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(top: topOffset),
        child: SizedBox(width: double.infinity, child: builder(context)),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final position = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    return SlideTransition(position: position, child: child);
  }
}
