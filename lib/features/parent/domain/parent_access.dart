import 'package:wonderly/core/utils/clock.dart';

/// In-memory grown-up session. Never persisted, so restarting the app always
/// asks for the parent gate again.
class ParentAccess {
  ParentAccess(this._clock);

  static const sessionLength = Duration(minutes: 5);

  final Clock _clock;
  DateTime? _expiresAt;

  bool get isActive {
    final expires = _expiresAt;
    return expires != null && _clock.now().isBefore(expires);
  }

  void grant() => _expiresAt = _clock.now().add(sessionLength);

  void revoke() => _expiresAt = null;
}
