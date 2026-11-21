import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/art_view.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/quiz/presentation/widgets/quiz_parts.dart';

OptionMark _markFor({
  required int index,
  required int answerIndex,
  required int? selected,
  required bool revealed,
}) {
  if (!revealed) {
    return index == selected ? OptionMark.selected : OptionMark.none;
  }
  if (index == answerIndex) return OptionMark.correct;
  if (index == selected) return OptionMark.wrong;
  return OptionMark.dimmed;
}

/// Renders a [ChoiceQuestion] as a picture grid or a list of text buttons.
class ChoiceQuestionView extends StatelessWidget {
  const ChoiceQuestionView({
    required this.question,
    required this.selected,
    required this.revealed,
    required this.onSelect,
    super.key,
  });

  final ChoiceQuestion question;
  final int? selected;
  final bool revealed;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return switch (question.layout) {
      ChoiceLayout.pictureGrid => _PictureGrid(view: this),
      ChoiceLayout.textList => _TextList(view: this),
    };
  }

  OptionMark mark(int i) => _markFor(
    index: i,
    answerIndex: question.answerIndex,
    selected: selected,
    revealed: revealed,
  );
}

class _PictureGrid extends StatelessWidget {
  const _PictureGrid({required this.view});

  final ChoiceQuestionView view;

  @override
  Widget build(BuildContext context) {
    final q = view.question;
    final compact = view.revealed;
    return Column(
      children: [
        PromptCard(
          text: q.prompt,
          height: compact ? 96 : 180,
          fontSize: compact ? 24 : 30,
          radius: compact ? 40 : 60,
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: compact ? 1.5 : 1.12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < q.options.length; i++)
              _PictureOption(
                option: q.options[i],
                mark: view.mark(i),
                artSize: compact ? 60 : 92,
                onTap: view.revealed ? null : () => view.onSelect(i),
              ),
          ],
        ),
      ],
    );
  }
}

class _PictureOption extends StatelessWidget {
  const _PictureOption({
    required this.option,
    required this.mark,
    required this.artSize,
    required this.onTap,
  });

  final AnswerOption option;
  final OptionMark mark;
  final double artSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = markStyle(mark);
    return Opacity(
      opacity: style.opacity,
      child: Semantics(
        button: true,
        selected: mark == OptionMark.selected || mark == OptionMark.correct,
        label: option.label,
        excludeSemantics: true,
        child: Material(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(color: style.border, width: 5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onTap,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (option.art != null)
                        ArtView(option.art!, size: artSize),
                      const SizedBox(height: 6),
                      Text(option.label, style: AppText.heading(20)),
                    ],
                  ),
                ),
                Positioned(top: 8, right: 8, child: MarkBadge(mark: mark)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextList extends StatelessWidget {
  const _TextList({required this.view});

  final ChoiceQuestionView view;

  @override
  Widget build(BuildContext context) {
    final q = view.question;
    final scene = q.scene;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scene != null && scene.isNotEmpty) ...[
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.sky,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final key in scene) ArtView(key, size: 64)],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Semantics(
          header: true,
          child: Text(q.prompt, style: AppText.heading(24, height: 1.2)),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < q.options.length; i++) ...[
          _TextOption(
            label: q.options[i].label,
            mark: view.mark(i),
            onTap: view.revealed ? null : () => view.onSelect(i),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TextOption extends StatelessWidget {
  const _TextOption({
    required this.label,
    required this.mark,
    required this.onTap,
  });

  final String label;
  final OptionMark mark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = markStyle(mark);
    final border = mark == OptionMark.none ? Colors.transparent : style.border;
    return Opacity(
      opacity: style.opacity,
      child: Semantics(
        button: true,
        selected: mark == OptionMark.selected || mark == OptionMark.correct,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: border, width: 4),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 62,
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: AppText.heading(19))),
                    MarkBadge(mark: mark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
