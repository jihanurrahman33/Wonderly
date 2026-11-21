import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/repositories/catalog_repository.dart';

sealed class CatalogState extends Equatable {
  const CatalogState();

  @override
  List<Object?> get props => const [];
}

final class CatalogLoading extends CatalogState {
  const CatalogLoading();
}

final class CatalogReady extends CatalogState {
  const CatalogReady(this.catalog);

  final Catalog catalog;

  @override
  List<Object?> get props => [catalog];
}

final class CatalogError extends CatalogState {
  const CatalogError();
}

/// Loads the quiz content and keeps it current as the model writes new
/// questions or the learner's progress moves on.
class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._repository, {Stream<void>? changes})
    : super(const CatalogLoading()) {
    _subscription = changes
        ?.transform(_debounce(const Duration(milliseconds: 400)))
        .listen((_) => unawaited(_refreshQuietly()));
  }

  final CatalogRepository _repository;
  StreamSubscription<void>? _subscription;

  Future<void> load() async {
    emit(const CatalogLoading());
    await _refresh();
  }

  /// Rebuilds the catalog without showing a loading state.
  Future<void> _refreshQuietly() async {
    if (isClosed || state is! CatalogReady) return;
    await _refresh();
  }

  Future<void> _refresh() async {
    final result = await _repository.load();
    if (isClosed) return;
    final next = result.fold<CatalogState>(
      onSuccess: CatalogReady.new,
      onFailure: (_) => const CatalogError(),
    );
    if (next != state) emit(next);
  }

  static StreamTransformer<T, T> _debounce<T>(Duration duration) {
    return StreamTransformer<T, T>.fromBind((stream) {
      Timer? timer;
      StreamSubscription<T>? source;
      late StreamController<T> controller;
      controller = StreamController<T>(
        onListen: () {
          source = stream.listen(
            (event) {
              timer?.cancel();
              timer = Timer(duration, () => controller.add(event));
            },
            onError: controller.addError,
            onDone: () {
              timer?.cancel();
              unawaited(controller.close());
            },
          );
        },
        onCancel: () async {
          timer?.cancel();
          await source?.cancel();
        },
      );
      return controller.stream;
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
