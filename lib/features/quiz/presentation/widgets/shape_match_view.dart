import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/art_view.dart';
import 'package:wonderly/features/learning/domain/entities/question.dart';
import 'package:wonderly/features/quiz/presentation/widgets/quiz_parts.dart';

String _capitalised(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Drag each shape onto its outline. Tapping a piece, then its outline, works
/// too so the game is usable without dragging.
class ShapeMatchView extends StatefulWidget {
  const ShapeMatchView({
    required this.question,
    required this.placed,
    required this.onPlaced,
    super.key,
  });

  final ShapeMatchQuestion question;
  final Set<String> placed;
  final ValueChanged<String> onPlaced;

  @override
  State<ShapeMatchView> createState() => _ShapeMatchViewState();
}

class _ShapeMatchViewState extends State<ShapeMatchView> {
  String? _picked;
  String? _nudge;

  void _tapPiece(String shape) =>
      setState(() => _picked = _picked == shape ? null : shape);

  void _tapSlot(String slot) {
    final picked = _picked;
    if (picked == null || widget.placed.contains(slot)) return;
    if (picked == slot) {
      setState(() => _picked = null);
      widget.onPlaced(slot);
    } else {
      setState(() => _nudge = 'Try another spot for the $picked.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final remaining = q.shapes.reversed
        .where((s) => !widget.placed.contains(s))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PromptCard(text: q.prompt, height: 100, fontSize: 26, radius: 40),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final shape in q.shapes)
                _Slot(
                  shape: shape,
                  filled: widget.placed.contains(shape),
                  onAccept: widget.onPlaced,
                  onTap: () => _tapSlot(shape),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Shapes to place',
          style: AppText.label(15, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 108),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(26),
          ),
          child: remaining.isEmpty
              ? Center(child: Text('All done!', style: AppText.heading(20)))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final shape in remaining)
                      _Piece(
                        shape: shape,
                        picked: shape == _picked,
                        onTap: () => _tapPiece(shape),
                      ),
                  ],
                ),
        ),
        if (_nudge != null) ...[
          const SizedBox(height: 10),
          HintBubble(text: _nudge!),
        ],
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.shape,
    required this.filled,
    required this.onAccept,
    required this.onTap,
  });

  final String shape;
  final bool filled;
  final ValueChanged<String> onAccept;
  final VoidCallback onTap;

  static const _outline = {
    'triangle': 'slot_triangle',
    'square': 'slot_square',
  };

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => !filled && d.data == shape,
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        final outlineKey = _outline[shape];
        return Semantics(
          button: !filled,
          label: filled ? '${_capitalised(shape)} placed' : 'Empty $shape spot',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: hovering ? AppColors.butter : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Opacity(
                    opacity: filled ? 1 : 0.55,
                    child: ArtView(
                      filled ? shape : (outlineKey ?? shape),
                      size: 84,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(_capitalised(shape), style: AppText.heading(16)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Piece extends StatelessWidget {
  const _Piece({
    required this.shape,
    required this.picked,
    required this.onTap,
  });

  final String shape;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final art = ArtView(shape, size: 76);
    return Semantics(
      button: true,
      selected: picked,
      label:
          '${_capitalised(shape)} piece. Drag it, or tap it then tap its spot.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Draggable<String>(
          data: shape,
          feedback: Material(
            color: Colors.transparent,
            child: ArtView(shape, size: 88),
          ),
          childWhenDragging: Opacity(opacity: 0.25, child: art),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: picked ? AppColors.ink : Colors.transparent,
                width: 3,
              ),
            ),
            child: art,
          ),
        ),
      ),
    );
  }
}
