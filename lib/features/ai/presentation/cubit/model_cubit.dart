import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonderly/features/ai/domain/entities/model_profile.dart';
import 'package:wonderly/features/ai/domain/entities/model_status.dart';
import 'package:wonderly/features/ai/domain/services/device_status.dart';
import 'package:wonderly/features/ai/domain/services/model_manager.dart';

/// Result of asking to start a download.
enum DownloadStart { started, needsWifiConfirmation }

class ModelState extends Equatable {
  const ModelState({
    this.status = const ModelNotInstalled(),
    this.profile = ModelProfile.balanced,
  });

  final ModelStatus status;
  final ModelProfile profile;

  bool get isInstalled => status is ModelInstalled;

  ModelState copyWith({ModelStatus? status, ModelProfile? profile}) =>
      ModelState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
      );

  @override
  List<Object?> get props => [status, profile];
}

/// What a grown-up sees and controls about the on-device model.
class ModelCubit extends Cubit<ModelState> {
  ModelCubit(this._manager, this._device) : super(const ModelState()) {
    _subscription = _manager.status.listen(
      (status) => emit(state.copyWith(status: status)),
    );
  }

  final ModelManager _manager;
  final DeviceStatus _device;
  StreamSubscription<ModelStatus>? _subscription;

  /// Reads what is installed for [profile].
  Future<void> init(ModelProfile profile) async {
    emit(state.copyWith(profile: profile));
    await _manager.refresh(profile);
  }

  Future<void> selectProfile(ModelProfile profile) async {
    if (state.status is ModelDownloading) return;
    emit(state.copyWith(profile: profile));
    await _manager.refresh(profile);
  }

  /// Starts the download. Models are over a gigabyte, so mobile data needs an
  /// explicit confirmation from the grown-up.
  Future<DownloadStart> download({bool allowMetered = false}) async {
    if (!allowMetered && !await _device.isOnUnmeteredNetwork()) {
      return DownloadStart.needsWifiConfirmation;
    }
    unawaited(_manager.download(state.profile));
    return DownloadStart.started;
  }

  void cancel() => _manager.cancelDownload();

  Future<void> delete() => _manager.delete(state.profile);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
