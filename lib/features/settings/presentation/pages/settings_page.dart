import 'package:flutter/material.dart';
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
  String? _hexError;

  String _toHex(Color c) => '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  Color? _parseHex(String input) {
    var s = input.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) {
      s = 'FF$s';
    } else if (s.length != 8) {
      return null;
    }
    final intVal = int.tryParse(s, radix: 16);
    if (intVal == null) return null;
    return Color(intVal);
  }

  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    if (!_hexInitDone) {
      _hexController.text = _toHex(themeVM.seedColor);
      _hexInitDone = true;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('主题设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('主题模式', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const <ButtonSegment<ThemeMode>>[
            ButtonSegment<ThemeMode>(value: ThemeMode.system, label: Text('系统'), icon: Icon(Icons.settings_suggest)),
            ButtonSegment<ThemeMode>(value: ThemeMode.light, label: Text('浅色'), icon: Icon(Icons.light_mode)),
            ButtonSegment<ThemeMode>(value: ThemeMode.dark, label: Text('深色'), icon: Icon(Icons.dark_mode)),
          ],
          selected: {themeVM.themeMode},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              themeVM.setMode(selection.first);
            }
          },
        ),
        const SizedBox(height: 16),
        const Text('主题色', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors.map((c) {
            final selected = themeVM.seedColor.value == c.value;
            return GestureDetector(
              onTap: () => themeVM.setSeedColor(c),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    width: selected ? 3 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.color_lens),
          label: const Text('选择自定义颜色'),
          onPressed: () async {
            Color temp = themeVM.seedColor;
            await showDialog(
              context: context,
              builder: (ctx) {
                return AlertDialog(
                  title: const Text('选择自定义颜色'),
                  content: StatefulBuilder(
                    builder: (ctx, setState) => SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: temp,
                        onColorChanged: (c) => setState(() => temp = c),
                        enableAlpha: false,
                        displayThumbColor: true,
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        themeVM.setSeedColor(temp);
                        Navigator.pop(ctx);
                      },
                      child: const Text('确定'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hexController,
          decoration: InputDecoration(
            labelText: '主题色(HEX)',
            errorText: _hexError,
          ),
          onChanged: (s) {
            final parsed = _parseHex(s);
            setState(() {
              _hexError = parsed == null ? '格式错误(例如: #4285F4)' : null;
            });
          },
          onSubmitted: (s) {
            final parsed = _parseHex(s);
            if (parsed != null) themeVM.setSeedColor(parsed);
          },
        ),
        const SizedBox(height: 16),
        const _PreviewPanel(),
        const SizedBox(height: 16),
        const TypographySpecimen(),
      ],
    );
  }
}

// 字体样版展示组件
class TypographySpecimen extends StatelessWidget {
  const TypographySpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('字体样版', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _spec('Display Large', tt.displayLarge),
            _spec('Display Medium', tt.displayMedium),
            _spec('Display Small', tt.displaySmall),
            const Divider(),
            _spec('Headline Large', tt.headlineLarge),
            _spec('Headline Medium', tt.headlineMedium),
            _spec('Headline Small', tt.headlineSmall),
            const Divider(),
            _spec('Title Large', tt.titleLarge),
            _spec('Title Medium', tt.titleMedium),
            _spec('Title Small', tt.titleSmall),
            const Divider(),
            _spec('Body Large', tt.bodyLarge),
            _spec('Body Medium', tt.bodyMedium),
            _spec('Body Small', tt.bodySmall),
            const Divider(),
            _spec('Label Large', tt.labelLarge),
            _spec('Label Medium', tt.labelMedium),
            _spec('Label Small', tt.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _spec(String name, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: style?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('中文示例：快狐跳过懒狗 123', style: style),
          Text('Latin Sample: Quick fox jumps 123', style: style),
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatefulWidget {
  const _PreviewPanel();

  @override
  State<_PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<_PreviewPanel> {
  bool switchOn = true;
  double sliderValue = 0.5;
  int navIndex = 0;
  Set<int> segmentSelection = {0};
  final TextEditingController _controller = TextEditingController(text: '示例输入');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('主题预览', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            NavigationBar(
              selectedIndex: navIndex,
              onDestinationSelected: (i) => setState(() => navIndex = i),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
                NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: '搜索'),
                NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const <ButtonSegment<int>>[
                ButtonSegment<int>(value: 0, label: Text('A'), icon: Icon(Icons.looks_one)),
                ButtonSegment<int>(value: 1, label: Text('B'), icon: Icon(Icons.looks_two)),
                ButtonSegment<int>(value: 2, label: Text('C'), icon: Icon(Icons.looks_3)),
              ],
              selected: segmentSelection,
              onSelectionChanged: (sel) => setState(() => segmentSelection = sel),
              multiSelectionEnabled: false,
              showSelectedIcon: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                const SizedBox(width: 8),
                TextButton(onPressed: () {}, child: const Text('Text')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '输入框',
                hintText: '输入一些内容',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(value: switchOn, onChanged: (v) => setState(() => switchOn = v)),
                Expanded(
                  child: Slider(value: sliderValue, onChanged: (v) => setState(() => sliderValue = v)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const Chip(label: Text('Chip')),
                Chip(
                  label: const Text('主色'),
                  backgroundColor: cs.primary,
                  labelStyle: TextStyle(color: cs.onPrimary),
                ),
                Chip(
                  label: const Text('次色'),
                  backgroundColor: cs.secondary,
                  labelStyle: TextStyle(color: cs.onSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('列表项（标题）'),
              subtitle: const Text('副标题文本'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}