import 'dart:async';
import 'package:flutter/material.dart';

class SubtitleWidget extends StatefulWidget {
  final Stream<dynamic> eventStream;
  final VoidCallback? onDoubleTapUnbound;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragStartCallback? onPanStart;

  const SubtitleWidget({
    Key? key,
    required this.eventStream,
    this.onDoubleTapUnbound,
    this.onPanUpdate,
    this.onPanStart,
  }) : super(key: key);

  @override
  _SubtitleWidgetState createState() => _SubtitleWidgetState();
}

class _SubtitleWidgetState extends State<SubtitleWidget> {
  String _text = "等待接收字幕...";
  double _fontSize = 24.0;
  double _opacity = 0.4;
  Axis _orientation = Axis.horizontal;
  bool _isLocked = false;
  bool _isDraggable = true;

  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.eventStream.listen(_handleEvent);
  }

  void _handleEvent(dynamic event) {
    if (event is Map) {
      final action = event['action'];
      final payload = event['payload'];

      setState(() {
        switch (action) {
          case 'UPDATE_TEXT':
            _text = payload.toString();
            break;
          case 'SET_FONT_SIZE':
            _fontSize = (payload as num).toDouble();
            break;
          case 'SET_OPACITY':
            _opacity = (payload as num).toDouble();
            break;
          case 'SET_ORIENTATION':
            _orientation = payload == 0 ? Axis.horizontal : Axis.vertical;
            break;
          case 'LOCK_OVERLAY':
            _isLocked = true;
            break;
          case 'UNLOCK_OVERLAY':
            _isLocked = false;
            break;
          case 'SET_DRAGGABLE':
            _isDraggable = payload as bool;
            break;
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _isLocked ? null : widget.onDoubleTapUnbound,
      onPanStart: (_isLocked || !_isDraggable) ? null : widget.onPanStart,
      onPanUpdate: (_isLocked || !_isDraggable) ? null : widget.onPanUpdate,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: _isLocked ? Colors.transparent : Colors.black.withOpacity(_opacity),
        alignment: Alignment.center,
        child: Flex(
          direction: _orientation,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _text,
              style: TextStyle(
                color: Colors.white,
                fontSize: _fontSize,
                decoration: TextDecoration.none,
                shadows: const [
                  Shadow(
                    blurRadius: 2.0,
                    color: Colors.black,
                    offset: Offset(1.0, 1.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}