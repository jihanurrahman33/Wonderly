import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/presentation/cubit/catalog_cubit.dart';

/// Builds [builder] once quiz content is loaded; shows a loader or a friendly
/// retry message otherwise.
class CatalogGate extends StatelessWidget {
  const CatalogGate({required this.builder, super.key});

  final Widget Function(BuildContext context, Catalog catalog) builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogCubit, CatalogState>(
      builder: (context, state) => switch (state) {
        CatalogLoading() => const Center(child: CircularProgressIndicator()),
        CatalogReady(:final catalog) => builder(context, catalog),
        CatalogError() => MessageView(
          title: 'Oops!',
          message: 'We could not open the quizzes. Please try again.',
          actionLabel: 'Try again',
          onAction: () => context.read<CatalogCubit>().load(),
        ),
      },
    );
  }
}
