import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/utils/clock.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';
import 'package:wonderly/features/parent/domain/parent_access.dart';
import 'package:wonderly/features/parent/presentation/cubit/parent_gate_cubit.dart';

/// Quick maths question that keeps children out of the grown-ups zone.
class ParentGatePage extends StatelessWidget {
  const ParentGatePage({this.next, super.key});

  /// Where to go after the gate (must be a parent-only page).
  final String? next;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ParentGateCubit>(),
      child: _GateView(
        destination: Routes.parentOnly.contains(next) ? next! : Routes.grownUps,
      ),
    );
  }
}

class _GateView extends StatefulWidget {
  const _GateView({required this.destination});

  final String destination;

  @override
  State<_GateView> createState() => _GateViewState();
}

class _GateViewState extends State<_GateView> {
  final Clock _clock = sl<Clock>();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh once a second so the lockout countdown stays accurate.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.me);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ParentGateCubit, ParentGateState>(
      listenWhen: (a, b) => !a.verified && b.verified,
      listener: (context, state) {
        sl<ParentAccess>().grant();
        context.pushReplacement(widget.destination);
      },
      builder: _build,
    );
  }

  Widget _build(BuildContext context, ParentGateState state) {
    final cubit = context.read<ParentGateCubit>();
    final now = _clock.now();
    final locked = state.isLocked(now);
    final secondsLeft = locked
        ? state.lockedUntil!.difference(now).inSeconds + 1
        : 0;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: WonderBackButton(
                  onPressed: _leave,
                  label: 'Back to profile',
                  color: AppColors.cream,
                ),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.lock_rounded, size: 56, color: AppColors.olive),
              const SizedBox(height: 10),
              Text('Grown-ups only', style: AppText.heading(30)),
              const SizedBox(height: 6),
              Text(
                'Solve this to enter the grown-ups zone.',
                style: AppText.subtitle(17),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Semantics(
                liveRegion: true,
                label:
                    'Question: ${state.challenge.left} times '
                    '${state.challenge.right}',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: Text(
                        state.challenge.question,
                        style: AppText.heading(36),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _AnswerBox(digit: _digit(state.input, 0)),
                    const SizedBox(width: 8),
                    _AnswerBox(digit: _digit(state.input, 1)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 24,
                child: Text(
                  locked
                      ? 'Too many tries. Please wait $secondsLeft seconds.'
                      : state.wrongAnswer
                      ? 'Not quite. Here is a new question.'
                      : '',
                  style: AppText.label(15, color: AppColors.incorrect),
                ),
              ),
              const Spacer(),
              _Keypad(
                enabled: !locked,
                onDigit: (d) {
                  HapticFeedback.selectionClick();
                  cubit.enterDigit(d);
                },
                onDelete: cubit.deleteDigit,
                onConfirm: cubit.confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _digit(String input, int i) => i < input.length ? input[i] : '';
}

class _AnswerBox extends StatelessWidget {
  const _AnswerBox({required this.digit});

  final String digit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink, width: 3),
      ),
      child: Text(digit, style: AppText.heading(34)),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.enabled,
    required this.onDigit,
    required this.onDelete,
    required this.onConfirm,
  });

  final bool enabled;
  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;

  Widget _key({
    required String label,
    required Widget child,
    required VoidCallback onTap,
    Color color = AppColors.white,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: enabled ? onTap : null,
          child: SizedBox(height: 64, child: Center(child: child)),
        ),
      ),
    );
  }

  Widget _digitKey(int d) => _key(
    label: '$d',
    onTap: () => onDigit(d),
    child: Text('$d', style: AppText.heading(28)),
  );

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var d = 1; d <= 9; d++) _digitKey(d),
        _key(
          label: 'Delete',
          onTap: onDelete,
          child: const Icon(Icons.backspace_outlined),
        ),
        _digitKey(0),
        _key(
          label: 'Confirm',
          onTap: onConfirm,
          color: AppColors.ink,
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.white,
            size: 30,
          ),
        ),
      ],
    );
  }
}
