import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../widget/overly_lyrics_widget.dart';



class AndroidOverlayPage extends StatelessWidget {
  const AndroidOverlayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 必须保留一个极其微弱的底色，防止图层折叠，0x01 表示 1/255 的透明度，肉眼不可见但能维持渲染树
      backgroundColor: const Color(0x01000000),
      body: SafeArea(
        child: SubtitleWidget(
          eventStream: FlutterOverlayWindow.overlayListener,
          onDoubleTapUnbound: () async {
            await FlutterOverlayWindow.shareData({'action': 'LOCK_OVERLAY'});
            await FlutterOverlayWindow.updateFlag(OverlayFlag.clickThrough);
          },
        ),
      ),
    );
  }
}