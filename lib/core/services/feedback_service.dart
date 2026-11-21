import 'package:flutter/services.dart';

/// Tactile feedback for answers. A no-op elsewhere keeps tests simple.
abstract interface class FeedbackService {
  Future<void> correct();

  Future<void> incorrect();
}

/// Uses device haptics.
class HapticFeedbackService implements FeedbackService {
  const HapticFeedbackService();

  @override
  Future<void> correct() => HapticFeedback.mediumImpact();

  @override
  Future<void> incorrect() => HapticFeedback.lightImpact();
}
