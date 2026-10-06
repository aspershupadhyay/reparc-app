// Local MCP server for a Reparc export file.
//
// Usage (from the app/ folder):
//   dart run tool/mcp/server.dart /path/to/reparc-export.json
//
// Then add it to an MCP client. Example for Claude Desktop
// (claude_desktop_config.json):
//   {
//     "mcpServers": {
//       "reparc": {
//         "command": "dart",
//         "args": ["run", "/path/to/reparc/app/tool/mcp/server.dart", "/path/to/reparc-export.json"]
//       }
//     }
//   }
//
// The server reads the file once, answers on stdin/stdout, and opens no
// network port. Logs go to stderr and never include record contents.
import 'dart:convert';
import 'dart:io';

import 'package:reparc/mcp/mcp_server.dart';
import 'package:reparc/mcp/reparc_tools.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tool/mcp/server.dart <reparc-export.json>');
    exitCode = 64;
    return;
  }
  final ReparcSnapshot snapshot;
  try {
    snapshot = ReparcSnapshot((jsonDecode(File(args.single).readAsStringSync()) as Map).cast<String, Object?>());
  } catch (e) {
    stderr.writeln('Could not read the export file: ${e.runtimeType}');
    exitCode = 66;
    return;
  }
  final server = McpServer(snapshot);
  stderr.writeln('Reparc MCP server ready. Shared data: ${snapshot.scopes.join(', ')}.');
  await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim().isEmpty) continue;
    Map<String, Object?>? reply;
    try {
      reply = server.handle((jsonDecode(line) as Map).cast<String, Object?>());
    } catch (_) {
      reply = {
        'jsonrpc': '2.0',
        'id': null,
        'error': {'code': -32700, 'message': 'Parse error'},
      };
    }
    if (reply != null) stdout.writeln(jsonEncode(reply));
  }
}
