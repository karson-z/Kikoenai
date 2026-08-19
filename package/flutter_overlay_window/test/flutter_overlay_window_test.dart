import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const controlChannel = MethodChannel('x-slayer/overlay_channel');
  const overlayChannel = MethodChannel('x-slayer/overlay');
  const messageChannel = BasicMessageChannel<dynamic>(
    'x-slayer/overlay_messenger',
    JSONMessageCodec(),
  );
  const mainToOverlayChannel = BasicMessageChannel<dynamic>(
    'x-slayer/overlay_messenger/main_to_overlay',
    JSONMessageCodec(),
  );
  const overlayToMainChannel = BasicMessageChannel<dynamic>(
    'x-slayer/overlay_messenger/overlay_to_main',
    JSONMessageCodec(),
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(controlChannel, (call) async {
      switch (call.method) {
        case 'closeOverlay':
        case 'checkPermission':
        case 'requestPermission':
          return true;
        case 'isOverlayActive':
          return false;
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(controlChannel, null);
    messenger.setMockMethodCallHandler(overlayChannel, null);
    messenger.setMockDecodedMessageHandler<dynamic>(messageChannel, null);
    messenger.setMockDecodedMessageHandler<dynamic>(mainToOverlayChannel, null);
    messenger.setMockDecodedMessageHandler<dynamic>(overlayToMainChannel, null);
  });

  group('FlutterOverlayWindow', () {
    test('closeOverlay should close the overlay', () async {
      expect(await FlutterOverlayWindow.closeOverlay(), isTrue);
      expect(await FlutterOverlayWindow.isActive(), isFalse);
    });

    test('isPermissionGranted should return a boolean', () async {
      expect(await FlutterOverlayWindow.isPermissionGranted(), isTrue);
    });

    test('requestPermission should return a boolean', () async {
      expect(await FlutterOverlayWindow.requestPermission(), isTrue);
    });

    test('resizeOverlay forwards size and top anchor to Android', () async {
      MethodCall? receivedCall;
      messenger.setMockMethodCallHandler(overlayChannel, (call) async {
        receivedCall = call;
        return true;
      });

      final resized = await FlutterOverlayWindow.resizeOverlay(
        WindowSize.matchParent,
        410,
        true,
        keepTop: true,
      );

      expect(resized, isTrue);
      expect(receivedCall?.method, 'resizeOverlay');
      expect(receivedCall?.arguments, {
        'width': WindowSize.matchParent,
        'height': 410,
        'enableDrag': true,
        'keepTop': true,
      });
    });

    test('shareData sends a JSON message through the platform channel',
        () async {
      final message = <String, dynamic>{
        'action': 'play',
        'payload': <String, dynamic>{'position': 42},
      };
      Object? receivedByPlatform;
      messenger.setMockDecodedMessageHandler<dynamic>(messageChannel, (
        incoming,
      ) async {
        receivedByPlatform = incoming;
        return incoming;
      });

      final reply = await FlutterOverlayWindow.shareData(message);

      expect(receivedByPlatform, message);
      expect(reply, message);
    });

    test('overlayListener emits JSON messages received from the platform',
        () async {
      final message = <String, dynamic>{
        'action': 'syncBusinessState',
        'payload': <String, dynamic>{'isPlaying': true},
      };
      final received = FlutterOverlayWindow.overlayListener.first;

      final encodedReply = await messenger.handlePlatformMessage(
        messageChannel.name,
        messageChannel.codec.encodeMessage(message),
        null,
      );

      expect(await received, message);
      expect(messageChannel.codec.decodeMessage(encodedReply), message);
    });

    test('sendToOverlay uses only the main-to-overlay channel', () async {
      final message = <String, dynamic>{'action': 'sync'};
      Object? receivedFromMain;
      Object? receivedFromOverlay;
      messenger.setMockDecodedMessageHandler<dynamic>(mainToOverlayChannel, (
        incoming,
      ) async {
        receivedFromMain = incoming;
        return incoming;
      });
      messenger.setMockDecodedMessageHandler<dynamic>(overlayToMainChannel, (
        incoming,
      ) async {
        receivedFromOverlay = incoming;
        return incoming;
      });

      final reply = await FlutterOverlayWindow.sendToOverlay(message);

      expect(receivedFromMain, message);
      expect(receivedFromOverlay, isNull);
      expect(reply, message);
    });

    test('messagesFromMain receives only main-to-overlay messages', () async {
      final expected = <String, dynamic>{'action': 'state'};
      final ignored = <String, dynamic>{'action': 'command'};
      final received = FlutterOverlayWindow.messagesFromMain.first;

      await messenger.handlePlatformMessage(
        overlayToMainChannel.name,
        overlayToMainChannel.codec.encodeMessage(ignored),
        null,
      );
      final encodedReply = await messenger.handlePlatformMessage(
        mainToOverlayChannel.name,
        mainToOverlayChannel.codec.encodeMessage(expected),
        null,
      );

      expect(await received, expected);
      expect(mainToOverlayChannel.codec.decodeMessage(encodedReply), expected);
    });

    test('sendToMain uses only the overlay-to-main channel', () async {
      final message = <String, dynamic>{'action': 'play'};
      Object? receivedFromMain;
      Object? receivedFromOverlay;
      messenger.setMockDecodedMessageHandler<dynamic>(mainToOverlayChannel, (
        incoming,
      ) async {
        receivedFromMain = incoming;
        return incoming;
      });
      messenger.setMockDecodedMessageHandler<dynamic>(overlayToMainChannel, (
        incoming,
      ) async {
        receivedFromOverlay = incoming;
        return incoming;
      });

      final reply = await FlutterOverlayWindow.sendToMain(message);

      expect(receivedFromMain, isNull);
      expect(receivedFromOverlay, message);
      expect(reply, message);
    });

    test('messagesFromOverlay receives only overlay-to-main messages',
        () async {
      final expected = <String, dynamic>{'action': 'command'};
      final ignored = <String, dynamic>{'action': 'state'};
      final received = FlutterOverlayWindow.messagesFromOverlay.first;

      await messenger.handlePlatformMessage(
        mainToOverlayChannel.name,
        mainToOverlayChannel.codec.encodeMessage(ignored),
        null,
      );
      final encodedReply = await messenger.handlePlatformMessage(
        overlayToMainChannel.name,
        overlayToMainChannel.codec.encodeMessage(expected),
        null,
      );

      expect(await received, expected);
      expect(overlayToMainChannel.codec.decodeMessage(encodedReply), expected);
    });
  });
}
