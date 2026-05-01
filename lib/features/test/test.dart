import 'package:flutter/material.dart';

import '../../core/widgets/menu/float_menu_button.dart';

class MorphingFabApp extends StatefulWidget {
  const MorphingFabApp({Key? key}) : super(key: key);

  @override
  State<MorphingFabApp> createState() => _MorphingFabAppState();
}

class _MorphingFabAppState extends State<MorphingFabApp> {
  bool _isFabOpen = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Data-Driven Morphing FAB')),
        body: Center(
          child: Text('当前状态: ${_isFabOpen ? "已展开" : "已收起"}'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: MorphingCapsuleFab(
          isExpanded: _isFabOpen,
          fabSize: 48,
          expandedHeight: 48,
          onChanged: (val) {
            setState(() {
              _isFabOpen = val;
            });
          },
          direction: AxisDirection.left,
          fabIcon: Icons.add,

          // 【核心变化】父组件现在只传递数据配置，不传 Widget
          actions: [
            MorphingAction(
              icon: Icons.filter_alt_outlined,
              label: '筛选',
              onTap: () {
                debugPrint('执行了筛选逻辑');
              },
            ),
            MorphingAction(
              icon: Icons.delete_outline,
              label: '删除记录',
              iconColor: Colors.red[400], // 甚至可以单独为某个图标定制颜色
              onTap: () {
                debugPrint('执行了删除逻辑');
              },
            ),
            // 你可以随时在这里增加第三个、第四个按钮，内部会自动适配并添加分割线
          ],
        ),
      ),
    );
  }
}