import 'package:wonderly/core/storage/json_value_repository.dart';
import 'package:wonderly/features/ai/domain/entities/generated_bank.dart';
import 'package:wonderly/features/ai/domain/repositories/generated_bank_repository.dart';

class GeneratedBankRepositoryImpl extends JsonValueRepository<GeneratedBank>
    implements GeneratedBankRepository {
  GeneratedBankRepositoryImpl(super.store)
    : super(storageKey: 'wonderly.generated.v1');

  @override
  GeneratedBank get defaultValue => const GeneratedBank();

  @override
  GeneratedBank decode(Map<String, Object?> json) =>
      GeneratedBank.fromJson(json);

  @override
  Map<String, Object?> encode(GeneratedBank value) => value.toJson();
}
