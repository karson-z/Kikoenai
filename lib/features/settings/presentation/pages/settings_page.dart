import 'package:flutter/material.dart';
import 'package:name_app/core/widgets/layout/adaptive_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../core/theme/theme_view_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _colors = <Color>[
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.indigo,
    Colors.brown,
  ];

  final TextEditingController _hexController = TextEditingController();
  bool _hexInitDone = false;

  String _toHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  // 定义主题模式的顺序，用于 ToggleButtons
  static const List<ThemeMode> _themeModes = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final viewportHeight = MediaQuery.of(context).size.height;

    if (!_hexInitDone) {
      _hexController.text = _toHex(themeVM.seedColor);
      _hexInitDone = true;
    }

    // 确定哪个按钮被选中 (ToggleButtons 需要一个 List<bool>)
    final selectedModeIndex = _themeModes.indexOf(themeVM.themeMode);
    final isSelected =
        List<bool>.generate(_themeModes.length, (i) => i == selectedModeIndex);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        automaticallyImplyLeading: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          const Text('主题模式',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ToggleButtons(
              isSelected: isSelected,
              onPressed: (int index) {
                themeVM.setMode(_themeModes[index]);
              },
              borderRadius: BorderRadius.circular(10),
              constraints: const BoxConstraints.tightFor(
                width: 80,
                height: 45,
              ),
              children: const [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings_suggest, size: 18),
                    SizedBox(width: 4),
                    Text('系统', style: TextStyle(fontSize: 14)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.light_mode, size: 18),
                    SizedBox(width: 4),
                    Text('浅色', style: TextStyle(fontSize: 14)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.dark_mode, size: 18),
                    SizedBox(width: 4),
                    Text('深色', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('主题色',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // --- 预设颜色 + 自定义颜色 ---
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._colors.map((c) {
                final selected = themeVM.seedColor.toARGB32() == c.toARGB32();
                return GestureDetector(
                  onTap: () => themeVM.setSeedColor(c),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: selected ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }),

              // --- 自定义颜色 + 按钮 ---
              GestureDetector(
                onTap: () async {
                  final theme = context.read<ThemeViewModel>();
                  Color original = theme.seedColor; // 取消时还原
                  Color temp = theme.seedColor;

                  await showDialog(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: const Text('选择自定义颜色'),
                        content: StatefulBuilder(
                          builder: (ctx, setState) => SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: temp,
                              enableAlpha: false,
                              displayThumbColor: true,
                              onColorChanged: (c) {
                                setState(() => temp = c);
                                theme.setSeedColor(c, preview: true);
                              },
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              theme.setSeedColor(original, preview: true);
                              Navigator.pop(ctx);
                            },
                            child: const Text('取消'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              theme.setSeedColor(temp);
                              Navigator.pop(ctx);
                            },
                            child: const Text('确定'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
