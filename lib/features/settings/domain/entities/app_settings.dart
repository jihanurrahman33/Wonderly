import 'package:equatable/equatable.dart';
import 'package:wonderly/core/constants/app_constants.dart';

/// Reading size chosen in Settings.
enum TextSize {
  small(0.9),
  medium(1),
  large(1.15);

  const TextSize(this.scale);

  final double scale;

  static TextSize fromName(String? name) => TextSize.values.firstWhere(
    (t) => t.name == name,
    orElse: () => TextSize.medium,
  );
}

/// User and parent preferences. Immutable.
class AppSettings extends Equatable {
  const AppSettings({
    this.soundEffects = true,
    this.music = false,
    this.readAloud = true,
    this.textSize = TextSize.medium,
    this.bedtimeMode = false,
    this.dailyLimitMinutes = AppConstants.defaultDailyLimitMinutes,
    this.weeklyReport = true,
  });

  factory AppSettings.fromJson(Map<String, Object?> json) {
    final limit =
        json['dailyLimitMinutes'] as int? ??
        AppConstants.defaultDailyLimitMinutes;
    return AppSettings(
      soundEffects: json['soundEffects'] as bool? ?? true,
      music: json['music'] as bool? ?? false,
      readAloud: json['readAloud'] as bool? ?? true,
      textSize: TextSize.fromName(json['textSize'] as String?),
      bedtimeMode: json['bedtimeMode'] as bool? ?? false,
      dailyLimitMinutes: limit.clamp(
        AppConstants.minDailyLimitMinutes,
        AppConstants.maxDailyLimitMinutes,
      ),
      weeklyReport: json['weeklyReport'] as bool? ?? true,
    );
  }

  final bool soundEffects;
  final bool music;
  final bool readAloud;
  final TextSize textSize;
  final bool bedtimeMode;
  final int dailyLimitMinutes;

  /// Preference only: there is no backend, so reports are shown in-app.
  final bool weeklyReport;

  AppSettings copyWith({
    bool? soundEffects,
    bool? music,
    bool? readAloud,
    TextSize? textSize,
    bool? bedtimeMode,
    int? dailyLimitMinutes,
    bool? weeklyReport,
  }) {
    return AppSettings(
      soundEffects: soundEffects ?? this.soundEffects,
      music: music ?? this.music,
      readAloud: readAloud ?? this.readAloud,
      textSize: textSize ?? this.textSize,
      bedtimeMode: bedtimeMode ?? this.bedtimeMode,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      weeklyReport: weeklyReport ?? this.weeklyReport,
    );
  }

  Map<String, Object?> toJson() => {
    'soundEffects': soundEffects,
    'music': music,
    'readAloud': readAloud,
    'textSize': textSize.name,
    'bedtimeMode': bedtimeMode,
    'dailyLimitMinutes': dailyLimitMinutes,
    'weeklyReport': weeklyReport,
  };

  @override
  List<Object?> get props => [
    soundEffects,
    music,
    readAloud,
    textSize,
    bedtimeMode,
    dailyLimitMinutes,
    weeklyReport,
  ];
}
