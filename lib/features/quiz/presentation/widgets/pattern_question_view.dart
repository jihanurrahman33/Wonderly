import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/art_view.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/quiz/presentation/widgets/quiz_parts.dart';

String _capitalised(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Renders a [PatternQuestion]: a shape sequence and tiles to finish it.
class PatternQuestionView extends StatelessWidget {
  const PatternQuestionView({
    required this.question,
    required this.selected,
    required this.revealed,
    required this.onSelect,
    super.key,
  });

  final PatternQuestion question;
  final int? selected;
  final bool revealed;
  final ValueChanged<int> onSelect;

  OptionMark _mark(int i) {
    if (!revealed) return i == selected ? OptionMark.selected : OptionMark.none;
    if (i == question.answerIndex) return OptionMark.correct;
    if (i == selected) return OptionMark.wrong;
    return OptionMark.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    final sequenceText = question.sequence.map(_capitalised).join(', ');
    return Column(
      children: [
        PromptCard(
          text: question.prompt,
          height: 110,
          fontSize: 30,
          radius: 48,
        ),
        const SizedBox(height: 14),
        Semantics(
          label: 'Pattern: $sequenceText, then what?',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final shape in question.sequence) ArtView(shape, size: 44),
                Text('?', style: AppText.heading(34)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 0; i < question.options.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _PatternOption(
                  shape: question.options[i],
                  mark: _mark(i),
                  onTap: revealed ? null : () => onSelect(i),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PatternOption extends StatelessWidget {
  const _PatternOption({
    required this.shape,
    required this.mark,
    required this.onTap,
  });

  final String shape;
  final OptionMark mark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = markStyle(mark);
    return Opacity(
      opacity: style.opacity,
      child: Semantics(
        button: true,
        selected: mark == OptionMark.selected || mark == OptionMark.correct,
        label: _capitalised(shape),
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
            child: AspectRatio(
              aspectRatio: 0.95,
              child: Stack(
                children: [
                  Center(child: ArtView(shape, size: 64)),
                  Positioned(top: 6, right: 6, child: MarkBadge(mark: mark)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
