import 'package:flutter/material.dart';
import 'package:flutter_lyric/core/lyric_controller.dart';
import 'package:flutter_lyric/core/lyric_parse.dart';
import 'package:flutter_lyric/core/lyric_style.dart';
import 'package:flutter_lyric/widgets/lyric_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/widgets/player/provider/player_lyrics_provider.dart';

import '../../service/lyrics/lyrics_parse_service.dart';

class ShowLyric extends ConsumerStatefulWidget {
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
  ConsumerState<ShowLyric> createState() => _ShowLyricState();
}

class _ShowLyricState extends ConsumerState<ShowLyric> {
  LyricController lyricController = LyricController();

  @override
  void dispose() {
    lyricController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    lyricController.loadLyricWithParsers(widget.lyricText,parsers: [VttParser(),LrcParser(),QrcParser(),FallbackParser()]);
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
    final style = ref.watch(lyricStyleProvider);
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
  }
}
