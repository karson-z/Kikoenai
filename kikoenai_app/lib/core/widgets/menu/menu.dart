import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

typedef MenuItemSelectedCallback = void Function(dynamic value);

class ContextMenuWrapper extends StatefulWidget {
  final Widget child;
  final List<PopupMenuEntry> items;
  final MenuItemSelectedCallback? onSelected;

  const ContextMenuWrapper({
    Key? key,
    required this.child,
    required this.items,
    this.onSelected,
  }) : super(key: key);

  @override
  State<ContextMenuWrapper> createState() => _ContextMenuWrapperState();
}

class _ContextMenuWrapperState extends State<ContextMenuWrapper> {
  final LayerLink _layerLink = LayerLink();
  Offset? _tapPosition;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTapDown: (details) {
          _tapPosition = details.globalPosition;
        },
        onLongPress: () {
          if (_tapPosition != null) {
            _showMenu(context, _tapPosition!);
          }
        },
        child: Listener(
          onPointerDown: (event) {
            if (event.kind == PointerDeviceKind.mouse &&
                event.buttons == kSecondaryMouseButton) {
              _showMenu(context, event.position);
            }
          },
          child: widget.child,
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final screenSize = overlay.size;
    final localPosition = overlay.globalToLocal(globalPosition);

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        localPosition.dx,
        localPosition.dy,
        screenSize.width - localPosition.dx,
        screenSize.height - localPosition.dy,
      ),
      items: widget.items,
    );

    if (result != null && widget.onSelected != null) {
      widget.onSelected!(result);
    }
  }
}
