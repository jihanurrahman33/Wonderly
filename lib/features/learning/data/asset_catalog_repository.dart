import 'dart:convert';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart' show rootBundle;
import 'package:wonderly/core/error/failure.dart';
import 'package:wonderly/core/error/result.dart';
import 'package:wonderly/core/utils/app_logger.dart';
import 'package:wonderly/features/learning/data/catalog_parser.dart';
import 'package:wonderly/features/learning/domain/entities/quiz_set.dart';
import 'package:wonderly/features/learning/domain/repositories/catalog_repository.dart';

/// Loads the bundled seed question bank. Works with zero network and no AI.
class AssetCatalogRepository implements CatalogRepository {
  AssetCatalogRepository({
    Future<String> Function()? loadJson,
    CatalogParser parser = const CatalogParser(),
  }) : _loadJson = loadJson ?? _defaultLoader,
       _parser = parser;

  static const assetPath = 'assets/data/questions.json';

  final Future<String> Function() _loadJson;
  final CatalogParser _parser;
  Catalog? _cached;

  static Future<String> _defaultLoader() => rootBundle.loadString(assetPath);

  @override
  Future<Result<Catalog>> load() async {
    final cached = _cached;
    if (cached != null) return Result.success(cached);
    try {
      final decoded = jsonDecode(await _loadJson());
      if (decoded is! Map<String, Object?>) {
        return const Result.failure(
          DataFailure('Question bank is not an object.'),
        );
      }
      final catalog = _parser.parse(decoded);
      if (catalog.sets.every((s) => s.isEmpty)) {
        return const Result.failure(DataFailure('Question bank is empty.'));
      }
      return Result.success(_cached = catalog);
    } on FormatException catch (e, s) {
      AppLogger.error('Question bank is malformed.', error: e, stackTrace: s);
      return const Result.failure(DataFailure('Question bank is malformed.'));
    } on FlutterError catch (e, s) {
      AppLogger.error('Question bank is missing.', error: e, stackTrace: s);
      return const Result.failure(DataFailure('Question bank is missing.'));
    }
  }
}
