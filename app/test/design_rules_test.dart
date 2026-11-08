// Guards against generic "AI-made" design and copy (owner request,
// 2026-11-08). The rules and the reasons are in handbook 3.16. This test
// reads the source; it does not render anything.
//
// When a rule fails: fix the code. Do not add a file to an allow list
// unless the handbook says why that file is an exception.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Words that make UI text sound like marketing or a chat bot. Matched as
/// whole words, without case, inside string literals only.
const bannedWords = [
  'seamless',
  'seamlessly',
  'effortless',
  'effortlessly',
  'unlock',
  'unlocks',
  'elevate',
  'supercharge',
  'empower',
  'empowers',
  'journey',
  'delve',
  'embark',
  'game-changer',
  'revolutionary',
  'magic',
  'magical',
  'powerful',
  'cutting-edge',
  'next-level',
  'unleash',
  'holistic',
  'curated',
  'ai-powered',
  'oops',
  'whoops',
  'awesome',
  'amazing',
  'ultimate',
  'leverage',
  'robust',
  'streamline',
  'vibrant',
  'crush',
  'smash',
  'beast mode',
  "let's",
  "you've got this",
  'level up',
  'boost your',
  'take it to',
  'like a pro',
];

/// Icons that stand for "AI" or "magic" instead of what the control does.
const bannedIcons = ['sparkles', 'sparkle', 'wandSparkles', 'wand', 'stars', 'bot', 'botMessageSquare', 'brain'];

/// Files allowed a raw Color(0x...): the palette and brand files, and the
/// 3D renderers and the GPS notification, which need colours outside the
/// Flutter theme.
const rawColourFiles = {
  'lib/core/palette.dart',
  'lib/core/brand.dart',
  'lib/core/brand_wordmark.dart',
  'lib/core/theme.dart',
  'lib/core/widgets.dart',
  'lib/activity/location_source.dart',
  'lib/features/exercises/viewer.dart',
  'lib/features/exercises/rig/render.dart',
  'lib/features/exercises/body3d/body_map_3d.dart',
  'lib/features/exercises/body3d/body_render.dart',
};

/// Files allowed a gradient: they draw data or a photo fade, not decoration.
const gradientFiles = {
  'lib/features/exercises/library_screen.dart',
  'lib/features/workout/guided_header.dart',
  'lib/features/workout/ring_clock.dart',
  // Shading of the 3D body, not decoration.
  'lib/features/exercises/body3d/body_map_3d.dart',
};

/// Files allowed a fontSize of their own: monospace keys, the 3D labels,
/// and the tab bar badge. Everything else uses the theme's text styles.
const fontSizeFiles = {
  'lib/core/theme.dart',
  // The segmented control's compact size, and the week strip's day letters.
  'lib/core/widgets.dart',
  'lib/features/home/home_screen.dart',
  'lib/features/exercises/viewer.dart',
  'lib/features/exercises/library/photo_motion.dart',
  'lib/features/me/ai_connections_screen.dart',
  'lib/features/me/gateway_setup_screen.dart',
  'lib/features/shell/app_shell.dart',
};

final _string = RegExp(
  r"'((?:[^'\\]|\\.)*)'"
  '|'
  r'"((?:[^"\\]|\\.)*)"',
);
final _emoji = RegExp('[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B50}\u{2705}]', unicode: true);

List<File> _sources() => [
  for (final f in Directory('lib').listSync(recursive: true))
    if (f is File && f.path.endsWith('.dart') && !f.path.endsWith('.g.dart')) f,
];

/// Each non-comment line with its UI-looking string literals (ones that
/// hold a space, so identifiers and keys are left out).
Iterable<(String file, int line, String text)> _uiStrings() sync* {
  for (final f in _sources()) {
    final lines = f.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i].trimLeft();
      if (l.startsWith('//') || l.startsWith('///') || l.startsWith('import ')) continue;
      for (final m in _string.allMatches(lines[i])) {
        final s = m.group(1) ?? m.group(2) ?? '';
        if (s.contains(' ')) yield (f.path.replaceAll(r'\', '/'), i + 1, s);
      }
    }
  }
}

/// [s] without its `${...}` parts, whose `!` is Dart, not text.
String _plain(String s) => s.replaceAll(RegExp(r'\$\{[^}]*\}'), '');

void main() {
  test('UI text has no marketing or chat-bot words', () {
    final hits = <String>[];
    for (final (file, line, s) in _uiStrings()) {
      final low = s.toLowerCase();
      for (final w in bannedWords) {
        if (RegExp('(^|[^a-z])${RegExp.escape(w)}(\$|[^a-z])').hasMatch(low)) hits.add('$file:$line "$w" in "$s"');
      }
    }
    expect(hits, isEmpty, reason: 'Say what the app does in plain words (handbook 3.16).');
  });

  test('UI text has no exclamation marks or emoji', () {
    final hits = <String>[
      for (final (file, line, s) in _uiStrings())
        if (RegExp(r'[A-Za-z0-9)]!(\s|$)').hasMatch(_plain(s)) || _emoji.hasMatch(s)) '$file:$line "$s"',
    ];
    expect(hits, isEmpty, reason: 'Calm, factual text: no "Great job!" and no emoji (handbook 3.16).');
  });

  test('no sparkle, wand, robot, or brain icons', () {
    final hits = <String>[];
    for (final f in _sources()) {
      final src = f.readAsStringSync();
      for (final icon in bannedIcons) {
        if (RegExp('LucideIcons\\.$icon\\b').hasMatch(src)) hits.add('${f.path}: LucideIcons.$icon');
      }
    }
    expect(hits, isEmpty, reason: 'An icon shows what the control does, not that "AI" is involved (handbook 3.16).');
  });

  test('colours, gradients, and font sizes come from the shared theme', () {
    final colours = <String>[], gradients = <String>[], sizes = <String>[];
    for (final f in _sources()) {
      final path = f.path.replaceAll(r'\', '/');
      final src = f.readAsStringSync();
      if (src.contains('Color(0x') && !rawColourFiles.contains(path)) colours.add(path);
      if (RegExp(r'\b(Linear|Radial|Sweep)Gradient\(').hasMatch(src) && !gradientFiles.contains(path)) {
        gradients.add(path);
      }
      if (src.contains('fontSize:') && !fontSizeFiles.contains(path)) sizes.add(path);
    }
    expect(colours, isEmpty, reason: 'Use palette.dart colours (handbook 3.8).');
    expect(gradients, isEmpty, reason: 'No decorative gradients (handbook 3.16).');
    expect(sizes, isEmpty, reason: 'Use the theme text styles, not a new font size (handbook 3.8).');
  });

  test('category colours do not tint icon badges in a rainbow', () {
    // D-032: category colours (coral, blue, orange, green) show data only.
    // A list of three or more of them, cycled over cards, is decoration.
    // Two-colour lists (a ring's gradient for one phase) are data.
    final rainbow = RegExp(r'\[\s*(p\.(coral|blue|orange|green)\s*,\s*){2,}p\.(coral|blue|orange|green)');
    final hits = <String>[
      for (final f in _sources())
        if (rainbow.hasMatch(f.readAsStringSync())) f.path,
    ];
    expect(hits, isEmpty, reason: 'Card and row icons are neutral (D-032).');
  });
}
