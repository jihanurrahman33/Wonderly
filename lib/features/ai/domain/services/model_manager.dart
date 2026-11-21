import 'package:wonderly/features/ai/domain/entities/model_profile.dart';
import 'package:wonderly/features/ai/domain/entities/model_status.dart';

/// Installs, tracks and removes the on-device model.
abstract interface class ModelManager {
  ModelStatus get current;

  Stream<ModelStatus> get status;

  /// Re-reads what is installed (for example after the app starts).
  Future<void> refresh(ModelProfile profile);

  /// Downloads [profile]. Progress is reported on [status].
  Future<void> download(ModelProfile profile);

  void cancelDownload();

  Future<void> delete(ModelProfile profile);
}
