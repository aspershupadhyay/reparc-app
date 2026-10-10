/// A minimal Model Context Protocol server for RepArc data.
///
/// It speaks JSON-RPC 2.0, one message per line, over stdin and stdout
/// (the MCP "stdio" transport). It offers read-only tools over one export
/// file. It opens no network port and sends nothing anywhere.
///
/// Protocol: https://modelcontextprotocol.io/specification
library;

import 'dart:convert';

import 'reparc_tools.dart';

const serverName = 'reparc';
const serverVersion = '0.1.0';

/// Protocol versions this server accepts. It answers with the client's
/// version when it is listed, else the newest one here.
const supportedProtocols = ['2026-07-28', '2025-11-25', '2025-06-18', '2025-03-26', '2024-11-05'];

class McpServer {
  McpServer(this.snapshot);
  final ReparcSnapshot snapshot;

  /// Handles one message. Returns the reply, or null for a notification.
  Map<String, Object?>? handle(Map<String, Object?> msg) {
    final id = msg['id'];
    final method = msg['method'];
    final params = (msg['params'] as Map?)?.cast<String, Object?>() ?? const {};
    if (method is! String) return id == null ? null : _error(id, -32600, 'Invalid request');
    // Notifications have no id and get no reply.
    if (id == null) return null;
    try {
      return switch (method) {
        'initialize' => _result(id, {
          'protocolVersion': supportedProtocols.contains(params['protocolVersion'])
              ? params['protocolVersion']
              : supportedProtocols.first,
          'capabilities': {
            'tools': {'listChanged': false},
          },
          'serverInfo': {'name': serverName, 'version': serverVersion},
          'instructions':
              'Read-only access to one RepArc export (workouts, meals, body data the user chose to share). '
              'Do not invent values: null means not recorded. RepArc is not a medical service. To suggest a '
              'roadmap or meal plan, use get_import_formats, then the check_ tools, and give the user the JSON '
              'to import in the app.',
        }),
        'ping' => _result(id, const {}),
        'tools/list' => _result(id, {
          'tools': [for (final t in toolsFor(snapshot)) t.toJson()],
        }),
        'tools/call' => _call(id, params),
        _ => _error(id, -32601, 'Method not found: $method'),
      };
    } catch (e) {
      return _error(id, -32603, 'Internal error');
    }
  }

  Map<String, Object?> _call(Object id, Map<String, Object?> params) {
    final name = params['name'];
    if (name is! String) return _error(id, -32602, 'Missing tool name');
    final args = (params['arguments'] as Map?)?.cast<String, Object?>() ?? const {};
    try {
      final out = callTool(snapshot, name, args);
      return _result(id, {
        'content': [
          {'type': 'text', 'text': const JsonEncoder.withIndent(' ').convert(out)},
        ],
        'structuredContent': out,
        'isError': false,
      });
    } on ArgumentError catch (e) {
      // Tool errors go back to the model so it can fix its call.
      return _result(id, {
        'content': [
          {'type': 'text', 'text': '${e.message}'},
        ],
        'isError': true,
      });
    }
  }

  Map<String, Object?> _result(Object id, Object result) => {'jsonrpc': '2.0', 'id': id, 'result': result};

  Map<String, Object?> _error(Object id, int code, String message) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  };
}
