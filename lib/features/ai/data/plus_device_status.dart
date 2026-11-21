import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wonderly/core/utils/app_logger.dart';
import 'package:wonderly/features/ai/domain/services/device_status.dart';

/// [DeviceStatus] from `connectivity_plus` and `battery_plus`.
class PlusDeviceStatus implements DeviceStatus {
  PlusDeviceStatus({Connectivity? connectivity, Battery? battery})
    : _connectivity = connectivity ?? Connectivity(),
      _battery = battery ?? Battery();

  static const lowBatteryPercent = 20;

  final Connectivity _connectivity;
  final Battery _battery;

  @override
  Future<bool> isOnUnmeteredNetwork() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet);
    } on Object catch (e) {
      AppLogger.warning('Could not read the network type.', e);
      return false;
    }
  }

  @override
  Future<bool> isBatteryLow() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final charging =
          state == BatteryState.charging || state == BatteryState.full;
      return level < lowBatteryPercent && !charging;
    } on Object catch (e) {
      AppLogger.warning('Could not read the battery.', e);
      return false;
    }
  }
}
