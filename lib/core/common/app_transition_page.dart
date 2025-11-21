import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 动画类型定义
enum PageTransitionType {
  fade, // 淡入淡出
  slideRight, // 右滑进入
  slideTop, // 上方滑入 (全屏)
  blurBottomSheet, // 底部弹出 + 模糊 + 圆角 (半屏/半透明)
}

/// 通用过场动画封装
///
/// 关键点说明：
/// 1. 避免全屏过渡（如 slideRight/slideTop）出现重叠闪烁，
///    新页面的根 Widget 必须设置一个不透明的背景色 (如 Scaffold 的 backgroundColor)。
/// 2. opaque: true 的页面在动画开始时会覆盖旧页面，但旧页面不会立即从渲染树移除，
///    而是等待动画完成。
class AppTransitionPage<T> extends CustomTransitionPage<T> {
  AppTransitionPage({
    required GoRouterState state,
    required Widget child,
    required PageTransitionType type,
    Duration? duration,
  }) : super(
    key: state.pageKey,
    // ⚠️ 关键：确保全屏页面的 child 拥有不透明背景，以避免重叠闪烁
    child: _buildChild(child, type),
    opaque: _isOpaque(type),
    barrierDismissible: type == PageTransitionType.blurBottomSheet,
    // 底部弹出时使用浅黑遮罩
    barrierColor: _barrierColor(type),
    transitionDuration: duration ?? const Duration(milliseconds: 250), // 增加至 250ms，视觉效果更平滑
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        _buildTransition(animation, secondaryAnimation, child, type),
  );

  /// 判断是否为不透明页面（全屏遮挡底层页面）
  static bool _isOpaque(PageTransitionType type) {
    // 底部弹出为半透明 (false)，其他全屏类型为不透明 (true)
    return type != PageTransitionType.blurBottomSheet;
  }

  /// 不同类型的遮罩颜色
  static Color? _barrierColor(PageTransitionType type) {
    if (type == PageTransitionType.blurBottomSheet) {
      // 较深的半透明黑色作为底部 Sheet 的背景遮罩
      return Colors.black.withOpacity(0.4);
    }
    return Colors.transparent;
  }

  /// 针对模糊底部弹出包装内容结构
  /// 为 blurBottomSheet 类型添加 BackdropFilter 和圆角。
  static Widget _buildChild(Widget child, PageTransitionType type) {
    if (type != PageTransitionType.blurBottomSheet) return child;

    // 底部弹出式容器，确保子 Widget 位于底部
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.65, // 弹出高度略增加
        child: ClipRRect(
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
          child: Stack(
            children: [
              // 底部 Sheet 内容
              child,
              // 顶层遮罩（用于模糊和变暗效果）
              Positioned.fill(
                child: BackdropFilter(
                  // 模糊效果应用在底下的页面（即旧页面）
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  // 添加一层额外的半透明黑色，增强“模态”效果
                  child: Container(color: Colors.black.withOpacity(0.05)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 根据类型构建动画过渡
  static Widget _buildTransition(
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      PageTransitionType type,
      ) {
    // 使用 CurveTween 应用于所有过渡，保持一致性
    const curve = Curves.easeOutCubic;

    switch (type) {
      case PageTransitionType.fade:
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          child: child,
        );

      case PageTransitionType.slideRight:
      // 关键：新页面从右侧滑入 (1, 0) -> (0, 0)
        final slideInTween = Tween(begin: const Offset(1, 0), end: Offset.zero)
            .chain(CurveTween(curve: curve));

        // 优化：旧页面轻微向左滑出，增强层次感
        final slideOutTween = Tween(begin: Offset.zero, end: const Offset(-0.15, 0))
            .chain(CurveTween(curve: curve));

        return SlideTransition(
          // 应用旧页面退出动画（使用 secondaryAnimation）
          position: secondaryAnimation.drive(slideOutTween),
          child: SlideTransition(
            // 应用新页面进入动画（使用 animation）
            position: animation.drive(slideInTween),
            child: child,
          ),
        );

      case PageTransitionType.slideTop:
      // 优化：移除 FadeTransition，避免新页面在起始帧是透明的。
      // 关键：确保 child 拥有不透明背景色，避免看到底层页面。
        final tween = Tween(begin: const Offset(0, -1), end: Offset.zero)
            .chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );

      case PageTransitionType.blurBottomSheet:
      // 底部弹出，只需新页面从底部滑入 (0, 1) -> (0, 0)
        final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
            .chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
    }
  }
}