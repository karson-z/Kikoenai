import 'package:flutter/material.dart';

class LyricsView extends StatelessWidget {
  final VoidCallback? onTap; // 用于点击切换回封面
  const LyricsView({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: const Text(
          "这里是歌词显示区域\n(点击切换回封面)",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}