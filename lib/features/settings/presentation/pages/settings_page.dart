import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../../core/theme/theme_view_model.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
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
      '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  static const List<ThemeMode> _themeModes = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeNotifierProvider.notifier);
    final theme = ref.watch(themeNotifierProvider);

    if (!_hexInitDone) {
      _hexController.text = _toHex(theme.value!.seedColor);
      _hexInitDone = true;
    }

    final selectedModeIndex = _themeModes.indexOf(theme.value!.mode);
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
                themeState.setMode(_themeModes[index]);
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._colors.map((c) {
                final selected = theme.value!.seedColor.value == c.value;
                return GestureDetector(
                  onTap: () => themeState.setSeedColor(c),
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
              GestureDetector(
                onTap: () async {
                  Color temp = theme.value!.seedColor;
                  Color original = temp;

                  await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('选择自定义颜色'),
                      content: StatefulBuilder(
                        builder: (ctx, setState) => SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: temp,
                            enableAlpha: false,
                            displayThumbColor: true,
                            onColorChanged: (c) {
                              setState(() => temp = c);
                              themeState.setSeedColor(c, preview: true);
                            },
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            themeState.setSeedColor(original, preview: true);
                            Navigator.pop(ctx);
                          },
                          child: const Text('取消'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            themeState.setSeedColor(temp);
                            Navigator.pop(ctx);
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    ),
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
