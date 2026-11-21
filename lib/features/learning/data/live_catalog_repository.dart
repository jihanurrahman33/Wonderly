import 'dart:async';

import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/features/ai/domain/entities/generated_bank.dart';
import 'package:wonderly/features/ai/domain/repositories/generated_bank_repository.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/repositories/catalog_repository.dart';
import 'package:wonderly/features/learning/domain/services/catalog_assembler.dart';
import 'package:wonderly/features/profile/domain/repositories/profile_repository.dart';
import 'package:wonderly/features/progress/domain/repositories/progress_repository.dart';

/// Combines the generated bank, the learner's grade and progress into the
/// catalog the app plays. Rebuilt on every [load], so it is always current.
class LiveCatalogRepository implements CatalogRepository {
  LiveCatalogRepository({
    required CatalogRepository seed,
    required GeneratedBankRepository bank,
    required ProfileRepository profile,
    required ProgressRepository progress,
    required Clock clock,
    CatalogAssembler assembler = const CatalogAssembler(),
  }) : _seed = seed,
       _bank = bank,
       _profile = profile,
       _progress = progress,
       _clock = clock,
       _assembler = assembler;

  final CatalogRepository _seed;
  final GeneratedBankRepository _bank;
  final ProfileRepository _profile;
  final ProgressRepository _progress;
  final Clock _clock;
  final CatalogAssembler _assembler;

  /// Emits whenever something the catalog depends on changes.
  Stream<void> get changes {
    // Closed by the consumer cancelling the stream (see onCancel below).
    // ignore: close_sinks
    final controller = StreamController<void>.broadcast();
    final subs = <StreamSubscription<Object?>>[
      _bank.watch().listen((_) => controller.add(null)),
      _progress.watch().listen((_) => controller.add(null)),
    ];
    controller.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };
    return controller.stream;
  }

  @override
  Future<Result<Catalog>> load() async {
    final seed = await _seed.load();
    final seedCatalog = seed.valueOrNull;
    if (seedCatalog == null) {
      return Result.failure(
        seed.failureOrNull ?? const DataFailure('No content.'),
      );
    }
    final bank = (await _bank.load()).valueOrNull ?? const GeneratedBank();
    final progress = (await _progress.load()).valueOrNull;
    final roster = (await _profile.load()).valueOrNull;
    return Result.success(
      _assembler.assemble(
        seed: seedCatalog,
        bank: bank,
        grade: roster?.active?.grade ?? 3,
        rounds: progress?.setRounds ?? const {},
        now: _clock.now(),
      ),
    );
  }
}
