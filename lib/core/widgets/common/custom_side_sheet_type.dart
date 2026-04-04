import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class CustomSideSheetType extends WoltModalType {
  const CustomSideSheetType()
      : super(
    shapeBorder: const RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
    ),
    dismissDirection: WoltModalDismissDirection.endToStart,
    showDragHandle: false,
    barrierDismissible: true,
    closeProgressThreshold: 0.5,
  );

  @override
  String routeLabel(BuildContext context) {
    return MaterialLocalizations.of(context).dialogLabel;
  }

  // 控制尺寸
  @override
  BoxConstraints layoutModal(Size availableSize) {
    const maxWidth = 320.0;

    final fixedHeight = availableSize.height * 0.8;

    return BoxConstraints(
      minWidth: maxWidth,
      maxWidth: maxWidth,
      minHeight: 0, // 🌟 关键：把最小高度和最大高度设为一样，强制固定
      maxHeight: fixedHeight,
    );
  }

  // 控制出现位置（右侧中间）
  @override
  Offset positionModal(
      Size availableSize,
      Size modalContentSize,
      TextDirection textDirection,
      ) {
    final x = availableSize.width - modalContentSize.width;
    final y = (availableSize.height - modalContentSize.height) / 2;
    return Offset(x, y);
  }

  // 动画：右侧滑入 + 渐变
  @override
  Widget buildTransitions(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final slide = Tween(
      begin: const Offset(1, 0), // 从右滑入
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutCubic));

    return SlideTransition(
      position: animation.drive(slide),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}
