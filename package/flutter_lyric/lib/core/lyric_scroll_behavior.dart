import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Strategy used to animate the vertical position of the active lyric line.
abstract class ScrollBehaviorConfig {
  const ScrollBehaviorConfig();

  Animation<double> applyAnimation({
    required AnimationController controller,
    required double begin,
    required double end,
  });
}

/// Curve-based scrolling retained for callers that need deterministic timing.
class CurvedScrollConfig extends ScrollBehaviorConfig {
  final Curve curve;
  final Duration Function(double offset) durationCalculator;

  const CurvedScrollConfig({
    required this.curve,
    required this.durationCalculator,
  });

  @override
  Animation<double> applyAnimation({
    required AnimationController controller,
    required double begin,
    required double end,
  }) {
    final duration = durationCalculator((begin - end).abs());
    if (duration == Duration.zero) {
      return AlwaysStoppedAnimation<double>(end);
    }

    final animation = Tween<double>(
      begin: begin,
      end: end,
    ).chain(CurveTween(curve: curve)).animate(controller);
    controller.value = 0;
    controller.animateTo(1, duration: duration, curve: Curves.linear);
    return animation;
  }
}

/// Physics-based scrolling that mirrors the weighted movement of Apple Music.
class SpringScrollConfig extends ScrollBehaviorConfig {
  final SpringDescription springDescription;
  final double initialVelocity;

  const SpringScrollConfig({
    required this.springDescription,
    this.initialVelocity = 0,
  });

  @override
  Animation<double> applyAnimation({
    required AnimationController controller,
    required double begin,
    required double end,
  }) {
    controller.animateWith(
      SpringSimulation(springDescription, begin, end, initialVelocity),
    );
    return controller;
  }
}
