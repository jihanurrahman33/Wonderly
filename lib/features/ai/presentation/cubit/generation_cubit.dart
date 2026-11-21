import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wonderly/core/utils/app_logger.dart';
import 'package:wonderly/features/ai/domain/entities/generated_bank.dart';
import 'package:wonderly/features/ai/domain/repositories/generated_bank_repository.dart';
import 'package:wonderly/features/ai/domain/services/device_status.dart';
import 'package:wonderly/features/ai/domain/usecases/bank_filler.dart';
import 'package:wonderly/features/learning/domain/entities/set_blueprint.dart';

/// Why background generation is paused.
enum PauseReason { quizOpen, appInBackground, userStopped }

class GenerationState extends Equatable {
  const GenerationState({
    this.running = false,
    this.made = 0,
    this.wanted = 0,
    this.setTitle,
    this.bankTotal = 0,
    this.bankMissing = 0,
    this.lowBattery = false,
  });

  final bool running;
  final int made;
  final int wanted;
  final String? setTitle;

  /// Questions the model has written and stored so far.
  final int bankTotal;

  /// Questions still needed to fill every set.
  final int bankMissing;
  final bool lowBattery;

  GenerationState copyWith({
    bool? running,
    int? made,
    int? wanted,
    String? Function()? setTitle,
    int? bankTotal,
    int? bankMissing,
    bool? lowBattery,
  }) {
    return GenerationState(
      running: running ?? this.running,
      made: made ?? this.made,
      wanted: wanted ?? this.wanted,
      setTitle: setTitle != null ? setTitle() : this.setTitle,
      bankTotal: bankTotal ?? this.bankTotal,
      bankMissing: bankMissing ?? this.bankMissing,
      lowBattery: lowBattery ?? this.lowBattery,
    );
  }

  @override
  List<Object?> get props => [
    running,
    made,
    wanted,
    setTitle,
    bankTotal,
    bankMissing,
    lowBattery,
  ];
}

/// Runs the question generator in the background and keeps it polite: it
/// pauses while a quiz is open, when the app is in the background, and when the
/// battery is low.
class GenerationCubit extends Cubit<GenerationState> {
  GenerationCubit({
    required BankFiller filler,
    required GeneratedBankRepository bank,
    required DeviceStatus device,
    required bool Function() isModelReady,
    required bool Function() isEnabled,
    required int Function() currentGrade,
  }) : _filler = filler,
       _bank = bank,
       _device = device,
       _isModelReady = isModelReady,
       _isEnabled = isEnabled,
       _grade = currentGrade,
       super(const GenerationState());

  final BankFiller _filler;
  final GeneratedBankRepository _bank;
  final DeviceStatus _device;
  final bool Function() _isModelReady;
  final bool Function() _isEnabled;
  final int Function() _grade;
  final Set<PauseReason> _pauses = {};
  bool _stopRequested = false;

  /// Refreshes the stored-question counters.
  Future<void> refreshCounts() async {
    final bank = (await _bank.load()).valueOrNull ?? const GeneratedBank();
    if (isClosed) return;
    emit(
      state.copyWith(
        bankTotal: bank.total,
        bankMissing: BankFiller.missing(bank, Curriculum.llmSets),
      ),
    );
  }

  void pause(PauseReason reason) {
    _pauses.add(reason);
  }

  Future<void> resume(PauseReason reason) async {
    _pauses.remove(reason);
    await maybeStart();
  }

  /// Stops the current run; it can be started again later.
  void stop() {
    _stopRequested = true;
    _pauses.add(PauseReason.userStopped);
  }

  /// Starts a run when the model is ready and nothing says to wait.
  Future<void> maybeStart({bool force = false}) async {
    if (force) _pauses.remove(PauseReason.userStopped);
    if (state.running ||
        !_isModelReady() ||
        !_isEnabled() ||
        _pauses.isNotEmpty) {
      return;
    }
    await refreshCounts();
    if (state.bankMissing == 0) return;
    if (await _device.isBatteryLow()) {
      emit(state.copyWith(lowBattery: true));
      return;
    }
    _stopRequested = false;
    emit(
      state.copyWith(
        running: true,
        made: 0,
        wanted: state.bankMissing,
        lowBattery: false,
      ),
    );
    try {
      await _filler.fill(
        grade: _grade(),
        shouldStop: () => _stopRequested || _pauses.isNotEmpty || isClosed,
        onProgress: (p) {
          if (isClosed) return;
          emit(
            state.copyWith(
              made: p.made,
              wanted: p.wanted,
              setTitle: () => p.setTitle,
            ),
          );
        },
      );
    } on Object catch (e, s) {
      AppLogger.error('Question generation crashed.', error: e, stackTrace: s);
    }
    if (isClosed) return;
    emit(state.copyWith(running: false, setTitle: () => null));
    await refreshCounts();
  }
}
