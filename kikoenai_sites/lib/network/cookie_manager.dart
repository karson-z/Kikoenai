import 'dart:collection';

/// Cookie 管理器
///
/// 内存级 Cookie 容器，按 host 维度存储。
/// 负责在请求时自动注入 `Cookie` 头，在响应时自动解析 `Set-Cookie` 头。
class SitesCookieManager {
  final Map<String, Map<String, String>> _store = {};

  /// 获取指定 host 下的全部 cookie（已 URL 解码值）
  Map<String, String> getCookies(String host) {
    return Map.unmodifiable(_store[host] ?? {});
  }

  /// 获取指定 host 下的 Cookie 字符串（形如 `k1=v1; k2=v2`）
  String getCookieHeader(String host) {
    final cookies = _store[host];
    if (cookies == null || cookies.isEmpty) return '';
    return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  /// 写入单条 Cookie
  ///
  /// [host] 目标域名
  /// [key] cookie 名
  /// [value] cookie 值
  void setCookie(String host, String key, String value) {
    _store.putIfAbsent(host, () => {});
    _store[host]![key] = value;
  }

  /// 从 `Set-Cookie` 头解析并存储
  ///
  /// 兼容单个或多个 `Set-Cookie`（以逗号分隔或列表）
  void parseSetCookieHeader(String host, dynamic headerValue) {
    if (headerValue == null) return;

    final List<String> rawCookies;
    if (headerValue is List) {
      rawCookies = headerValue.map((e) => e.toString()).toList();
    } else if (headerValue is String) {
      // Set-Cookie 多条可能以逗号分隔（但值中也可能含逗号，这里做简单处理）
      rawCookies = headerValue.split(',');
    } else {
      return;
    }

    for (final raw in rawCookies) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      // 每个 Set-Cookie 形如 `name=value; Path=/; HttpOnly`
      final firstSemi = trimmed.indexOf(';');
      final kvPart = firstSemi > 0 ? trimmed.substring(0, firstSemi) : trimmed;
      final eq = kvPart.indexOf('=');
      if (eq <= 0) continue;
      final key = kvPart.substring(0, eq).trim();
      final value = kvPart.substring(eq + 1).trim();
      if (key.isNotEmpty) {
        setCookie(host, key, value);
      }
    }
  }

  /// 删除指定 host 下的某个 cookie
  void removeCookie(String host, String key) {
    _store[host]?.remove(key);
  }

  /// 清空指定 host 下全部 cookie
  void clearHost(String host) {
    _store.remove(host);
  }

  /// 清空所有 cookie
  void clearAll() {
    _store.clear();
  }

  /// 返回全部存储内容（只读视图）
  Map<String, Map<String, String>> get all =>
      UnmodifiableMapView(_store);
}
