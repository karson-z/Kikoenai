import 'package:flutter/material.dart';
import 'package:kikoenai/core/utils/data/time_formatter.dart';
import 'package:kikoenai/features/album/data/model/rate_count_detail.dart';

// RatingSection 保持不变...
class RatingSection extends StatelessWidget {
  final double average; // 平均分
  final int userRating; // 当前用户的评分 (0 表示未评分)
  final ValueChanged<int> onRatingUpdate; // 评分回调
  final List<Widget>? extraWidgets;

  const RatingSection({
    super.key,
    required this.average,
    required this.userRating,
    required this.onRatingUpdate,
    this.extraWidgets,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAverageRow(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAverageRow() {
    final isUserRated = userRating > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 核心星星组件
        _InteractiveStarRow(
          average: average,
          userRating: userRating,
          size: 20,
          onRate: onRatingUpdate,
        ),

        const SizedBox(width: 8),

        // 分数显示
        Text(
          isUserRated ? userRating.toString() : average.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 14,
            color: isUserRated ? Colors.blue : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),

        if (extraWidgets != null) ...extraWidgets!,
      ],
    );
  }
}

class _InteractiveStarRow extends StatefulWidget {
  final double average;
  final int userRating;
  final double size;
  final ValueChanged<int> onRate;

  const _InteractiveStarRow({
    required this.average,
    required this.userRating,
    required this.size,
    required this.onRate,
  });

  @override
  State<_InteractiveStarRow> createState() => _InteractiveStarRowState();
}

class _InteractiveStarRowState extends State<_InteractiveStarRow> {
  // 用于记录当前鼠标悬停在第几个星星上 (1-5)，0 表示没有悬停
  int _hoveredIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 判断当前是否处于"用户已评分"状态
    final bool isUserRated = widget.userRating > 0;

    // 决定显示的基准分数：用户分 或 平均分
    final double displayRating = isUserRated ? widget.userRating.toDouble() : widget.average;

    // 决定颜色：用户分(蓝) 或 平均分(黄)
    final Color activeColor = isUserRated ? Colors.blue : Colors.amber;

    List<Widget> stars = [];

    for (int i = 1; i <= 5; i++) {
      IconData icon;

      if (isUserRated) {
        // 用户评分模式：只有全星或空星
        icon = i <= widget.userRating ? Icons.star : Icons.star_border;
      } else {
        // 平均分模式：支持半星
        double diff = displayRating - i + 1;
        if (diff >= 1) {
          icon = Icons.star;
        } else if (diff > 0.5) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
      }

      // 判断当前星星是否被悬停
      final bool isHovered = _hoveredIndex == i;

      stars.add(
        // 2. 使用 MouseRegion 监听鼠标进入和离开
        MouseRegion(
          onEnter: (_) => setState(() => _hoveredIndex = i),
          onExit: (_) => setState(() => _hoveredIndex = 0),
          child: GestureDetector(
            onTap: () {
              widget.onRate(i);
            },
            child: Padding(
              // 稍微调整一下 Padding，避免放大时过于拥挤
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              // 3. 使用 TweenAnimationBuilder 实现平滑的缩放动画
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 1.0,
                  end: isHovered ? 1.3 : 1.0, // 悬停时放大到 1.3 倍
                ),
                duration: const Duration(milliseconds: 300), // 动画时长
                curve: Curves.easeOutBack, // 使用带有回弹效果的曲线，更有活力
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                // 实际的星星图标作为 child 传入，避免重复构建
                child: Icon(
                  icon,
                  color: (icon == Icons.star_border && !isUserRated)
                      ? Colors.grey.withOpacity(0.4) // 未选中的底色
                      : activeColor,
                  size: widget.size,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min, // 让 Row 紧缩，只占用必要的空间
      children: stars,
    );
  }
}