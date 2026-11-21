import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/wonder_progress_bar.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';

/// Back button, set title and "3/10" counter.
class QuizHeader extends StatelessWidget {
  const QuizHeader({
    required this.title,
    required this.current,
    required this.total,
    required this.onBack,
    super.key,
  });

  final String title;
  final int current;
  final int total;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            WonderBackButton(onPressed: onBack, label: 'Leave quiz'),
            Flexible(
              child: Text(
                title,
                style: AppText.heading(22),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Semantics(
              label: 'Question $current of $total',
              excludeSemantics: true,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  '$current/$total',
                  style: AppText.body(17, weight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        WonderProgressBar(
          value: total == 0 ? 0 : current / total,
          height: 10,
          track: const Color(0x2E171910),
          fill: AppColors.ink,
          semanticLabel: 'Quiz progress',
        ),
      ],
    );
  }
}

/// White rounded prompt bubble.
class PromptCard extends StatelessWidget {
  const PromptCard({
    required this.text,
    this.height = 180,
    this.fontSize = 30,
    this.radius = 60,
    super.key,
  });

  final String text;
  final double height;
  final double fontSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppText.heading(fontSize, height: 1.2),
        ),
      ),
    );
  }
}

/// How an answer option looks after the answer is checked.
enum OptionMark { none, selected, correct, wrong, dimmed }

/// Border and badge colours for an [OptionMark].
({Color border, Color? badge, IconData? icon, double opacity}) markStyle(
  OptionMark mark,
) {
  return switch (mark) {
    OptionMark.none => (
      border: Colors.transparent,
      badge: null,
      icon: null,
      opacity: 1,
    ),
    OptionMark.selected => (
      border: AppColors.ink,
      badge: AppColors.ink,
      icon: Icons.check_rounded,
      opacity: 1,
    ),
    OptionMark.correct => (
      border: AppColors.correct,
      badge: AppColors.correct,
      icon: Icons.check_rounded,
      opacity: 1,
    ),
    OptionMark.wrong => (
      border: AppColors.incorrect,
      badge: AppColors.incorrect,
      icon: Icons.close_rounded,
      opacity: 1,
    ),
    OptionMark.dimmed => (
      border: Colors.transparent,
      badge: null,
      icon: null,
      opacity: 0.5,
    ),
  };
}

/// Small round check or cross shown on a marked option.
class MarkBadge extends StatelessWidget {
  const MarkBadge({required this.mark, super.key});

  final OptionMark mark;

  @override
  Widget build(BuildContext context) {
    final style = markStyle(mark);
    if (style.badge == null) return const SizedBox.shrink();
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: style.badge, shape: BoxShape.circle),
      child: Icon(style.icon, color: AppColors.white, size: 18),
    );
  }
}

/// Read aloud and Hint chips shown under the question.
class QuizToolRow extends StatelessWidget {
  const QuizToolRow({required this.onHint, this.onReadAloud, super.key});

  final VoidCallback onHint;

  /// `null` hides the button (read aloud turned off in settings).
  final VoidCallback? onReadAloud;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onReadAloud != null) ...[
          _ToolChip(
            icon: Icons.volume_up_rounded,
            label: 'Read aloud',
            onTap: onReadAloud!,
          ),
          const SizedBox(width: 10),
        ],
        _ToolChip(
          icon: Icons.lightbulb_outline_rounded,
          label: 'Hint',
          onTap: onHint,
        ),
      ],
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: const Color(0xB3FFFFFF),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 46,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 8),
                  Text(label, style: AppText.label(15, color: AppColors.ink)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Speech-bubble style hint text.
class HintBubble extends StatelessWidget {
  const HintBubble({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xB3FFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded, color: AppColors.sunDeep),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.body(15))),
        ],
      ),
    );
  }
}
