import 'dart:async';
import 'dart:convert';

import 'package:genui/genui.dart';
import 'package:wonderly/core/utils/app_logger.dart';
import 'package:wonderly/features/ai/domain/services/llm_client.dart';
import 'package:wonderly/features/ai/domain/usecases/a2ui_validator.dart';
import 'package:wonderly/features/ai/presentation/a2ui/wonderly_catalog.dart';

/// What the agent knows when it writes a message.
class BuddyBrief {
  const BuddyBrief({
    required this.kind,
    required this.name,
    required this.grade,
    required this.stars,
    required this.streak,
    required this.minutesThisWeek,
    required this.suggestedSetId,
    required this.suggestedSetTitle,
    required this.allowedSetIds,
    this.strongSubjects = const [],
    this.practiceSubjects = const [],
  });

  final BuddyKind kind;
  final String name;
  final int grade;
  final int stars;
  final int streak;
  final int minutesThisWeek;
  final String suggestedSetId;
  final String suggestedSetTitle;
  final Set<String> allowedSetIds;
  final List<String> strongSubjects;
  final List<String> practiceSubjects;
}

enum BuddyKind {
  /// A short encouraging card for the child on Home.
  tip,

  /// A weekly summary for the grown-ups.
  report,
}

/// Smart Buddy: an on-device agent that answers with A2UI.
///
/// The language model writes the words and chooses the next quiz; the result is
/// validated, then turned into A2UI messages that flow through genui's
/// transport and surface controller exactly like messages from any other
/// agent. If the model is missing, slow or wrong, a deterministic message
/// takes its place, so the card is always there and always correct.
class BuddyAgent {
  BuddyAgent({
    required LlmClient llm,
    required BuddyActionHandler onAction,
    bool Function()? canUseModel,
    A2uiValidator validator = const A2uiValidator(),
  }) : _llm = llm,
       _canUseModel = canUseModel ?? (() => true),
       _validator = validator {
    controller = SurfaceController(catalogs: [WonderlyCatalog.build(onAction)]);
    transport = A2uiTransportAdapter();
    _subscription = transport.incomingMessages.listen(controller.handleMessage);
  }

  final LlmClient _llm;
  final A2uiValidator _validator;
  final bool Function() _canUseModel;
  late final SurfaceController controller;
  late final A2uiTransportAdapter transport;
  StreamSubscription<Object?>? _subscription;

  /// True when the last surface used the model's words.
  bool usedModel = false;

  /// Draws a surface for [brief] under [surfaceId].
  Future<void> show(BuddyBrief brief, {required String surfaceId}) async {
    var spec = await _askModel(brief);
    usedModel = spec != null;
    spec ??= _fallback(brief);
    _emit(spec, brief, surfaceId);
  }

  Future<BuddyCardSpec?> _askModel(BuddyBrief brief) async {
    if (!_llm.isReady || !_canUseModel()) return null;
    try {
      final reply = await _llm
          .complete(
            system: _system(brief),
            user: jsonEncode(_facts(brief)),
            maxOutputTokens: 380,
            temperature: 0.6,
          )
          .timeout(const Duration(seconds: 90));
      final text = reply.valueOrNull;
      if (text == null) return null;
      return _validator.parse(text, allowedSetIds: brief.allowedSetIds);
    } on TimeoutException {
      AppLogger.warning(
        'Smart Buddy took too long; using the built-in message.',
      );
      return null;
    } finally {
      await _llm.release();
    }
  }

  Map<String, Object?> _facts(BuddyBrief b) => {
    'childName': b.name,
    'grade': b.grade,
    'stars': b.stars,
    'dayStreak': b.streak,
    'minutesPlayedThisWeek': b.minutesThisWeek,
    'suggestedQuiz': {'setId': b.suggestedSetId, 'title': b.suggestedSetTitle},
    if (b.strongSubjects.isNotEmpty) 'strongSubjects': b.strongSubjects,
    if (b.practiceSubjects.isNotEmpty) 'needsPractice': b.practiceSubjects,
  };

  String _system(BuddyBrief b) {
    final audience = b.kind == BuddyKind.tip
        ? 'a child aged 6 to 11. Be warm, short and playful.'
        : 'the parent of a child aged 6 to 11. Summarise the week kindly and '
              'suggest one next step. Be calm and clear.';
    return 'You are Smart Buddy, a friendly guide in a learning app. You write '
        'one small card for $audience Use only facts you are given; never '
        'invent numbers. Reply with exactly two JSON objects, nothing else.\n'
        'First: {"version":"v0.9","createSurface":{"surfaceId":"buddy","catalogId":"${WonderlyCatalog.catalogId}"}}\n'
        'Second: {"version":"v0.9","updateComponents":{"surfaceId":"buddy","components":['
        '{"id":"root","component":"BuddyCard","accent":"sage","title":"<max 6 words>",'
        '"body":"<max 2 short sentences>","child":"go"},'
        '{"id":"go","component":"ActionButton","label":"<max 4 words>",'
        '"action":{"event":{"name":"startQuiz","context":{"setId":"${b.suggestedSetId}"}}}}]}}\n'
        'accent is one of sun, sage, sky, butter, cream. setId must be one of: '
        '${b.allowedSetIds.join(', ')}.';
  }

  /// Built-in wording used whenever the model cannot answer.
  BuddyCardSpec _fallback(BuddyBrief b) {
    if (b.kind == BuddyKind.report) {
      final practice = b.practiceSubjects.isEmpty
          ? 'Keep exploring every subject.'
          : 'Next, try ${b.practiceSubjects.first} together.';
      return BuddyCardSpec(
        title: "${b.name}'s week",
        body:
            '${b.name} played ${b.minutesThisWeek} minutes and has ${b.stars} stars. $practice',
        accent: 'sage',
        actionLabel: 'Play ${b.suggestedSetTitle}',
        actionSetId: b.suggestedSetId,
      );
    }
    final streak = b.streak > 1 ? 'You are on a ${b.streak} day streak. ' : '';
    return BuddyCardSpec(
      title: 'Hi ${b.name}!',
      body: '${streak}Ready for a quick round of ${b.suggestedSetTitle}?',
      accent: 'sage',
      actionLabel: 'Play ${b.suggestedSetTitle}',
      actionSetId: b.suggestedSetId,
    );
  }

  /// Sends the A2UI messages for [spec] through the transport.
  void _emit(BuddyCardSpec spec, BuddyBrief brief, String surfaceId) {
    final components = <Map<String, Object?>>[
      {
        'id': 'card',
        'component': 'BuddyCard',
        'accent': spec.accent,
        'title': spec.title,
        'body': spec.body,
        if (spec.actionSetId != null) 'child': 'go',
      },
      if (spec.actionSetId != null)
        {
          'id': 'go',
          'component': 'ActionButton',
          'label': spec.actionLabel ?? 'Play',
          'action': {
            'event': {
              'name': 'startQuiz',
              'context': {'setId': spec.actionSetId},
            },
          },
        },
    ];
    if (brief.kind == BuddyKind.report) {
      components
        ..add({
          'id': 'stats',
          'component': 'Row',
          'justify': 'spaceEvenly',
          'children': ['t1', 't2', 't3'],
        })
        ..add(_tile('t1', '${brief.minutesThisWeek} min', 'This week'))
        ..add(_tile('t2', '${brief.stars}', 'Stars'))
        ..add(_tile('t3', '${brief.streak}', 'Day streak'));
    }
    final root = brief.kind == BuddyKind.report
        ? {
            'id': 'root',
            'component': 'Column',
            'children': ['card', 'stats'],
          }
        : {
            'id': 'root',
            'component': 'Column',
            'children': ['card'],
          };
    transport
      ..addChunk(
        jsonEncode({
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': surfaceId,
            'catalogId': WonderlyCatalog.catalogId,
          },
        }),
      )
      ..addChunk(
        jsonEncode({
          'version': 'v0.9',
          'updateComponents': {
            'surfaceId': surfaceId,
            'components': [root, ...components],
          },
        }),
      );
  }

  Map<String, Object?> _tile(String id, String value, String label) => {
    'id': id,
    'component': 'StatTile',
    'value': value,
    'label': label,
  };

  void dispose() {
    unawaited(_subscription?.cancel());
    controller.dispose();
    transport.dispose();
  }
}
