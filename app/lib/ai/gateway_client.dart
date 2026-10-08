import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'rpc.dart';
import 'tools.dart';

/// Repository that holds the Vercel gateway (`gateway/` folder).
/// The private source repository; the gateway deploys from its gateway/ folder.
const gatewayRepository = 'https://github.com/aspershupadhyay/reparc-app';

/// One-click deploy of the gateway into the owner's own Vercel account,
/// with an Upstash Redis store from the Vercel Marketplace. Vercel asks for
/// REPARC_OWNER_KEY; the owner pastes the key the app made.
String vercelDeployUrl() {
  String enc(String s) => Uri.encodeQueryComponent(s);
  const stores = '[{"type":"integration","integrationSlug":"upstash","productSlug":"upstash-kv","protocol":"storage"}]';
  return 'https://vercel.com/new/clone'
      '?repository-url=${enc(gatewayRepository)}'
      '&root-directory=gateway'
      '&project-name=reparc-gateway&repository-name=reparc-gateway'
      '&env=REPARC_OWNER_KEY'
      '&envDescription=${enc('Paste the owner key from the Reparc app. It stays in your Vercel project and on your phone.')}'
      '&envLink=${enc('$gatewayRepository/blob/main/gateway/README.md')}'
      '&stores=${enc(stores)}';
}

/// A new 256-bit owner key for REPARC_OWNER_KEY.
String newOwnerKey() {
  final r = Random.secure();
  return 'rok_${List.generate(32, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}

/// Normalises what the user pasted into an https base URL, or null.
///
/// Plain http is accepted only for this computer's loopback address, for
/// development. The owner key never travels over plain http on a network.
Uri? parseGatewayAddress(String input) {
  var text = input.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'https://$text';
  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty || uri.userInfo.isNotEmpty) return null;
  final loopback = uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '10.0.2.2';
  if (uri.scheme != 'https' && !(uri.scheme == 'http' && loopback)) return null;
  var path = uri.path;
  String trimSlashes(String p) => p.endsWith('/') ? trimSlashes(p.substring(0, p.length - 1)) : p;
  path = trimSlashes(path);
  if (path.endsWith('/mcp')) path = trimSlashes(path.substring(0, path.length - 4));
  return uri.replace(path: path, query: null, fragment: null);
}

class GatewayException implements Exception {
  const GatewayException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

/// An AI app the owner approved on their gateway.
class GatewayApp {
  const GatewayApp({
    required this.id,
    required this.name,
    required this.kind,
    required this.createdAt,
    this.lastUsedAt,
  });
  factory GatewayApp.fromJson(Map<String, dynamic> j) => GatewayApp(
    id: j['id'] as String,
    name: cleanClientName(j['name']),
    kind: j['kind'] as String? ?? 'oauth',
    createdAt: DateTime.fromMillisecondsSinceEpoch((j['created_at_ms'] as num).toInt()),
    lastUsedAt: j['last_used_ms'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch((j['last_used_ms'] as num).toInt()),
  );
  final String id;
  final String name;

  /// 'oauth' (signed in through the browser) or 'key' (a key from the app).
  final String kind;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
}

/// An AI app waiting for the owner to approve its sign-in.
class SignInRequest {
  const SignInRequest({required this.id, required this.client, required this.match, required this.returnsTo});
  factory SignInRequest.fromJson(Map<String, dynamic> j) => SignInRequest(
    id: j['id'] as String,
    client: cleanClientName(j['client_name']),
    match: (j['match'] as String? ?? '').replaceAll(RegExp('[^A-Z0-9]'), ''),
    returnsTo: cleanClientName(j['return_host'], fallback: 'an app'),
  );
  final String id;
  final String client;

  /// Short code the browser page shows. The owner checks that both match.
  final String match;
  final String returnsTo;
}

class GatewayState {
  const GatewayState({this.apps = const [], this.requests = const []});
  final List<GatewayApp> apps;
  final List<SignInRequest> requests;
}

/// Owner API of the user's own gateway. Every call sends the owner key over
/// HTTPS. Redirects are not followed, so the key cannot leak to another host.
class GatewayApi {
  GatewayApi(this.base, this.ownerKey, {HttpClient? client}) : _http = client ?? HttpClient() {
    _http.connectionTimeout = const Duration(seconds: 15);
  }

  final Uri base;
  final String ownerKey;
  final HttpClient _http;

  Uri get mcpUrl => base.replace(path: '${base.path}/mcp');

  Future<Object?> _call(
    String method,
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final uri = base.replace(path: '${base.path}$path');
    try {
      final req = await _http.openUrl(method, uri).timeout(timeout);
      req.followRedirects = false;
      req.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $ownerKey')
        ..set(HttpHeaders.acceptHeader, 'application/json');
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.add(utf8.encode(jsonEncode(body)));
      }
      final res = await req.close().timeout(timeout);
      final text = await res.transform(utf8.decoder).join().timeout(timeout);
      if (res.statusCode == 204 || text.isEmpty) return null;
      final Object? json;
      try {
        json = jsonDecode(text);
      } on FormatException {
        throw GatewayException('This address did not answer like a Reparc gateway.', status: res.statusCode);
      }
      if (res.statusCode == 401) {
        throw const GatewayException('The owner key does not match REPARC_OWNER_KEY in Vercel.', status: 401);
      }
      if (res.statusCode >= 300) {
        final msg = json is Map && json['error'] is String
            ? json['error'] as String
            : 'Gateway error ${res.statusCode}';
        throw GatewayException(msg, status: res.statusCode);
      }
      return json;
    } on GatewayException {
      rethrow;
    } on TimeoutException {
      throw const GatewayException('The gateway did not answer in time.');
    } on HandshakeException {
      throw const GatewayException('The secure connection failed. Check the address.');
    } on SocketException {
      throw const GatewayException('Could not reach the gateway. Check the address and your connection.');
    } on HttpException {
      throw const GatewayException('The connection to the gateway broke. Try again.');
    }
  }

  /// Checks that [base] is a Reparc gateway that knows this owner key.
  Future<void> verify() async {
    final info = await _call('GET', '/v1/info');
    if (info is! Map || info['product'] != 'reparc-gateway') {
      throw const GatewayException('This address is not a Reparc gateway.');
    }
    if (info['setup_required'] == true) {
      throw const GatewayException(
        'The gateway is not set up yet. Add REPARC_OWNER_KEY (and the Upstash store) in Vercel, then redeploy.',
      );
    }
    await state();
  }

  Future<GatewayState> state() async {
    final j = await _call('GET', '/v1/owner/state');
    if (j is! Map) throw const GatewayException('Unexpected answer from the gateway.');
    return GatewayState(
      apps: [for (final a in (j['apps'] as List? ?? const [])) GatewayApp.fromJson((a as Map).cast<String, dynamic>())],
      requests: [
        for (final r in (j['requests'] as List? ?? const []))
          SignInRequest.fromJson((r as Map).cast<String, dynamic>()),
      ],
    );
  }

  Future<void> decide(String requestId, {required bool approve}) =>
      _call('POST', '/v1/owner/requests/${Uri.encodeComponent(requestId)}', body: {'approve': approve});

  Future<void> revoke(String appId) => _call('DELETE', '/v1/owner/apps/${Uri.encodeComponent(appId)}');

  /// Creates a key for an AI app that cannot sign in through a browser.
  Future<String> createKey(String name) async {
    final j = await _call('POST', '/v1/owner/keys', body: {'name': name});
    if (j is! Map || j['key'] is! String) throw const GatewayException('Unexpected answer from the gateway.');
    return j['key'] as String;
  }

  /// Waits up to about 25 seconds for tool calls from AI apps.
  Future<List<Map<String, dynamic>>> poll() async {
    final j = await _call('GET', '/v1/phone/poll', timeout: const Duration(seconds: 40));
    if (j is! Map) return const [];
    return [for (final c in (j['calls'] as List? ?? const [])) (c as Map).cast<String, dynamic>()];
  }

  Future<void> sendResults(List<Map<String, Object?>> results) =>
      _call('POST', '/v1/phone/results', body: {'results': results});

  void close() => _http.close(force: true);
}

enum RelayStatus { stopped, connecting, online, retrying }

/// Answers tool calls that arrive through the owner's gateway while the
/// user keeps online access on and Reparc open.
///
/// The gateway forwards each call; the phone runs it against the local
/// database and sends back only that answer. The gateway keeps no copy of
/// the records (see gateway/README.md).
class GatewayRelay {
  GatewayRelay({required this.api, required this.tools, this.onActivity, this.onStatus});

  final GatewayApi api;
  final ReparcTools tools;
  final ActivitySink? onActivity;
  final void Function(RelayStatus status, String? message)? onStatus;

  bool _running = false;
  int _failures = 0;

  bool get running => _running;

  void start() {
    if (_running) return;
    _running = true;
    unawaited(_loop());
  }

  void stop() {
    _running = false;
    onStatus?.call(RelayStatus.stopped, null);
  }

  Future<void> _loop() async {
    onStatus?.call(RelayStatus.connecting, null);
    while (_running) {
      try {
        final calls = await api.poll();
        if (!_running) break;
        _failures = 0;
        onStatus?.call(RelayStatus.online, null);
        if (calls.isEmpty) continue;
        final results = <Map<String, Object?>>[];
        for (final c in calls) {
          final id = c['id'];
          final tool = c['tool'];
          if (id is! String || tool is! String) continue;
          final caller = ToolCaller(client: cleanClientName(c['client']), via: 'online');
          final r = await tools.call(tool, c['arguments'], caller);
          onActivity?.call(
            ActivityEntry(at: DateTime.now(), client: caller.client, via: 'online', tool: tool, ok: !r.isError),
          );
          results.add({'id': id, 'result': r.toMcp()});
        }
        if (results.isNotEmpty) await api.sendResults(results);
      } on GatewayException catch (e) {
        if (!_running) break;
        _failures++;
        if (e.status == 401) {
          // A changed owner key will not start working by retrying.
          _running = false;
          onStatus?.call(RelayStatus.stopped, e.message);
          return;
        }
        onStatus?.call(RelayStatus.retrying, e.message);
        await Future<void>.delayed(_backoff());
      } catch (_) {
        if (!_running) break;
        _failures++;
        onStatus?.call(RelayStatus.retrying, 'Connection problem. Retrying.');
        await Future<void>.delayed(_backoff());
      }
    }
  }

  Duration _backoff() => Duration(seconds: const [1, 2, 5, 10, 20, 30][min(_failures - 1, 5)]);
}
