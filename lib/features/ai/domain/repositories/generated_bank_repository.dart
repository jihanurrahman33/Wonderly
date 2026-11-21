import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/features/ai/domain/entities/generated_bank.dart';

/// Persistence for model-written questions.
abstract interface class GeneratedBankRepository {
  Stream<GeneratedBank> watch();

  Future<Result<GeneratedBank>> load();

  Future<Result<GeneratedBank>> update(
    GeneratedBank Function(GeneratedBank current) transform,
  );
}
