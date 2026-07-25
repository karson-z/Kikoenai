import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 从右向左滑入的页面过渡动画
class SlideRightTransitionPage<T> extends CustomTransitionPage<T> {
  SlideRightTransitionPage({
    LocalKey? key,
    required super.child,
  }) : super(
    key: key,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween<Offset>(
        begin: const Offset(1.0, 0.0), // 从右侧边缘开始
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutQuart));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}