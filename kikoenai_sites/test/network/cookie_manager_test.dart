import 'package:flutter_test/flutter_test.dart';
import 'package:kikoenai_sites/network/cookie_manager.dart';

void main() {
  late SitesCookieManager manager;

  setUp(() {
    manager = SitesCookieManager();
  });

  group('SitesCookieManager', () {
    test('setCookie / getCookies 基本读写', () {
      manager.setCookie('example.com', 'session', 'abc123');
      expect(manager.getCookies('example.com')['session'], 'abc123');
    });

    test('getCookieHeader 返回拼接后的字符串', () {
      manager
        ..setCookie('a.com', 'k1', 'v1')
        ..setCookie('a.com', 'k2', 'v2');
      final header = manager.getCookieHeader('a.com');
      expect(header, contains('k1=v1'));
      expect(header, contains('k2=v2'));
      expect(header, contains(';'));
    });

    test('getCookieHeader 空 host 返回空串', () {
      expect(manager.getCookieHeader('unknown.com'), '');
    });

    test('parseSetCookieHeader 单条', () {
      manager.parseSetCookieHeader('b.com', 'token=xyz; Path=/; HttpOnly');
      expect(manager.getCookies('b.com')['token'], 'xyz');
    });

    test('parseSetCookieHeader 列表多条', () {
      manager.parseSetCookieHeader(
        'c.com',
        ['a=1; Path=/', 'b=2; Path=/; HttpOnly'],
      );
      expect(manager.getCookies('c.com')['a'], '1');
      expect(manager.getCookies('c.com')['b'], '2');
    });

    test('parseSetCookieHeader 字符串多条（逗号分隔）', () {
      manager.parseSetCookieHeader('d.com', 'x=10, y=20');
      expect(manager.getCookies('d.com')['x'], '10');
      expect(manager.getCookies('d.com')['y'], '20');
    });

    test('removeCookie 删除单条', () {
      manager.setCookie('e.com', 'k', 'v');
      manager.removeCookie('e.com', 'k');
      expect(manager.getCookies('e.com')['k'], isNull);
    });

    test('clearHost 清空指定 host', () {
      manager
        ..setCookie('f.com', 'k', 'v')
        ..clearHost('f.com');
      expect(manager.getCookies('f.com'), isEmpty);
    });

    test('clearAll 清空全部', () {
      manager
        ..setCookie('g.com', 'k', 'v')
        ..setCookie('h.com', 'k', 'v')
        ..clearAll();
      expect(manager.all, isEmpty);
    });

    test('all 返回只读视图', () {
      manager.setCookie('i.com', 'k', 'v');
      final view = manager.all;
      expect(() => view['new'] = {}, throwsUnsupportedError);
    });
  });
}
