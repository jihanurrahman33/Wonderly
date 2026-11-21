import 'dart:convert';

import 'package:wonderly/features/ai/domain/services/content_safety.dart';

/// A card the model designed, already checked and reduced to plain values.
class BuddyCardSpec {
  const BuddyCardSpec({
    required this.title,
    required this.body,
    required this.accent,
    this.actionLabel,
    this.actionSetId,
  });

  final String title;
  final String body;
  final String accent;
  final String? actionLabel;
  final String? actionSetId;
}

/// Checks UI the model wrote in the A2UI format before anything is drawn.
///
/// A small model can produce almost-right JSON. This reads the reply, accepts
/// only the exact shape the app expects (one `BuddyCard`, at most one
/// `ActionButton` that starts a known quiz), checks every string for
/// child-safety, and returns plain values. The app then builds the A2UI
/// messages itself, so nothing unchecked ever reaches the renderer.
class A2uiValidator {
  const A2uiValidator({ContentSafety safety = const ContentSafety()})
    : _safety = safety;

  final ContentSafety _safety;

  static const accents = {'sun', 'sage', 'sky', 'butter', 'cream'};
  static const maxTitle = 40;
  static const maxBody = 180;

  /// Returns the card, or `null` when the reply is not acceptable.
  BuddyCardSpec? parse(String raw, {required Set<String> allowedSetIds}) {
    final components = _components(raw);
    if (components == null) return null;
    final byId = <String, Map<String, Object?>>{};
    for (final c in components) {
      final id = c['id'];
      if (id is! String || byId.containsKey(id)) return null;
      byId[id] = c;
    }
    final root = byId['root'];
    if (root == null || root['component'] != 'BuddyCard') return null;

    final title = root['title'];
    final body = root['body'];
    if (title is! String || body is! String) return null;
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > maxTitle) return null;
    if (cleanBody.isEmpty || cleanBody.length > maxBody) return null;
    if (_safety.check(cleanTitle) != null || _safety.check(cleanBody) != null) {
      return null;
    }

    final accent = root['accent'];
    final spec = BuddyCardSpec(
      title: cleanTitle,
      body: cleanBody,
      accent: accent is String && accents.contains(accent) ? accent : 'sage',
    );

    final childId = root['child'];
    if (childId == null) return spec;
    if (childId is! String) return null;
    final button = byId[childId];
    if (button == null || button['component'] != 'ActionButton') return null;
    final label = button['label'];
    final event = (button['action'] is Map<String, Object?>)
        ? (button['action']! as Map<String, Object?>)['event']
        : null;
    if (label is! String || event is! Map<String, Object?>) return null;
    if (event['name'] != 'startQuiz') return null;
    final ctx = event['context'];
    final setId = ctx is Map<String, Object?> ? ctx['setId'] : null;
    if (setId is! String || !allowedSetIds.contains(setId)) return null;
    final cleanLabel = label.trim();
    if (cleanLabel.isEmpty ||
        cleanLabel.length > 32 ||
        _safety.check(cleanLabel) != null) {
      return null;
    }
    return BuddyCardSpec(
      title: spec.title,
      body: spec.body,
      accent: spec.accent,
      actionLabel: cleanLabel,
      actionSetId: setId,
    );
  }

  /// Pulls the `components` list out of an `updateComponents` message.
  List<Map<String, Object?>>? _components(String raw) {
    for (final object in _jsonObjects(raw)) {
      final update = object['updateComponents'];
      if (update is Map<String, Object?>) {
        final list = update['components'];
        if (list is List<Object?> &&
            list.every((c) => c is Map<String, Object?>)) {
          return [for (final c in list) c! as Map<String, Object?>];
        }
      }
    }
    return null;
  }

  Iterable<Map<String, Object?>> _jsonObjects(String raw) sync* {
    var depth = 0;
    var start = -1;
    var inString = false;
    var escaped = false;
    for (var i = 0; i < raw.length; i++) {
      final ch = raw[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == r'\') {
          escaped = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
      } else if (ch == '{') {
        if (depth == 0) start = i;
        depth++;
      } else if (ch == '}' && depth > 0) {
        depth--;
        if (depth == 0 && start >= 0) {
          try {
            final decoded = jsonDecode(raw.substring(start, i + 1));
            if (decoded is Map<String, Object?>) yield decoded;
          } on FormatException {
            // Skip malformed fragments and keep scanning.
          }
          start = -1;
        }
      }
    }
  }
}
