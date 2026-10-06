import 'dart:convert';

/// The MCP tool contract in `assets/mcp/tools.json`.
///
/// The phone and the Vercel gateway read the same file, so both list the
/// same tools. CI checks that the gateway's copy is identical.
class ToolContract {
  ToolContract._(this.raw, this.tools);

  factory ToolContract.parse(String json) {
    final raw = jsonDecode(json) as Map<String, dynamic>;
    final tools = {
      for (final t in raw['tools'] as List)
        (t as Map<String, dynamic>)['name'] as String: ToolSpec(t['name'] as String, t['scope'] as String?, t),
    };
    return ToolContract._(raw, tools);
  }

  final Map<String, dynamic> raw;
  final Map<String, ToolSpec> tools;

  String get instructions => raw['instructions'] as String;
  List<String> get supportedVersions => [for (final v in raw['supported_versions'] as List) v as String];
  Map<String, dynamic> get server => raw['server'] as Map<String, dynamic>;

  /// Scope names and their descriptions, in display order.
  Map<String, String> get scopes => (raw['scopes'] as Map<String, dynamic>).cast<String, String>();

  /// Tool definitions as MCP `tools/list` returns them. The `scope` field
  /// is Reparc's own and is left out.
  List<Map<String, dynamic>> get listed => [
    for (final t in tools.values)
      {
        for (final e in t.json.entries)
          if (e.key != 'scope') e.key: e.value,
      },
  ];
}

class ToolSpec {
  const ToolSpec(this.name, this.scope, this.json);
  final String name;

  /// Data category the tool needs, or null when it needs none.
  final String? scope;
  final Map<String, dynamic> json;
}
