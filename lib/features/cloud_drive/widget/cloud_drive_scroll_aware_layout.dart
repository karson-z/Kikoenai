import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CloudDriveScrollAwareLayout extends StatefulWidget {
  const CloudDriveScrollAwareLayout({
    super.key,
    required this.toolbar,
    required this.child,
  });

  final Widget toolbar;
  final Widget child;

  @override
  State<CloudDriveScrollAwareLayout> createState() =>
      _CloudDriveScrollAwareLayoutState();
}

class _CloudDriveScrollAwareLayoutState
    extends State<CloudDriveScrollAwareLayout> {
  bool _isToolbarVisible = true;

  bool _handleUserScroll(UserScrollNotification notification) {
    if (notification.depth != 0) return false;

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
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = disableAnimations
        ? Duration.zero
        : _isToolbarVisible
        ? const Duration(milliseconds: 180)
        : const Duration(milliseconds: 120);

    return Column(
      children: [
        ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.bottomCenter,
            heightFactor: _isToolbarVisible ? 1 : 0,
            duration: duration,
            curve: _isToolbarVisible ? Curves.easeOutCubic : Curves.easeInCubic,
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
