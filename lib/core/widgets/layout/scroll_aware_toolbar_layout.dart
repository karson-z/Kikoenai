import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class ScrollAwareToolbarLayout extends StatefulWidget {
  const ScrollAwareToolbarLayout({
    super.key,
    required this.toolbar,
    required this.child,
    this.forceToolbarVisible = false,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.scrollDistance = 80,
    this.snapThreshold = 0.5,
  })  : assert(scrollDistance > 0),
        assert(snapThreshold > 0 && snapThreshold < 1);

  final Widget toolbar;
  final Widget child;
  final bool forceToolbarVisible;
  final ScrollNotificationPredicate notificationPredicate;
  final double scrollDistance;
  final double snapThreshold;

  @override
  State<ScrollAwareToolbarLayout> createState() =>
      _ScrollAwareToolbarLayoutState();
}

class _ScrollAwareToolbarLayoutState extends State<ScrollAwareToolbarLayout>
    with SingleTickerProviderStateMixin {
  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 320,
    damping: 30,
  );

  late final AnimationController _visibilityController;
  bool _isCompensatingScroll = false;

  @override
  void initState() {
    super.initState();
    _visibilityController = AnimationController(
      vsync: this,
      value: 1,
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void didUpdateWidget(covariant ScrollAwareToolbarLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceToolbarVisible && !oldWidget.forceToolbarVisible) {
      _visibilityController
        ..stop()
        ..value = 1;
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_isCompensatingScroll) return false;

    if (widget.forceToolbarVisible ||
        notification.metrics.axis != Axis.vertical ||
        !widget.notificationPredicate(notification)) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      _visibilityController.stop();
    } else if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta;
      if (delta != null && delta != 0) {
        _updateVisibility(delta, notification);
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll != 0) {
        _updateVisibility(notification.overscroll, notification);
      }
    } else if (notification is ScrollEndNotification) {
      _settleVisibility();
    }

    return false;
  }

  void _updateVisibility(double scrollDelta, ScrollNotification notification) {
    _visibilityController.stop();

    final currentVisibility = _visibilityController.value;
    final availableDistance = scrollDelta < 0
        ? (1 - currentVisibility) * widget.scrollDistance
        : currentVisibility * widget.scrollDistance;
    final consumedDistance = scrollDelta.abs().clamp(0.0, availableDistance);

    if (consumedDistance > 0) {
      _visibilityController.value =
          (currentVisibility - scrollDelta.sign * consumedDistance / widget.scrollDistance)
              .clamp(0.0, 1.0)
              .toDouble();
      _compensateContentScroll(notification, scrollDelta.sign * consumedDistance);
    }
  }

  void _compensateContentScroll(
    ScrollNotification notification,
    double consumedDelta,
  ) {
    final notificationContext = notification.context;
    if (notificationContext == null) return;

    final scrollable = Scrollable.maybeOf(notificationContext);
    final position = scrollable?.position;
    if (position == null || !position.hasPixels) return;

    final target = (position.pixels - consumedDelta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((target - position.pixels).abs() < 0.001) return;

    _isCompensatingScroll = true;
    try {
      // Correct only the portion consumed by the toolbar while preserving
      // the active drag activity on the content scrollable.
      position.setPixels(target);
    } finally {
      _isCompensatingScroll = false;
    }
  }

  void _settleVisibility() {
    final target =
        _visibilityController.value >= widget.snapThreshold ? 1.0 : 0.0;

    if ((_visibilityController.value - target).abs() < 0.001) {
      _visibilityController.value = target;
      return;
    }

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      _visibilityController.value = target;
      return;
    }

    _visibilityController.animateWith(
      SpringSimulation(_spring, _visibilityController.value, target, 0),
    );
  }

  @override
  void dispose() {
    _visibilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _visibilityController,
          child: widget.toolbar,
          builder: (context, toolbar) {
            final visibility = widget.forceToolbarVisible
                ? 1.0
                : _visibilityController.value.clamp(0.0, 1.0);
            final isInteractive = visibility >= 0.999;

            return ClipRect(
              child: Align(
                key: const ValueKey('scroll-aware-toolbar-viewport'),
                alignment: Alignment.bottomCenter,
                heightFactor: visibility,
                child: IgnorePointer(
                  ignoring: !isInteractive,
                  child: ExcludeSemantics(
                    excluding: !isInteractive,
                    child: Transform.scale(
                      alignment: Alignment.bottomCenter,
                      scaleY: 0.96 + 0.04 * visibility,
                      child: toolbar,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
