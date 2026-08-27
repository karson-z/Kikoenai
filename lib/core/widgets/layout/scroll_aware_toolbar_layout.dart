import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScrollAwareToolbarLayout extends StatefulWidget {
  const ScrollAwareToolbarLayout({
    super.key,
    required this.toolbar,
    required this.child,
    this.forceToolbarVisible = false,
    this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  final Widget toolbar;
  final Widget child;
  final bool forceToolbarVisible;
  final ScrollNotificationPredicate notificationPredicate;

  @override
  State<ScrollAwareToolbarLayout> createState() =>
      _ScrollAwareToolbarLayoutState();
}

class _ScrollAwareToolbarLayoutState extends State<ScrollAwareToolbarLayout> {
  bool _isToolbarVisible = true;

  @override
  void didUpdateWidget(covariant ScrollAwareToolbarLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceToolbarVisible && !oldWidget.forceToolbarVisible) {
      _isToolbarVisible = true;
    }
  }

  bool _handleUserScroll(UserScrollNotification notification) {
    if (widget.forceToolbarVisible ||
        notification.metrics.axis != Axis.vertical ||
        !widget.notificationPredicate(notification)) {
      return false;
    }

    final shouldShow = switch (notification.direction) {
      ScrollDirection.forward => true,
      ScrollDirection.reverse => false,
      ScrollDirection.idle => _isToolbarVisible,
    };
    if (shouldShow != _isToolbarVisible) {
      setState(() => _isToolbarVisible = shouldShow);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = widget.forceToolbarVisible || _isToolbarVisible;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = disableAnimations
        ? Duration.zero
        : isVisible
        ? const Duration(milliseconds: 180)
        : const Duration(milliseconds: 120);

    return Column(
      children: [
        ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.bottomCenter,
            heightFactor: isVisible ? 1 : 0,
            duration: duration,
            curve: isVisible ? Curves.easeOutCubic : Curves.easeInCubic,
            child: widget.toolbar,
          ),
        ),
        Expanded(
          child: NotificationListener<UserScrollNotification>(
            onNotification: _handleUserScroll,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
