import 'package:flutter/material.dart';

class Message extends StatelessWidget {
  final String message;
  final MessageType type;
  final Duration duration;
  final VoidCallback? onClose;

  const Message({
    super.key,
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
    this.onClose,
  });

  static void show({
    required BuildContext context,
    required String message,
    required MessageType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewPadding.top + 20,
        left: MediaQuery.of(context).size.width * 0.1,
        right: MediaQuery.of(context).size.width * 0.1,
        child: Message(
          message: message,
          type: type,
          duration: duration,
          onClose: () => overlayEntry.remove(),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    // 自动关闭
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  Color get _backgroundColor {
    switch (type) {
      case MessageType.success:
        return Colors.green.withAlpha(90);
      case MessageType.error:
        return const Color.fromARGB(255, 211, 129, 123).withAlpha(90);
      case MessageType.warning:
        return Colors.orange.withAlpha(90);
      case MessageType.info:
        return Colors.blue.withAlpha(90);
    }
  }

  IconData get _icon {
    switch (type) {
      case MessageType.success:
        return Icons.check_circle;
      case MessageType.error:
        return Icons.error;
      case MessageType.warning:
        return Icons.warning;
      case MessageType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}

enum MessageType {
  success,
  error,
  warning,
  info,
}
