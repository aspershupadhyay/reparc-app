/// Checks tool arguments against the JSON Schema subset used in
/// `assets/mcp/tools.json`.
///
/// The phone checks every argument itself. It never trusts the gateway or
/// the AI client to do it. Returns null when [value] is valid, otherwise a
/// short message that names the field.
String? validateSchema(Map<String, dynamic> schema, Object? value, [String path = 'arguments']) {
  final type = schema['type'];
  switch (type) {
    case 'object':
      if (value is! Map) return '$path must be an object';
      final props = (schema['properties'] as Map?)?.cast<String, dynamic>() ?? const {};
      for (final r in (schema['required'] as List?) ?? const []) {
        if (!value.containsKey(r) || value[r] == null) return '$path.$r is required';
      }
      for (final e in value.entries) {
        final key = e.key;
        if (key is! String) return '$path has a key that is not text';
        final sub = props[key];
        if (sub == null) {
          if (schema['additionalProperties'] == false) return '$path.$key is not a known field';
          continue;
        }
        if (e.value == null) continue;
        final err = validateSchema((sub as Map).cast<String, dynamic>(), e.value, '$path.$key');
        if (err != null) return err;
      }
      return null;
    case 'array':
      if (value is! List) return '$path must be a list';
      final min = schema['minItems'] as int?;
      final max = schema['maxItems'] as int?;
      if (min != null && value.length < min) return '$path needs at least $min items';
      if (max != null && value.length > max) return '$path allows at most $max items';
      final items = (schema['items'] as Map?)?.cast<String, dynamic>();
      if (items != null) {
        for (final (i, v) in value.indexed) {
          final err = validateSchema(items, v, '$path[$i]');
          if (err != null) return err;
        }
      }
      return null;
    case 'string':
      if (value is! String) return '$path must be text';
      final len = value.runes.length;
      final min = schema['minLength'] as int?;
      final max = schema['maxLength'] as int?;
      if (min != null && value.trim().length < min) return '$path is too short';
      if (max != null && len > max) return '$path is longer than $max characters';
      if (_control.hasMatch(value)) return '$path contains control characters';
      final pattern = schema['pattern'] as String?;
      if (pattern != null && !RegExp(pattern).hasMatch(value)) return '$path has the wrong format';
      final allowed = schema['enum'] as List?;
      if (allowed != null && !allowed.contains(value)) return '$path must be one of ${allowed.join(', ')}';
      return null;
    case 'integer':
      if (value is! int) return '$path must be a whole number';
      return _range(schema, value, path);
    case 'number':
      if (value is! num || value.isNaN || value.isInfinite) return '$path must be a number';
      return _range(schema, value, path);
    default:
      return null;
  }
}

String? _range(Map<String, dynamic> schema, num value, String path) {
  final min = schema['minimum'] as num?;
  final max = schema['maximum'] as num?;
  final exMin = schema['exclusiveMinimum'] as num?;
  if (min != null && value < min) return '$path must be at least $min';
  if (exMin != null && value <= exMin) return '$path must be more than $exMin';
  if (max != null && value > max) return '$path must be at most $max';
  return null;
}

/// Control characters other than tab and new line.
final _control = RegExp(r'[\u0000-\u0008\u000B-\u001F\u007F-\u009F]');
