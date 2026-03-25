import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../core/service/overlay-lyrics/overly_lyrics_manager.dart';
import '../widget/overly_lyrics_widget.dart';

class DesktopOverlayPage extends StatelessWidget {
  const DesktopOverlayPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventStream = DesktopSubtitleManager().uiEventStream;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SubtitleWidget(
        eventStream: eventStream,
        onDoubleTapUnbound: () {
          DesktopSubtitleManager().lock();
        },
        onPanStart: (details) {
          // 调用桌面系统底层的原生拖拽能力
          windowManager.startDragging();
        },
      ),
    );
  }
}