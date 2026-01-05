import 'package:flutter/material.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

class CustomBottomType extends WoltModalType {
  const CustomBottomType()
      : super(
    shapeBorder: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    dismissDirection: WoltModalDismissDirection.down,
    showDragHandle: true,
    closeProgressThreshold: 0.5,
    barrierDismissible: true,
    forceMaxHeight: false,
  );

  @override
  String routeLabel(BuildContext context) {
    return MaterialLocalizations.of(context).dialogLabel;
  }

  @override
  BoxConstraints layoutModal(Size availableSize) {
    final width = availableSize.width;

    double maxHeight;

    if (width < 523) {
      maxHeight = availableSize.height * 0.6;
    } else if (width < 800) {
      maxHeight = 500;
    } else {
      maxHeight = 600;
    }

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
    // bottomSheet 贴底部
    final x = 0.0;
    final y = availableSize.height - modalContentSize.height;
    return Offset(x, y);
  }

  @override
  Widget buildTransitions(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final slide = Tween(
      begin: const Offset(0, 1), // bottomSlideIn
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
