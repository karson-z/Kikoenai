import 'package:flutter/material.dart';
import 'package:kikoenai/core/constants/app_constants.dart';

/// 可拖拽、键盘自适应的居中弹窗组件
/// 当键盘弹出时，通过AnimatedPadding移动整个弹窗，保持固定高度
class DraggableCenteredPopup extends StatefulWidget {
  final Widget child;

  const DraggableCenteredPopup({super.key, required this.child});

  @override
  State<DraggableCenteredPopup> createState() => _DraggableCenteredPopupState();
}

class _DraggableCenteredPopupState extends State<DraggableCenteredPopup> {
  double _dragOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    // 获取键盘弹出时的底部内边距
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      // 当键盘弹出时，通过调整底部内边距来移动整个弹窗
      // 这样外部盒子会整体上移，内部内容自然跟随移动
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Center(
        child: GestureDetector(
          onVerticalDragUpdate: (details) =>
              setState(() => _dragOffset += details.primaryDelta ?? 0),
          onVerticalDragEnd: (details) {
            if (_dragOffset.abs() > 120) {
              Navigator.of(context).pop(false);
            } else {
              setState(() => _dragOffset = 0);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.translationValues(0, _dragOffset, 0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            width: 500,
            height: 400, // 保持固定高度
            padding:
                const EdgeInsets.symmetric(vertical: AppConstants.kPadding),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // 顶部拖拽手柄
                Container(
                  width: 70,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 直接显示子组件，让它跟随外部盒子一起移动
                // 使用Flexible而不是Expanded，确保内容能够在固定高度内合理显示
                Flexible(
                  fit: FlexFit.tight,
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
