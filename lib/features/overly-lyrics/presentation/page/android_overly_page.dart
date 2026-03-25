import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../widget/overly_lyrics_widget.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AndroidOverlayPage(),
  ));
}

class AndroidOverlayPage extends StatelessWidget {
  const AndroidOverlayPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventStream = FlutterOverlayWindow.overlayListener;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SubtitleWidget(
        eventStream: eventStream,
        onDoubleTapUnbound: () async {
          await FlutterOverlayWindow.shareData({'action': 'LOCK_OVERLAY'});
          await FlutterOverlayWindow.updateFlag(OverlayFlag.clickThrough);
        },
        onPanUpdate: (details) {
          // 若严格要求在 Dart 层手动控制拖拽，坐标计算及更新逻辑置于此处
          // 需维护全局的 currentX 与 currentY
          // currentX += details.delta.dx;
          // currentY += details.delta.dy;
          // 视具体插件版本调用对应的更新方法，例如：
          // FlutterOverlayWindow.moveOverlay(OverlayPosition(currentX, currentY));
        },
      ),
    );
  }
}