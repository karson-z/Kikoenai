import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 动画类型定义
enum PageTransitionType {
  fade, // 淡入淡出
  slideRight, // 右滑进入
  slideTop, // 上方滑入
  blurBottomSheet, // 底部弹出 + 模糊 + 圆角
}

/// 通用过场动画封装
class AppTransitionPage<T> extends CustomTransitionPage<T> {
  AppTransitionPage({
    required GoRouterState state,
    required Widget child,
    required PageTransitionType type,
    Duration? duration,
  }) : super(
          key: state.pageKey,
          child: _buildChild(child, type),
          opaque: _isOpaque(type),
          barrierDismissible: type == PageTransitionType.blurBottomSheet,
          barrierColor: _barrierColor(type),
          transitionDuration: duration ?? const Duration(milliseconds: 150),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              _buildTransition(animation, secondaryAnimation, child, type),
        );

  /// 判断是否透明页面
  static bool _isOpaque(PageTransitionType type) {
    // 底部弹出为半透明，其他类型为不透明
    return type != PageTransitionType.blurBottomSheet;
  }

  /// 不同类型的遮罩颜色
  static Color? _barrierColor(PageTransitionType type) {
    if (type == PageTransitionType.blurBottomSheet) {
      return Colors.black.withAlpha(30);
    }
    return Colors.transparent;
  }

  /// 针对模糊底部弹出包装内容结构
  static Widget _buildChild(Widget child, PageTransitionType type) {
    if (type != PageTransitionType.blurBottomSheet) return child;

    return Stack(
      children: [
        // 背景模糊层
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(color: Colors.black.withAlpha(12)),
        ),
        // 底部内容
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.6,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  /// 根据类型构建动画过渡
  static Widget _buildTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    PageTransitionType type,
  ) {
    switch (type) {
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );

      case PageTransitionType.slideRight:
        final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);

      case PageTransitionType.slideTop:
        // ✅ 上方滑入，旧页面不动且立即消失（opaque: true）
        final tween = Tween(begin: const Offset(0, -1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: animation, child: child),
        );

      case PageTransitionType.blurBottomSheet:
        final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
    }
  }
}
