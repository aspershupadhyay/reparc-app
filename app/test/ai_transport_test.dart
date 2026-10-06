import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/ai/gateway_client.dart';
import 'package:reparc/ai/lan_server.dart';
import 'package:reparc/ai/rpc.dart';

import 'ai_tools_test.dart' show AiFixture;

Future<(int, Map<String, dynamic>?, HttpHeaders)> post(
  int port,
  Object body, {
  String? key,
  Map<String, String> headers = const {},
  String path = '/mcp',
  String method = 'POST',
}) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl(method, Uri.parse('http://127.0.0.1:$port$path'));
    if (key != null) req.headers.set('authorization', 'Bearer $key');
    headers.forEach(req.headers.set);
    req.headers.contentType = ContentType.json;
    if (method == 'POST') req.write(body is String ? body : jsonEncode(body));
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    return (res.statusCode, text.isEmpty ? null : jsonDecode(text) as Map<String, dynamic>, res.headers);
  } finally {
    client.close(force: true);
  }
}

void main() {
  late AiFixture f;
  setUp(() => f = AiFixture());
  tearDown(() => f.db.close());

  group('Wi-Fi server', () {
    late LanMcpServer server;
    late int port;
    final log = <ActivityEntry>[];
    final key = newAccessKey();

    setUp(() async {
      log.clear();
      server = LanMcpServer(
        rpc: McpRpc(AiFixture.contract, f.tools, onActivity: log.add),
        accessKey: key,
        port: 0,
      );
      port = await server.start(address: InternetAddress.loopbackIPv4);
    });
    tearDown(() => server.stop());

    const init = {
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {
        'protocolVersion': '2025-06-18',
        'clientInfo': {'name': 'Codex'},
      },
    };

    test('keys are long, random, and compared exactly', () {
      expect(key, startsWith('rpl_'));
      expect(key.length, greaterThan(40));
      expect(newAccessKey(), isNot(key));
      expect(constantTimeEquals(key, key), isTrue);
      expect(constantTimeEquals(key, '${key}x'), isFalse);
      expect(constantTimeEquals('', key), isFalse);
    });

    test('a request without the key is refused', () async {
      final (status, body, headers) = await post(port, init);
      expect(status, 401);
      expect(body!['error'], contains('access key'));
      expect(headers.value('www-authenticate'), 'Bearer');
      expect((await post(port, init, key: 'rpl_wrong')).$1, 401);
    });

    test('browser requests (Origin header) are refused even with the key', () async {
      expect((await post(port, init, key: key, headers: {'origin': 'http://evil.example'})).$1, 403);
    });

    test('only POST /mcp is served', () async {
      expect((await post(port, init, key: key, path: '/')).$1, 404);
      expect((await post(port, init, key: key, method: 'GET')).$1, 405);
    });

    test('ten wrong keys block the address', () async {
      for (var i = 0; i < 10; i++) {
        await post(port, init, key: 'rpl_wrong$i');
      }
      expect((await post(port, init, key: key)).$1, 429);
    });

    test('large bodies and bad JSON are refused', () async {
      expect((await post(port, 'x' * (LanMcpServer.maxBody + 10), key: key)).$1, 413);
      final (status, body, _) = await post(port, '{nope', key: key);
      expect(status, 400);
      expect((body!['error'] as Map)['code'], -32700);
    });

    test('an MCP client can initialize, list, and call tools', () async {
      final (s1, b1, h1) = await post(port, init, key: key);
      expect(s1, 200);
      expect((b1!['result'] as Map)['serverInfo'], containsPair('name', 'reparc'));
      final session = h1.value('mcp-session-id');
      expect(session, isNotNull);
      final (s2, _, _) = await post(port, {'jsonrpc': '2.0', 'method': 'notifications/initialized'}, key: key);
      expect(s2, 202);
      final (_, b3, _) = await post(port, {'jsonrpc': '2.0', 'id': 2, 'method': 'tools/list'}, key: key);
      expect(((b3!['result'] as Map)['tools'] as List), hasLength(12));
      final (_, b4, _) = await post(
        port,
        {
          'jsonrpc': '2.0',
          'id': 3,
          'method': 'tools/call',
          'params': {'name': 'get_overview', 'arguments': <String, Object>{}},
        },
        key: key,
        headers: {'mcp-session-id': session!},
      );
      expect((b4!['result'] as Map)['isError'], isFalse);
      expect(log.single.client, 'Codex');
      expect(log.single.via, 'wifi');
    });

    test('only private network addresses count as local', () {
      bool p(String a) => isPrivateAddress(InternetAddress(a));
      expect(p('192.168.1.20'), isTrue);
      expect(p('10.0.0.5'), isTrue);
      expect(p('172.20.1.1'), isTrue);
      expect(p('127.0.0.1'), isTrue);
      expect(p('100.100.1.1'), isTrue);
      expect(p('fd00::1'), isTrue);
      expect(p('::ffff:192.168.1.2'), isTrue);
      expect(p('8.8.8.8'), isFalse);
      expect(p('172.32.0.1'), isFalse);
      expect(p('2001:4860::8888'), isFalse);
      expect(p('::ffff:8.8.8.8'), isFalse);
    });
  });

  group('online gateway', () {
    test('addresses must be https except loopback', () {
      expect(parseGatewayAddress('reparc-gateway-me.vercel.app').toString(), 'https://reparc-gateway-me.vercel.app');
      expect(parseGatewayAddress('https://x.vercel.app/mcp/').toString(), 'https://x.vercel.app');
      expect(parseGatewayAddress('http://x.vercel.app'), isNull);
      expect(parseGatewayAddress('https://user:pw@x.vercel.app'), isNull);
      expect(parseGatewayAddress('http://127.0.0.1:8788').toString(), 'http://127.0.0.1:8788');
      expect(parseGatewayAddress(''), isNull);
    });

    test('owner keys and the deploy link', () {
      final k = newOwnerKey();
      expect(k, matches(RegExp(r'^rok_[0-9a-f]{64}$')));
      final url = Uri.parse(vercelDeployUrl());
      expect(url.host, 'vercel.com');
      expect(url.queryParameters['root-directory'], 'gateway');
      expect(url.queryParameters['env'], 'REPARC_OWNER_KEY');
      expect(url.queryParameters['repository-url'], 'https://github.com/aspershupadhyay/reparc');
      expect(url.queryParameters['env'], isNot(contains(k)));
    });

    test('the relay answers forwarded calls and sends only results back', () async {
      await f.share(['gym']);
      final owner = newOwnerKey();
      final results = Completer<Map<String, dynamic>>();
      var polls = 0;
      final fake = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      fake.listen((req) async {
        final authed = req.headers.value('authorization') == 'Bearer $owner';
        req.response.headers.contentType = ContentType.json;
        if (!authed) {
          req.response.statusCode = 401;
          req.response.write('{"error":"no"}');
        } else if (req.uri.path == '/v1/phone/poll') {
          polls++;
          req.response.write(
            jsonEncode({
              'calls': polls == 1
                  ? [
                      {'id': 'c_1', 'client': 'Claude', 'tool': 'list_workouts', 'arguments': <String, Object>{}},
                      {'id': 'c_2', 'client': 'Claude', 'tool': 'list_meals', 'arguments': <String, Object>{}},
                    ]
                  : [],
            }),
          );
          if (polls > 1) await Future<void>.delayed(const Duration(milliseconds: 50));
        } else if (req.uri.path == '/v1/phone/results') {
          final body = jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>;
          if (!results.isCompleted) results.complete(body);
          req.response.statusCode = 204;
        }
        await req.response.close();
      });
      final api = GatewayApi(Uri.parse('http://127.0.0.1:${fake.port}'), owner);
      final log = <ActivityEntry>[];
      final relay = GatewayRelay(api: api, tools: f.tools, onActivity: log.add)..start();
      final body = await results.future.timeout(const Duration(seconds: 10));
      relay.stop();
      api.close();
      await fake.close(force: true);

      final list = (body['results'] as List).cast<Map<String, dynamic>>();
      expect(list.map((r) => r['id']), ['c_1', 'c_2']);
      expect((list[0]['result'] as Map)['isError'], isFalse);
      // Meal data is not shared, so that call is refused on the phone.
      expect((list[1]['result'] as Map)['isError'], isTrue);
      expect(log.map((e) => '${e.client}/${e.via}/${e.ok}'), ['Claude/online/true', 'Claude/online/false']);
    });

    test('a wrong owner key stops the relay', () async {
      final fake = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      fake.listen((req) async {
        req.response.statusCode = 401;
        req.response.headers.contentType = ContentType.json;
        req.response.write('{"error":"missing or wrong bearer token"}');
        await req.response.close();
      });
      final stopped = Completer<String?>();
      final api = GatewayApi(Uri.parse('http://127.0.0.1:${fake.port}'), 'rok_wrong_wrong_wrong_wrong_wrong_wrong');
      GatewayRelay(
        api: api,
        tools: f.tools,
        onStatus: (s, m) {
          if (s == RelayStatus.stopped && !stopped.isCompleted) stopped.complete(m);
        },
      ).start();
      expect(await stopped.future.timeout(const Duration(seconds: 10)), contains('owner key'));
      api.close();
      await fake.close(force: true);
    });
  });
}
