import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'rpc.dart';
import 'tools.dart';

/// MCP server on the phone's Wi-Fi network (handbook 10.6, D-018).
///
/// It runs only while the user keeps it on, and stops by itself after the
/// time they chose. Each request must:
///
/// - come from a private network address (home or office Wi-Fi),
/// - carry the access key as `Authorization: Bearer <key>`,
/// - have no `Origin` header, so a web page cannot call it (DNS rebinding),
/// - be a JSON POST to `/mcp` of at most 256 KB.
///
/// An address that sends 10 wrong keys is blocked for 10 minutes. The
/// connection is plain HTTP inside the local network. Use it only on a
/// network you trust; the online gateway uses HTTPS.
class LanMcpServer {
  LanMcpServer({required this.rpc, required this.accessKey, this.port = defaultPort, this.now = DateTime.now});

  static const defaultPort = 8765;
  static const maxBody = 256 * 1024;
  static const _maxFailures = 10;
  static const _blockFor = Duration(minutes: 10);

  final McpRpc rpc;
  final String accessKey;
  final int port;
  final DateTime Function() now;

  HttpServer? _server;
  final _failures = <String, List<DateTime>>{};
  final _blocked = <String, DateTime>{};

  /// Client names from `initialize`, by MCP session ID.
  final _sessions = <String, String>{};

  int? get boundPort => _server?.port;
  bool get running => _server != null;

  /// Starts listening on all IPv4 interfaces. If [port] is taken, a free
  /// port is used instead.
  Future<int> start({InternetAddress? address}) async {
    if (_server != null) return _server!.port;
    final bind = address ?? InternetAddress.anyIPv4;
    HttpServer server;
    try {
      server = await HttpServer.bind(bind, port);
    } on SocketException {
      server = await HttpServer.bind(bind, 0);
    }
    server.idleTimeout = const Duration(seconds: 30);
    server.serverHeader = null;
    _server = server;
    server.listen(_handle, onError: (_) {});
    return server.port;
  }

  Future<void> stop() async {
    final s = _server;
    _server = null;
    _sessions.clear();
    await s?.close(force: true);
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    res.headers
      ..set('cache-control', 'no-store')
      ..set('x-content-type-options', 'nosniff');
    try {
      final ip = req.connectionInfo?.remoteAddress;
      if (ip == null || !isPrivateAddress(ip)) {
        return await _send(res, 403, {'error': 'Only devices on the same local network can connect.'});
      }
      final key = ip.address;
      final blockedUntil = _blocked[key];
      if (blockedUntil != null && now().isBefore(blockedUntil)) {
        return await _send(res, 429, {'error': 'Too many wrong keys. Try again later.'});
      }
      if (req.headers.value('origin') != null) {
        return await _send(res, 403, {'error': 'Browser requests are not allowed.'});
      }
      if (req.uri.path != '/mcp') return await _send(res, 404, {'error': 'Not found. Use /mcp.'});
      if (req.method != 'POST') {
        res.headers.set('allow', 'POST');
        return await _send(res, 405, {'error': 'Use POST. This server does not open event streams.'});
      }
      if (!_authorized(req.headers.value('authorization'))) {
        _fail(key);
        res.headers.set('www-authenticate', 'Bearer');
        return await _send(res, 401, {
          'error': 'Missing or wrong access key. Copy it from Reparc → Me → AI connections.',
        });
      }
      _failures.remove(key);
      if ((req.contentLength) > maxBody) return await _send(res, 413, {'error': 'Request is too large.'});
      final body = await _readBody(req);
      if (body == null) return await _send(res, 413, {'error': 'Request is too large.'});
      Object? message;
      try {
        message = jsonDecode(body);
      } on FormatException {
        return await _send(res, 400, {
          'jsonrpc': '2.0',
          'id': null,
          'error': {'code': -32700, 'message': 'Parse error'},
        });
      }
      final isInit = message is Map && message['method'] == 'initialize';
      var session = req.headers.value('mcp-session-id');
      if (isInit) {
        session = _newSessionId();
        final params = message['params'];
        final info = params is Map ? params['clientInfo'] : null;
        if (_sessions.length > 50) _sessions.remove(_sessions.keys.first);
        _sessions[session] = cleanClientName(info is Map ? info['name'] : null, fallback: 'Wi-Fi client');
        res.headers.set('mcp-session-id', session);
      }
      final client = _sessions[session] ?? 'Wi-Fi client';
      final reply = await rpc.handle(
        message,
        caller: ToolCaller(client: client, via: 'wifi'),
      );
      if (reply == null) {
        res.statusCode = 202;
        await res.close();
        return;
      }
      await _send(res, 200, reply);
    } catch (_) {
      try {
        await _send(res, 500, {'error': 'Internal error'});
      } catch (_) {}
    }
  }

  bool _authorized(String? header) {
    if (header == null) return false;
    final parts = header.split(' ');
    if (parts.length != 2 || parts[0].toLowerCase() != 'bearer') return false;
    return constantTimeEquals(parts[1].trim(), accessKey);
  }

  void _fail(String ip) {
    final t = now();
    final list = (_failures[ip] ??= [])
      ..add(t)
      ..removeWhere((x) => t.difference(x) > _blockFor);
    if (list.length >= _maxFailures) {
      _blocked[ip] = t.add(_blockFor);
      _failures.remove(ip);
    }
  }

  static Future<String?> _readBody(HttpRequest req) async {
    final bytes = <int>[];
    await for (final chunk in req) {
      bytes.addAll(chunk);
      if (bytes.length > maxBody) return null;
    }
    return utf8.decode(bytes, allowMalformed: false);
  }

  static Future<void> _send(HttpResponse res, int status, Object body) async {
    res.statusCode = status;
    res.headers.contentType = ContentType.json;
    res.write(jsonEncode(body));
    await res.close();
  }

  static String _newSessionId() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}

/// A new 256-bit access key for the Wi-Fi server.
String newAccessKey() {
  final r = Random.secure();
  final bytes = List<int>.generate(32, (_) => r.nextInt(256));
  return 'rpl_${base64Url.encode(bytes).replaceAll('=', '')}';
}

/// Compares two secrets without leaking where they differ.
bool constantTimeEquals(String a, String b) {
  final x = utf8.encode(a), y = utf8.encode(b);
  var diff = x.length ^ y.length;
  for (var i = 0; i < x.length; i++) {
    diff |= x[i] ^ (i < y.length ? y[i] : 0);
  }
  return diff == 0;
}

/// Loopback, private (RFC 1918), link-local, and carrier-grade NAT (used by
/// some phone hotspots) addresses, and IPv6 unique-local and link-local.
bool isPrivateAddress(InternetAddress ip) {
  if (ip.isLoopback || ip.isLinkLocal) return true;
  final b = ip.rawAddress;
  if (ip.type == InternetAddressType.IPv4) {
    return b[0] == 10 ||
        (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
        (b[0] == 192 && b[1] == 168) ||
        (b[0] == 100 && b[1] >= 64 && b[1] <= 127);
  }
  if (ip.type == InternetAddressType.IPv6) {
    // IPv4-mapped (::ffff:a.b.c.d).
    final mapped = b.sublist(0, 10).every((x) => x == 0) && b[10] == 0xff && b[11] == 0xff;
    if (mapped) return isPrivateAddress(InternetAddress.fromRawAddress(b.sublist(12)));
    return (b[0] & 0xfe) == 0xfc;
  }
  return false;
}

/// The phone's IPv4 addresses on local networks, Wi-Fi first when the
/// interface name shows it.
Future<List<String>> localAddresses() async {
  final list = await NetworkInterface.list(type: InternetAddressType.IPv4);
  int rank(NetworkInterface i) {
    final n = i.name.toLowerCase();
    if (n.startsWith('wlan') || n == 'en0') return 0;
    if (n.startsWith('ap') || n.startsWith('swlan') || n.startsWith('bridge')) return 1;
    return 2;
  }

  list.sort((a, b) => rank(a).compareTo(rank(b)));
  return [
    for (final i in list)
      for (final a in i.addresses)
        if (!a.isLoopback && isPrivateAddress(a)) a.address,
  ];
}
