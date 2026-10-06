import 'contract.dart';
import 'tools.dart';

/// One line in the AI activity list. It holds the tool name and outcome
/// only, never arguments or results (handbook 10.7).
class ActivityEntry {
  const ActivityEntry({
    required this.at,
    required this.client,
    required this.via,
    required this.tool,
    required this.ok,
  });
  final DateTime at;
  final String client;
  final String via;
  final String tool;
  final bool ok;
}

typedef ActivitySink = void Function(ActivityEntry entry);

/// MCP over JSON-RPC 2.0 for the Wi-Fi server (Streamable HTTP, JSON
/// responses). The online gateway speaks the same protocol on its side and
/// forwards only `tools/call` to the phone.
class McpRpc {
  McpRpc(this.contract, this.tools, {this.onActivity});

  final ToolContract contract;
  final ReparcTools tools;
  final ActivitySink? onActivity;

  /// Handles one JSON-RPC message. Returns null for notifications.
  Future<Map<String, Object?>?> handle(Object? message, {required ToolCaller caller}) async {
    if (message is List) return _error(null, -32600, 'Batch requests are not supported');
    if (message is! Map) return _error(null, -32600, 'Expected a JSON-RPC object');
    final method = message['method'];
    if (method is! String || !message.containsKey('id')) return null;
    final id = message['id'];
    if (message['jsonrpc'] != '2.0') return _error(id, -32600, 'jsonrpc must be "2.0"');
    final params = message['params'];
    switch (method) {
      case 'initialize':
        return _result(id, initializeResult(params));
      case 'ping':
        return _result(id, const <String, Object?>{});
      case 'tools/list':
        return _result(id, {'tools': contract.listed});
      case 'tools/call':
        if (params is! Map || params['name'] is! String) return _error(id, -32602, 'tools/call needs a tool name');
        final name = params['name'] as String;
        if (!contract.tools.containsKey(name)) return _error(id, -32602, 'Unknown tool');
        final args = params['arguments'];
        if (args != null && args is! Map) return _error(id, -32602, 'arguments must be an object');
        final result = await tools.call(name, args, caller);
        onActivity?.call(
          ActivityEntry(at: DateTime.now(), client: caller.client, via: caller.via, tool: name, ok: !result.isError),
        );
        return _result(id, result.toMcp());
      case 'resources/list':
        return _result(id, {'resources': <Object>[]});
      case 'prompts/list':
        return _result(id, {'prompts': <Object>[]});
      default:
        return _error(id, -32601, 'Method not found');
    }
  }

  Map<String, Object?> initializeResult(Object? params) {
    final requested = params is Map ? params['protocolVersion'] : null;
    final versions = contract.supportedVersions;
    return {
      'protocolVersion': requested is String && versions.contains(requested) ? requested : versions.first,
      'capabilities': {
        'tools': {'listChanged': false},
      },
      'serverInfo': contract.server,
      'instructions': contract.instructions,
    };
  }

  static Map<String, Object?> _result(Object? id, Object? result) => {'jsonrpc': '2.0', 'id': id, 'result': result};

  static Map<String, Object?> _error(Object? id, int code, String message) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  };
}

/// Cleans a client name for display: no control characters, at most 40
/// characters, and a neutral default.
String cleanClientName(Object? name, {String fallback = 'An AI app'}) {
  if (name is! String) return fallback;
  final cleaned = name.replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), '').trim();
  if (cleaned.isEmpty) return fallback;
  final runes = cleaned.runes.toList();
  return runes.length <= 40 ? cleaned : String.fromCharCodes(runes.take(40));
}
