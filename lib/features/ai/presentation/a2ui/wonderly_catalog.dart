import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';

/// Called when a child or grown-up taps an A2UI action button.
typedef BuddyActionHandler = void Function(
  String name,
  Map<String, Object?> context,
);

/// The A2UI catalog Smart Buddy may draw with.
///
/// It is deliberately small and safe: text, layout and a few Wonderly widgets.
/// There is no image, video, audio, text input or link component, so a model
/// cannot show remote content or collect anything from a child, whatever it
/// writes.
abstract final class WonderlyCatalog {
  static const catalogId = 'wonderly.buddy.v1';

  /// Components the model is told about, in the prompt.
  static const componentNames = [
    'BuddyCard',
    'ActionButton',
    'StatTile',
    'Column',
    'Row',
    'Text',
  ];

  static Catalog build(BuddyActionHandler onAction) {
    return Catalog(
      [
        BasicCatalogItems.column,
        BasicCatalogItems.row,
        BasicCatalogItems.text,
        BasicCatalogItems.divider,
        _buddyCard,
        _statTile,
        _actionButton(onAction),
      ],
      catalogId: catalogId,
      systemPromptFragments: const [],
    );
  }

  static Color _accent(String? name) => switch (name) {
    'sage' => AppColors.sage,
    'sky' => AppColors.sky,
    'butter' => AppColors.butter,
    'cream' => AppColors.cream,
    _ => AppColors.sun,
  };

  static final CatalogItem _buddyCard = CatalogItem(
    name: 'BuddyCard',
    dataSchema: S.object(
      description: 'A friendly rounded card with a title, a message and an optional action.',
      properties: {
        'title': A2uiSchemas.stringReference(description: 'Short title.'),
        'body': A2uiSchemas.stringReference(
          description: 'One or two kind sentences.',
        ),
        'accent': S.string(
          description: 'Background colour.',
          enumValues: ['sun', 'sage', 'sky', 'butter', 'cream'],
        ),
        'child': A2uiSchemas.componentReference(
          description: 'Optional component shown under the message, such as an ActionButton.',
        ),
      },
      required: ['title', 'body'],
    ),
    exampleData: [
      () => '''
[
  {"id": "root", "component": "BuddyCard", "accent": "sage",
   "title": "Hi Alex!", "body": "You are on a 3 day streak. Keep it going!",
   "child": "go"},
  {"id": "go", "component": "ActionButton", "label": "Play Zoology Quiz",
   "action": {"event": {"name": "startQuiz", "context": {"setId": "zoology_quiz"}}}}
]''',
    ],
    widgetBuilder: (ctx) {
      final data = ctx.data as JsonMap;
      final childId = data['child'] as String?;
      return BoundString(
        dataContext: ctx.dataContext,
        value: data['title'],
        builder: (context, title) => BoundString(
          dataContext: ctx.dataContext,
          value: data['body'],
          builder: (context, body) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _accent(data['accent'] as String?),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title ?? '', style: AppText.heading(22)),
                const SizedBox(height: 6),
                Text(
                  body ?? '',
                  style: AppText.body(16, weight: FontWeight.w700),
                ),
                if (childId != null) ...[
                  const SizedBox(height: 14),
                  ctx.buildChild(childId),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );

  static final CatalogItem _statTile = CatalogItem(
    name: 'StatTile',
    dataSchema: S.object(
      description: 'A small tile with a big value and a caption, for example "3 days" and "Streak".',
      properties: {
        'value': A2uiSchemas.stringReference(description: 'The big value.'),
        'label': A2uiSchemas.stringReference(
          description: 'Caption under the value.',
        ),
      },
      required: ['value', 'label'],
    ),
    widgetBuilder: (ctx) {
      final data = ctx.data as JsonMap;
      return BoundString(
        dataContext: ctx.dataContext,
        value: data['value'],
        builder: (context, value) => BoundString(
          dataContext: ctx.dataContext,
          value: data['label'],
          builder: (context, label) => Semantics(
            label: '${label ?? ''}: ${value ?? ''}',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value ?? '', style: AppText.heading(24)),
                  Text(
                    label ?? '',
                    style: AppText.subtitle(14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  static CatalogItem _actionButton(BuddyActionHandler onAction) {
    return CatalogItem(
      name: 'ActionButton',
      dataSchema: S.object(
        description: 'A pill button that asks the app to do something, such as start a quiz.',
        properties: {
          'label': A2uiSchemas.stringReference(description: 'Button text.'),
          'action': A2uiSchemas.action(),
        },
        required: ['label', 'action'],
      ),
      widgetBuilder: (ctx) {
        final data = ctx.data as JsonMap;
        return BoundString(
          dataContext: ctx.dataContext,
          value: data['label'],
          builder: (context, label) => Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: Material(
              color: AppColors.ink,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => _dispatch(ctx, data, onAction),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        label ?? '',
                        style: AppText.heading(17, color: AppColors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _dispatch(
    CatalogItemContext ctx,
    JsonMap data,
    BuddyActionHandler onAction,
  ) async {
    final action = data['action'];
    if (action is! Map<String, Object?>) return;
    final event = action['event'];
    if (event is! Map<String, Object?>) return;
    final name = event['name'];
    if (name is! String) return;
    final contextDefinition = event['context'];
    final resolved = await resolveContext(
      ctx.dataContext,
      contextDefinition is Map<String, Object?> ? contextDefinition : null,
    );
    onAction(name, resolved);
  }
}
