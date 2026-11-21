import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';

/// Source of quiz content.
///
/// Today this is the bundled seed bank. A generator-backed source (for
/// example an on-device model that fills a validated local bank) can be added
/// behind the same interface.
abstract interface class CatalogRepository {
  Future<Result<Catalog>> load();
}
