import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai_core/kikoenai_core.dart';
import 'package:kikoenai/core/widgets/common/back_button_interceptor.dart';
import 'package:kikoenai/core/widgets/common/kikoenai_dialog.dart';
import 'package:kikoenai/features/player/widget/other/player_sleep_time_picker.dart';
import '../../provider/player_sleep_time_provider.dart';
// 记得 import 上面定义的 provider 文件

class SleepTimerButton extends ConsumerWidget {
  const SleepTimerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听剩余时间
    final remainingTime = ref.watch(sleepTimerProvider);
    final isActive = remainingTime != null;

    return GestureDetector(
      onTap: () {
        if (isActive) {
          // 如果已经开启，点击则是取消或查看详情
          showCancelSleepTimerDialog(context, ref);
        } else {
          // 如果未开启，点击弹出设置时间面板
          _showTimePicker(context);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        // 根据状态调整内边距和形状
        padding: EdgeInsets.symmetric(
            horizontal: isActive ? 12 : 10,
            vertical: 8
        ),
        decoration: BoxDecoration(
          // 视觉风格：半透明白色背景
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标
            const Icon(
              Icons.bedtime_rounded, // 或者使用 Icons.nights_stay
              color: Colors.white,
              size: 20,
            ),

            // 倒计时文字部分 - 使用 AnimatedSize 做宽度动画
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: isActive ? null : 0, // 不激活时宽度为0
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    isActive ? OtherUtil.formatSleepTimeDuration(remainingTime) : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Monospace', // 等宽字体防止数字跳动
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  void _showTimePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 允许弹窗根据内容自适应高度
      backgroundColor: Colors.transparent, // 背景透明，由组件内部控制圆角
      builder: (context) => const BackButtonPriorityWrapper(
        zIndex: 100,
        name: 'SleepBottomShell',
        child: SleepTimerBottomSheet(),
      ),
    );
  }

  Future<void> showCancelSleepTimerDialog(BuildContext context, WidgetRef ref) async {
    // 使用统一弹窗样式
    final confirm = await KikoenaiAlertDialog.confirm(
      context,
      title: "关闭定时",
      content: "确定要取消当前的定时关闭任务吗？",
    );

    // 如果用户点击了确定
    if (confirm) {
      ref.read(sleepTimerProvider.notifier).stopTimer();
    }
  }
}