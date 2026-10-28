import 'dart:io';

import 'package:equatable/equatable.dart';

/// HTTP forward proxy, including HTTPS CONNECT. SOCKS/PAC are not endpoints.
class ProxyEndpoint extends Equatable {
  const ProxyEndpoint(this.host, this.port);

  final String host;
  final int port;

  static ProxyEndpoint? parse(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final raw = value.trim();
    final uri = Uri.tryParse(raw.contains('://') ? raw : 'http://$raw');
    if (uri == null ||
        uri.scheme != 'http' ||
        uri.host.isEmpty ||
        !uri.hasPort ||
        uri.port < 1 ||
        uri.port > 65535 ||
        uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment ||
        RegExp(r'\s').hasMatch(uri.host)) {
      return null;
    }
    return ProxyEndpoint(uri.host.replaceAll(RegExp(r'^\[|\]$'), ''), uri.port);
  }

  String get authority => '${host.contains(':') ? '[$host]' : host}:$port';
  String get url => 'http://$authority';

  @override
  List<Object?> get props => [host, port];
}

class SystemProxyConfig extends Equatable {
  SystemProxyConfig({
    this.http,
    this.https,
    List<String> bypass = const [],
    this.fallbackToDirect = true,
  }) : bypass = List.unmodifiable(bypass);

  static final direct = SystemProxyConfig();

  final ProxyEndpoint? http;
  final ProxyEndpoint? https;
  final List<String> bypass;
  final bool fallbackToDirect;

  factory SystemProxyConfig.single(
    ProxyEndpoint? endpoint, {
    bool fallbackToDirect = true,
  }) => SystemProxyConfig(
    http: endpoint,
    https: endpoint,
    fallbackToDirect: fallbackToDirect,
  );

  ProxyEndpoint? proxyFor(Uri uri) {
    if (bypass.any((rule) => _matchesBypass(uri, rule))) return null;
    return switch (uri.scheme.toLowerCase()) {
      'http' => http,
      'https' => https,
      _ => null,
    };
  }

  String findProxy(Uri uri) {
    final endpoint = proxyFor(uri);
    if (endpoint == null) return 'DIRECT';
    return 'PROXY ${endpoint.authority}${fallbackToDirect ? '; DIRECT' : ''}';
  }

  /// background_downloader has a single global endpoint, with no bypass API.
  ProxyEndpoint? get downloadProxy => https ?? http;

  factory SystemProxyConfig.fromWindowsRegistry(String output) {
    String? value(String key) => RegExp(
      '^\\s*$key\\s+REG_\\w+\\s+([^\\r\\n]+)',
      multiLine: true,
      caseSensitive: false,
    ).firstMatch(output)?.group(1)?.trim();

    final enabled = value('ProxyEnable');
    if (enabled != '0x1' && enabled != '1') return direct;
    final server = value('ProxyServer');
    ProxyEndpoint? http;
    ProxyEndpoint? https;
    if (server != null && server.contains('=')) {
      for (final entry in server.split(';')) {
        final pair = entry.split('=');
        if (pair.length != 2) continue;
        switch (pair.first.trim().toLowerCase()) {
          case 'http':
            http = ProxyEndpoint.parse(pair.last);
          case 'https':
            https = ProxyEndpoint.parse(pair.last);
        }
      }
    } else {
      http = https = ProxyEndpoint.parse(server);
    }
    return SystemProxyConfig(
      http: http,
      https: https,
      bypass: (value('ProxyOverride') ?? '')
          .split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }

  factory SystemProxyConfig.fromScutil(String output) {
    final values = <String, String>{};
    final exceptions = <String>[];
    var depth = 0;
    var inExceptions = false;
    for (final raw in output.split('\n')) {
      final line = raw.trim();
      if (line.endsWith('{')) {
        if (depth == 1 && line.startsWith('ExceptionsList :')) {
          inExceptions = true;
        }
        depth++;
        continue;
      }
      if (line == '}') {
        if (depth == 2) inExceptions = false;
        depth--;
        continue;
      }
      final separator = line.indexOf(' : ');
      if (separator < 0) continue;
      final key = line.substring(0, separator);
      final value = line.substring(separator + 3);
      if (depth == 1) values[key] = value;
      if (depth == 2 && inExceptions) exceptions.add(value);
    }
    ProxyEndpoint? endpoint(String scheme) {
      if (values['${scheme}Enable'] != '1') return null;
      final host = values['${scheme}Proxy'];
      final port = values['${scheme}Port'];
      if (host == null || port == null) return null;
      return ProxyEndpoint.parse(
        '${host.contains(':') ? '[$host]' : host}:$port',
      );
    }

    return SystemProxyConfig(
      http: endpoint('HTTP'),
      https: endpoint('HTTPS'),
      bypass: [
        ...exceptions,
        if (values['ExcludeSimpleHostnames'] == '1') '<local>',
      ],
    );
  }

  static bool _matchesBypass(Uri uri, String rule) {
    final host = uri.host.toLowerCase().replaceAll(RegExp(r'^\[|\]$'), '');
    final pattern = rule.trim().toLowerCase();
    if (pattern == '<local>') return !host.contains('.') && !host.contains(':');
    if (pattern.contains('/')) {
      final parts = pattern.split('/');
      final address = InternetAddress.tryParse(host);
      final network = InternetAddress.tryParse(parts.first);
      final bits = parts.length == 2 ? int.tryParse(parts.last) : null;
      if (address == null ||
          network == null ||
          bits == null ||
          address.type != network.type ||
          bits < 0 ||
          bits > address.rawAddress.length * 8) {
        return false;
      }
      for (var i = 0; i < address.rawAddress.length; i++) {
        final remaining = bits - i * 8;
        final mask = remaining >= 8
            ? 255
            : remaining <= 0
            ? 0
            : (255 << (8 - remaining)) & 255;
        if ((address.rawAddress[i] & mask) != (network.rawAddress[i] & mask)) {
          return false;
        }
      }
      return true;
    }
    final expression = pattern.split('*').map(RegExp.escape).join('.*');
    final matcher = RegExp('^$expression\$');
    return matcher.hasMatch(host) ||
        matcher.hasMatch('${uri.host.toLowerCase()}:${uri.port}');
  }

  @override
  List<Object?> get props => [http, https, bypass, fallbackToDirect];
}
