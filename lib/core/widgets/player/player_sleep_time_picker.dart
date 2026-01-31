import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/player/provider/player_sleep_time_provider.dart';

import '../../utils/data/other.dart';

class SleepTimerBottomSheet extends ConsumerStatefulWidget {
  const SleepTimerBottomSheet({super.key});

  @override
  ConsumerState<SleepTimerBottomSheet> createState() => _SleepTimerBottomSheetState();
}

class _SleepTimerBottomSheetState extends ConsumerState<SleepTimerBottomSheet> {
  bool _isCustomMode = false;

  @override
  Widget build(BuildContext context) {
    // 获取当前是否为深色模式
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 背景色：浅色用浅灰(iOS风格)，深色用纯黑或极深灰
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FA);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _isCustomMode
              ? _CustomPickerView(
            onCancel: () => setState(() => _isCustomMode = false),
            onConfirm: (Duration duration) {
              final controller = ref.read(sleepTimerProvider.notifier);
              controller.startTimer(duration);
              print("自定义时间: $duration");
              Navigator.pop(context);
            },
          )
              : _PresetListView(
            onCustomTap: () => setState(() => _isCustomMode = true),
          ),
        ),
      ),
    );
  }
}

class _PresetListView extends ConsumerStatefulWidget {
  final VoidCallback onCustomTap;

  const _PresetListView({required this.onCustomTap});

  @override
  ConsumerState<_PresetListView> createState() => _PresetListViewState();
}

class _PresetListViewState extends ConsumerState<_PresetListView> {
  final List<int> _presets = [10, 20, 30, 45, 60, 90];
  int? _selectedIndex;
  @override
  Widget build(BuildContext context) {
    final sleepTime = ref.watch(sleepTimerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // [修改点] 获取全局定义的主题色
    final primaryColor = Theme.of(context).primaryColor;

    // --- 颜色定义 ---
    final titleColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final mainTextColor = isDark ? Colors.white : const Color(0xFF333333);
    final dividerColor = isDark ? Colors.white12 : const Color(0xFFEEEEEE);
    // 未选中状态根据模式变化
    final unselectedItemColor = isDark ? Colors.white70 : const Color(0xFF666666);
    final unselectedItemBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
          child: Text("定时关闭",
              style: TextStyle(
                  fontSize: 16,
                  color: titleColor,
                  fontWeight: FontWeight.w500)),
        ),

        // 主卡片区域
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(OtherUtil.formatSleepTimeDuration(sleepTime ?? Duration.zero),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: mainTextColor)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 圆形预设按钮列表
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _presets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final minutes = entry.value;
                    final isSelected = _selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          final controller = ref.read(sleepTimerProvider.notifier);
                          controller.startTimer(Duration(minutes: minutes));
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? primaryColor // [修改点] 选中背景使用主题色
                                : unselectedItemBg,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Text(
                            "$minutes",
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected
                                  ? Colors.white // 选中文字保持白色
                                  : unselectedItemColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Divider(height: 1, color: dividerColor),
              const SizedBox(height: 16),

              // 自定义按钮
              GestureDetector(
                onTap: widget.onCustomTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "自定义",
                    style: TextStyle(color: secondaryTextColor, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 视图 2：自定义时间选择器
// -----------------------------------------------------------------------------
class _CustomPickerView extends StatefulWidget {
  final VoidCallback onCancel;
  final ValueChanged<Duration> onConfirm;

  const _CustomPickerView({required this.onCancel, required this.onConfirm});

  @override
  State<_CustomPickerView> createState() => _CustomPickerViewState();
}

class _CustomPickerViewState extends State<_CustomPickerView> {
  int _selectedHour = 0;
  int _selectedMinute = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // [修改点] 获取全局定义的主题色
    final primaryColor = Theme.of(context).primaryColor;

    final titleColor = isDark ? Colors.white70 : Colors.black54;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final dividerColor = isDark ? Colors.white12 : Colors.grey[200];
    final cancelButtonBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final cancelButtonText = isDark ? Colors.white70 : const Color(0xFF666666);
    final cancelButtonBorder = isDark ? Colors.transparent : const Color(0xFFCCCCCC);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
          child: Text("自定义关闭",
              style: TextStyle(
                  fontSize: 16,
                  color: titleColor,
                  fontWeight: FontWeight.w500)),
        ),

        // 滚轮区域卡片
        Container(
          height: 250,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 小时滚轮
              _buildColumn(
                context,
                itemCount: 24,
                label: "小时",
                onChanged: (v) => _selectedHour = v,
              ),
              // 中间分割线
              Container(
                height: 40,
                width: 1,
                color: dividerColor,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              // 分钟滚轮
              _buildColumn(
                context,
                itemCount: 60,
                label: "分钟",
                onChanged: (v) => _selectedMinute = v,
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // 底部按钮组
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              // 取消按钮
              Expanded(
                child: TextButton(
                  onPressed: widget.onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(color: cancelButtonBorder),
                    ),
                    backgroundColor: cancelButtonBg,
                  ),
                  child: Text("取消",
                      style: TextStyle(color: cancelButtonText, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 20),
              // 确定按钮
              Expanded(
                child: TextButton(
                  onPressed: () {
                    final duration = Duration(
                        hours: _selectedHour, minutes: _selectedMinute);
                    widget.onConfirm(duration);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: primaryColor, // [修改点] 按钮背景色使用主题色
                  ),
                  child: const Text("确定",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
      ],
    );
  }

  // 构建滚轮列
  Widget _buildColumn(BuildContext context, {
    required int itemCount,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numberColor = isDark ? Colors.white : const Color(0xFF333333);
    final labelColor = isDark ? Colors.white54 : Colors.grey;

    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            child: CupertinoPicker(
              itemExtent: 40,
              backgroundColor: Colors.transparent,
              selectionOverlay: null, // 移除自带的灰色遮罩
              onSelectedItemChanged: onChanged,
              children: List.generate(itemCount, (index) {
                return Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: numberColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              }),
            ),
          ),
          Text(label,
              style: TextStyle(color: labelColor, fontSize: 14)),
        ],
      ),
    );
  }
}