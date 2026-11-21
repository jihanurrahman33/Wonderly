import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/core/services/sound_service.dart';

/// Plays [effect] once when it first appears. Draws nothing.
class PlaySoundOnce extends StatefulWidget {
  const PlaySoundOnce(this.effect, {super.key});

  final SoundEffect effect;

  @override
  State<PlaySoundOnce> createState() => _PlaySoundOnceState();
}

class _PlaySoundOnceState extends State<PlaySoundOnce> {
  @override
  void initState() {
    super.initState();
    unawaited(sl<SoundService>().play(widget.effect));
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
