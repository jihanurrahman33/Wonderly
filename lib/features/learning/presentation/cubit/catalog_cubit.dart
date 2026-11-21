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

/// Loads the quiz content once and exposes it to the whole app.
class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit(this._repository) : super(const CatalogLoading());

  final CatalogRepository _repository;

  Future<void> load() async {
    emit(const CatalogLoading());
    final result = await _repository.load();
    emit(
      result.fold(
        onSuccess: CatalogReady.new,
        onFailure: (_) => const CatalogError(),
      ),
    );
  }
}
