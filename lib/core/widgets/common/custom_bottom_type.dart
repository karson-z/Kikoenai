import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

/// A custom bottom sheet modal type adapted from the official [WoltBottomSheetType].
class CustomBottomType extends WoltModalType {
  const CustomBottomType({
    ShapeBorder shapeBorder = _defaultShapeBorder,
    bool? showDragHandle = true, // Default to true as per your initial setup
    bool forceMaxHeight = false,
    WoltModalDismissDirection dismissDirection = WoltModalDismissDirection.down,
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
    // Your custom 25.0 border radius
    borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
  );

  @override
  String routeLabel(BuildContext context) =>
      MaterialLocalizations.of(context).bottomSheetLabel;

  @override
  BoxConstraints layoutModal(Size availableSize) {
    final width = availableSize.width;
    double maxHeight = availableSize.height * 0.6;
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      minHeight: 0,
      maxHeight: maxHeight,
    );
  }

  @override
  Offset positionModal(
      Size availableSize,
      Size modalContentSize,
      TextDirection textDirection,
      ) {
    // Stick to the bottom
    return Offset(0, max(0.0, availableSize.height - modalContentSize.height));
  }

  @override
  Widget decoratePageContent(
      BuildContext context,
      Widget child,
      bool useSafeArea,
      ) {
    // Official implementation for safe area handling within the page
    return useSafeArea
        ? SafeArea(
      top: false,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: child,
      ),
    )
        : child;
  }

  @override
  Widget decorateModal(BuildContext context, Widget modal, bool useSafeArea) =>
      // Ensure the modal respects safe areas but only where necessary
  useSafeArea ? SafeArea(top: false, bottom: false, child: modal) : modal;

  @override
  Widget buildTransitions(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    // 1. 定义位移路径：从正下方滑入
    final positionTween = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    );

    // 2. 核心修复：分离进场和退场的动画曲线
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      // 进场 (打开时)：使用 easeOutCubic，先快后慢，有高级的阻尼感
      curve: Curves.easeOutCubic,
      // 退场 (拖拽关闭时)：必须使用 linear，保证 1:1 绝对跟手！
      reverseCurve: Curves.linear,
    );

    return SlideTransition(
      position: positionTween.animate(curvedAnimation),
      child: child,
    );
  }

  /// Provides a way to create a new instance with modified properties.
  CustomBottomType copyWith({
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
    return CustomBottomType(
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