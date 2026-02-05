import 'package:flutter/material.dart';
import 'package:flutter_lyric/core/lyric_controller.dart';
import 'package:flutter_lyric/core/lyric_style.dart';
import 'package:flutter_lyric/core/lyric_styles.dart';
import 'package:flutter_lyric/widgets/lyric_view.dart';

class ShowLyric extends StatefulWidget {
  const ShowLyric({
    super.key,
    required this.lyricText,
    required this.progress,
    this.beforeLyricBuilder,
    this.afterLyricBuilder,
    this.initStyle,
    this.initController,
  });
  final String lyricText;
  final Duration progress;
  final LyricStyle? initStyle;
  final Function(LyricController)? initController;
  final List<Widget> Function(LyricController, LyricStyle)? beforeLyricBuilder;
  final List<Widget> Function(LyricController, LyricStyle)? afterLyricBuilder;

  @override
  State<ShowLyric> createState() => _ShowLyricState();
}

class _ShowLyricState extends State<ShowLyric> {
  LyricController lyricController = LyricController();
  final ValueNotifier<LyricStyle> _currentStyleNotifier = ValueNotifier(
    LyricStyles.default1,
  );

  @override
  void dispose() {
    lyricController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _currentStyleNotifier.value = widget.initStyle ?? LyricStyles.default1;
    lyricController.loadLyric(widget.lyricText,);
    lyricController.setProgress(widget.progress);
    widget.initController?.call(lyricController);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ShowLyric oldWidget) {
    if (oldWidget.progress != widget.progress) {
      lyricController.setProgress(widget.progress);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
      child: ValueListenableBuilder(
        valueListenable: _currentStyleNotifier,
        builder: (context, style, child) {
          return Stack(
            children: [
              ...?widget.beforeLyricBuilder?.call(lyricController, style),
              RepaintBoundary(
                child: LyricView(controller: lyricController, style: style),
              ),
              ...?widget.afterLyricBuilder?.call(lyricController, style),
              // Positioned(
              //   right: 20,
              //   top: 20,
              //   child: Row(
              //     children: [
              //       GestureDetector(
              //         child: Icon(Icons.settings, color: Colors.white),
              //         onTap: () {
              //           showDialog(
              //             context: context,
              //             builder: (context) => ValueListenableBuilder(
              //               valueListenable: _currentStyleNotifier,
              //               builder: (context, value, child) {
              //                 return EditStyle(
              //                   style: value,
              //                   onStyleChanged: (style) {
              //                     setState(() {
              //                       _currentStyleNotifier.value = style;
              //                     });
              //                   },
              //                 );
              //               },
              //             ),
              //           );
              //         },
              //       ),
              //     ],
              //   ),
              // ),
            ],
          );
        },
      ),
    );
  }
}
