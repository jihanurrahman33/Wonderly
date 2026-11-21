/// Network and power facts that decide whether heavy work should run.
abstract interface class DeviceStatus {
  /// True on Wi-Fi or Ethernet (not metered mobile data).
  Future<bool> isOnUnmeteredNetwork();

  /// True when the battery is low and not charging.
  Future<bool> isBatteryLow();
}
