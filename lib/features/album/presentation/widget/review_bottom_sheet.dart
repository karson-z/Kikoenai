import 'package:flutter/material.dart';
// 请替换为你实际的模型文件路径
import '../../../../core/enums/work_progress.dart';
import '../../data/model/user_work_status.dart';

class ReviewBottomSheet extends StatefulWidget {
  final UserWorkStatus initialStatus;
  final Function(UserWorkStatus) onSubmit;

  const ReviewBottomSheet({
    super.key,
    required this.initialStatus,
    required this.onSubmit,
  });

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  late WorkProgress _selectedProgress;
  late int _rating;
  late TextEditingController _reviewController;

  @override
  void initState() {
    super.initState();
    // 初始化状态
    _selectedProgress = widget.initialStatus.progress == WorkProgress.unknown
        ? WorkProgress.marked // 默认选中 "标记"
        : widget.initialStatus.progress;

    _rating = widget.initialStatus.rating;
    _reviewController = TextEditingController(text: widget.initialStatus.reviewText);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    // 构建新的模型对象
    final newStatus = widget.initialStatus.copyWith(
      progress: _selectedProgress,
      rating: _rating,
      reviewText: _reviewController.text.isEmpty ? null : _reviewController.text,
    );

    // 回调给父组件处理
    widget.onSubmit(newStatus);
    Navigator.pop(context); // 关闭弹窗
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 获取键盘高度，防止遮挡
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 顶部把手 ---
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text("标记进度", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // --- 进度选择 (ChoiceChips) ---
            Wrap(
              spacing: 8,
              children: WorkProgress.values
                  .where((e) => e != WorkProgress.unknown) // 过滤掉 unknown
                  .map((progress) {
                final isSelected = _selectedProgress == progress;
                return ChoiceChip(
                  label: Text(_getProgressLabel(progress)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedProgress = progress);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            Text("评分", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // --- 星级评分组件 ---
            Row(
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  iconSize: 32,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _rating = starIndex),
                  icon: Icon(
                    starIndex <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: starIndex <= _rating ? Colors.amber : theme.disabledColor,
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            Text("写评论", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // --- 评论输入框 ---
            TextField(
              controller: _reviewController,
              maxLines: 4,
              minLines: 2,
              decoration: InputDecoration(
                hintText: "记录当下的听感...",
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 32),

            // --- 提交按钮 ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _handleSubmit,
                child: const Text("保存评价"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 辅助方法：将枚举转为中文显示
  String _getProgressLabel(WorkProgress p) {
    switch (p) {
      case WorkProgress.marked: return "想听";
      case WorkProgress.listening: return "在听";
      case WorkProgress.listened: return "听完";
      case WorkProgress.replay: return "重播";
      case WorkProgress.postponed: return "搁置";
      default: return "未知";
    }
  }
}