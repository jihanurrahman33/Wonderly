import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/art_view.dart';
import 'package:wonderly/core/widgets/wonder_progress_bar.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/entities/subject.dart';
import 'package:wonderly/features/learning/domain/services/learning_stats.dart';
import 'package:wonderly/features/learning/presentation/subject_style.dart';
import 'package:wonderly/features/learning/presentation/widgets/catalog_gate.dart';
import 'package:wonderly/features/progress/presentation/cubit/progress_cubit.dart';

/// "What shall we learn?" subject picker.
class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CatalogGate(
      builder: (context, catalog) {
        final progress = context.watch<ProgressCubit>().state.progress;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
          children: [
            Text('What shall we learn?', style: AppText.heading(28)),
            const SizedBox(height: 8),
            Text(
              'Pick a subject to start playing.',
              style: AppText.subtitle(17),
            ),
            const SizedBox(height: 14),
            GridView(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                // Grow with the text size so large text never overflows.
                mainAxisExtent: 176 * _textFactor(context),
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final subject in Subject.values)
                  _SubjectTile(
                    title: subject.label,
                    color: subject.color,
                    art: ArtView(subject.artKey, size: 60),
                    done: LearningStats.doneIn(subject, catalog, progress),
                    total: catalog.questionCountFor(subject),
                    onTap: () => _open(context, catalog, subject),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  double _textFactor(BuildContext context) {
    final factor = MediaQuery.textScalerOf(context).scale(16) / 16;
    return factor < 1 ? 1 : factor;
  }

  void _open(BuildContext context, Catalog catalog, Subject subject) {
    final sets = catalog.setsFor(subject);
    if (sets.isEmpty) return _comingSoon(context);
    context.push(
      sets.length == 1
          ? Routes.quiz(sets.first.id)
          : Routes.subject(subject.name),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Coming soon!')));
  }
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({
    required this.title,
    required this.color,
    required this.art,
    required this.onTap,
    this.done = 0,
    this.total = 0,
  });

  final String title;
  final Color color;
  final Widget art;
  final VoidCallback onTap;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final subtitle = '$done/$total done';
    return TintedCard(
      color: color,
      semanticLabel: '$title, $subtitle',
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 64,
            child: Align(alignment: Alignment.centerLeft, child: art),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.heading(19)),
              Text(subtitle, style: AppText.subtitle(14)),
              const SizedBox(height: 6),
              WonderProgressBar(
                value: total == 0 ? 0 : done / total,
                track: const Color(0x1F171910),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
