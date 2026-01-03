import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 用于限制输入只能是数字

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final int safeTotalPages = totalPages < 1 ? 1 : totalPages;
    final bool canGoPrev = currentPage > 1;
    final bool canGoNext = currentPage < safeTotalPages;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. 上一页按钮
          OutlinedButton.icon(
            onPressed: canGoPrev ? () => onPageChanged(currentPage - 1) : null,
            icon: const Icon(Icons.arrow_back_ios, size: 14),
            label: const Text('Prev'),
          ),

          // 2. 页码展示区域 (支持点击跳转)
          InkWell(
            onTap: () => _showJumpDialog(context, safeTotalPages),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '$currentPage',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue, //以此颜色暗示可点击
                    ),
                  ),
                  Text(
                    ' / $safeTotalPages',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. 下一页按钮
          OutlinedButton.icon(
            onPressed: canGoNext ? () => onPageChanged(currentPage + 1) : null,
            icon: const Icon(Icons.arrow_back_ios, size: 14), // 修正图标方向
            label: const Text('Next'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ).styleWithIconRight(),
        ],
      ),
    );
  }

  /// 显示跳转对话框
  void _showJumpDialog(BuildContext context, int maxPage) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('跳转到页码'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '输入 1 - $maxPage',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            // 限制只能输入数字
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (value) {
              _handleJump(context, value, maxPage);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => _handleJump(context, controller.text, maxPage),
              child: const Text('跳转'),
            ),
          ],
        );
      },
    );
  }

  /// 处理跳转逻辑
  void _handleJump(BuildContext context, String value, int maxPage) {
    if (value.isEmpty) return;

    final int? targetPage = int.tryParse(value);

    if (targetPage != null) {
      if (targetPage >= 1 && targetPage <= maxPage) {
        Navigator.pop(context); // 关闭弹窗
        if (targetPage != currentPage) {
          onPageChanged(targetPage); // 触发回调
        }
      } else {
        // 输入超出范围提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请输入 1 到 $maxPage 之间的页码')),
        );
      }
    }
  }
}

// 扩展方法：让图标在右侧
extension on ButtonStyleButton {
  Widget styleWithIconRight() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: this,
    );
  }
}