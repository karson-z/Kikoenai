import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// 一个自定义的右侧边栏，仿照官方 WoltBottomSheetType 的健壮结构编写
class CustomSideSheetType extends WoltModalType {
  const CustomSideSheetType({
    ShapeBorder shapeBorder = _defaultShapeBorder,
    bool? showDragHandle = false,
    bool forceMaxHeight = true, // 侧边栏通常需要撑满全高
    // 注意：右侧面板关闭应该是向右滑，对应的方向是 startToEnd (LTR环境下)
    WoltModalDismissDirection dismissDirection = WoltModalDismissDirection.endToStart,
    Duration transitionDuration = const Duration(milliseconds: 350),
    Duration reverseTransitionDuration = const Duration(milliseconds: 250),
    double minFlingVelocity = 700.0,
    double closeProgressThreshold = 0.5,
    bool? barrierDismissible = true,
  }) : super(
    shapeBorder: shapeBorder,
    forceMaxHeight: forceMaxHeight,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    dismissDirection: dismissDirection,
    minFlingVelocity: minFlingVelocity,
    closeProgressThreshold: closeProgressThreshold,
    showDragHandle: showDragHandle,
    barrierDismissible: barrierDismissible,
  );

  static const ShapeBorder _defaultShapeBorder = RoundedRectangleBorder(
    // 左侧加上圆角，右侧贴边不需要圆角
    borderRadius: BorderRadius.horizontal(left: Radius.circular(16.0)),
  );

  @override
  String routeLabel(BuildContext context) =>
      MaterialLocalizations.of(context).drawerLabel; // 语义化为 Drawer

  /// 控制面板的尺寸
  @override
  BoxConstraints layoutModal(Size availableSize) {
    const maxWidth = 400.0;

    return BoxConstraints(
      minWidth: maxWidth,
      maxWidth: maxWidth,
      minHeight: availableSize.height, // 侧边栏高度撑满
      maxHeight: availableSize.height,
    );
  }

  /// 控制面板出现的位置（紧贴右侧）
  @override
  Offset positionModal(
      Size availableSize,
      Size modalContentSize,
      TextDirection textDirection,
      ) {
    // X轴：屏幕总宽减去面板宽度，即靠右停靠
    // Y轴：0，即从顶部开始
    final x = max(0.0, availableSize.width - modalContentSize.width);
    return Offset(x, 0);
  }

  /// 内部安全区处理
  @override
  Widget decoratePageContent(
      BuildContext context,
      Widget child,
      bool useSafeArea,
      ) {
    return useSafeArea
        ? SafeArea(
      left: false, // 贴近右侧，不需要处理左侧的安全区
      right: true,
      child: child,
    )
        : child;
  }

  /// 外部安全区处理
  @override
  Widget decorateModal(BuildContext context, Widget modal, bool useSafeArea) =>
      useSafeArea ? SafeArea(left: false, right: false, child: modal) : modal;

  /// 动画配置：右侧纯滑入，退场/拖拽时绝对跟手
  @override
  Widget buildTransitions(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    // 定义位移路径：从右侧 (1.0, 0.0) 滑入到原位 (0, 0)
    final positionTween = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    );

    // 核心修复：分离进场和退场的动画曲线
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      // 进场：使用 easeOutCubic，丝滑减速阻尼感
      curve: Curves.easeOutCubic,
      // 退场 (向右滑动关闭)：使用 linear，保证 1:1 绝对跟手！
      reverseCurve: Curves.linear,
    );

    // 纯滑动，无透明度渐变
    return SlideTransition(
      position: positionTween.animate(curvedAnimation),
      child: child,
    );
  }

  /// 提供 copyWith 方便后续动态修改参数
  CustomSideSheetType copyWith({
    ShapeBorder? shapeBorder,
    bool? showDragHandle,
    bool? forceMaxHeight,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    WoltModalDismissDirection? dismissDirection,
    double? minFlingVelocity,
    double? closeProgressThreshold,
    bool? barrierDismissible,
  }) {
    return CustomSideSheetType(
      shapeBorder: shapeBorder ?? this.shapeBorder,
      showDragHandle: showDragHandle ?? this.showDragHandle,
      forceMaxHeight: forceMaxHeight ?? this.forceMaxHeight,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      reverseTransitionDuration:
      reverseTransitionDuration ?? this.reverseTransitionDuration,
      dismissDirection: dismissDirection ?? this.dismissDirection!,
      minFlingVelocity: minFlingVelocity ?? this.minFlingVelocity,
      closeProgressThreshold:
      closeProgressThreshold ?? this.closeProgressThreshold,
      barrierDismissible: barrierDismissible ?? this.barrierDismissible,
    );
  }
}