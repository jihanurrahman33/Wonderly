import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:wonderly/core/utils/app_logger.dart';

/// What the phone can run, read once from the operating system.
class DeviceCapability {
  const DeviceCapability({required this.supported, this.reason, this.ramMb});

  final bool supported;
  final String? reason;

  /// Physical memory in megabytes, when the platform reports it.
  final int? ramMb;
}

/// Checks the hard requirements of the on-device engine: Android 11 or newer
/// on a 64-bit ARM chip, or iOS 15 or newer.
class DeviceCapabilityChecker {
  const DeviceCapabilityChecker([this._plugin]);

  final DeviceInfoPlugin? _plugin;

  Future<DeviceCapability> check() async {
    final plugin = _plugin ?? DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        if (info.version.sdkInt < 30) {
          return const DeviceCapability(
            supported: false,
            reason: 'Smart Buddy needs Android 11 or newer.',
          );
        }
        if (!info.supportedAbis.contains('arm64-v8a')) {
          return const DeviceCapability(
            supported: false,
            reason: 'Smart Buddy needs a 64-bit ARM phone.',
          );
        }
        return DeviceCapability(supported: true, ramMb: info.physicalRamSize);
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        final major = int.tryParse(info.systemVersion.split('.').first) ?? 0;
        if (major < 15) {
          return const DeviceCapability(
            supported: false,
            reason: 'Smart Buddy needs iOS 15 or newer.',
          );
        }
        return DeviceCapability(supported: true, ramMb: info.physicalRamSize);
      }
    } on Exception catch (e) {
      AppLogger.warning('Could not read device information.', e);
      return const DeviceCapability(supported: true);
    }
    return const DeviceCapability(
      supported: false,
      reason: 'Smart Buddy runs on Android and iOS phones.',
    );
  }
}
