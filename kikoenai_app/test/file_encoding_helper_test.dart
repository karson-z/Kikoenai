import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai/core/utils/data/charset_cover.dart';

void main() {
  group('FileEncodingHelper.decodeBytes', () {
    tearDown(() {
      FileEncodingHelper.debugResetCharsetDecodeHandler();
    });

    test('decodes UTF-8 text by default', () async {
      const text = 'Hello 世界 こんにちは';
      final result = await FileEncodingHelper.decodeBytes(utf8.encode(text));

      expect(result.content, text);
      expect(result.encoding, 'UTF-8');
    });

    test('prefers hinted GBK charset for Chinese text', () async {
      const text = '中文歌词';
      final gbkBytes = Uint8List.fromList(
          <int>[0xD6, 0xD0, 0xCE, 0xC4, 0xB8, 0xE8, 0xB4, 0xCA]);

      FileEncodingHelper.debugSetCharsetDecodeHandler((charset, bytes) async {
        if (charset == 'GBK' || charset == 'GB18030') {
          expect(bytes, gbkBytes);
          return text;
        }
        throw UnsupportedError('Unexpected charset: $charset');
      });

      final result = await FileEncodingHelper.decodeBytes(
        gbkBytes,
        hintedCharset: 'gbk',
      );

      expect(result.content, text);
      expect(result.encoding, 'GBK');
    });

    test('falls back to Shift_JIS for Japanese text when UTF-8 fails',
        () async {
      const text = 'こんにちは';
      final sjisBytes = Uint8List.fromList(
          <int>[0x82, 0xB1, 0x82, 0xF1, 0x82, 0xC9, 0x82, 0xBF, 0x82, 0xCD]);

      FileEncodingHelper.debugSetCharsetDecodeHandler((charset, bytes) async {
        if (charset == 'GB18030' || charset == 'GBK') {
          return '‚±‚ñ‚É‚¿‚Í';
        }
        if (charset == 'Shift_JIS') {
          expect(bytes, sjisBytes);
          return text;
        }
        if (charset == 'EUC-JP') {
          return '�����';
        }
        throw UnsupportedError('Unexpected charset: $charset');
      });

      final result = await FileEncodingHelper.decodeBytes(sjisBytes);

      expect(result.content, text);
      expect(result.encoding, 'Shift_JIS');
    });

    test('extracts charset from content-type header', () {
      final charset = FileEncodingHelper.extractCharsetFromContentType(
        'text/plain; charset=Shift_JIS',
      );

      expect(charset, 'Shift_JIS');
    });
  });
}
