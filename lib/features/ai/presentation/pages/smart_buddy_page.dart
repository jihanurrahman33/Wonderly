import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/services/natural_voice.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/art_view.dart';
import 'package:wonderly/core/widgets/wonder_button.dart';
import 'package:wonderly/core/widgets/wonder_progress_bar.dart';
import 'package:wonderly/core/widgets/wonder_switch.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';
import 'package:wonderly/features/ai/domain/entities/model_profile.dart';
import 'package:wonderly/features/ai/domain/entities/model_status.dart';
import 'package:wonderly/features/ai/presentation/cubit/generation_cubit.dart';
import 'package:wonderly/features/ai/presentation/cubit/model_cubit.dart';
import 'package:wonderly/features/settings/presentation/cubit/settings_cubit.dart';

/// Grown-ups page to set up the on-device AI: pick a model, download it once,
/// and control background question writing.
class SmartBuddyPage extends StatelessWidget {
  const SmartBuddyPage({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.me);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ModelCubit>().state;
    final generation = context.watch<GenerationCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          children: [
            Row(
              children: [
                WonderBackButton(
                  onPressed: () => _back(context),
                  color: AppColors.cream,
                ),
                const SizedBox(width: 12),
                Text('Smart Buddy', style: AppText.heading(24)),
              ],
            ),
            const SizedBox(height: 16),
            _Intro(awake: model.isInstalled),
            const SizedBox(height: 14),
            _StatusCard(model: model),
            if (model.isInstalled) ...[
              const SizedBox(height: 14),
              _GenerationCard(
                generation: generation,
                enabled: settings.aiEnabled,
              ),
            ],
            if (model.status is! ModelUnsupported) ...[
              const SizedBox(height: 14),
              const _VoiceCard(),
            ],
            const SizedBox(height: 14),
            const _PrivacyNote(),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.color = AppColors.white});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(26),
    ),
    child: child,
  );
}

class _Intro extends StatelessWidget {
  const _Intro({required this.awake});

  final bool awake;

  @override
  Widget build(BuildContext context) {
    return _Card(
      color: AppColors.sage,
      child: Row(
        children: [
          const ArtView('owl', size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  awake ? 'Smart Buddy is awake' : 'Wake up Smart Buddy',
                  style: AppText.heading(20),
                ),
                const SizedBox(height: 4),
                Text(
                  'An AI that runs on this phone writes fresh quizzes for your '
                  "child's grade, and a weekly note for you.",
                  style: AppText.body(15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.model});

  final ModelState model;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ModelCubit>();
    final settings = context.read<SettingsCubit>();
    return switch (model.status) {
      ModelUnsupported(:final reason) => _Card(
        child: _Message(icon: Icons.info_outline_rounded, text: reason),
      ),
      ModelDownloading(:final percent) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Downloading ${model.profile.model}',
              style: AppText.heading(18),
            ),
            const SizedBox(height: 10),
            WonderProgressBar(
              value: percent / 100,
              height: 12,
              track: AppColors.sand,
              semanticLabel: 'Download progress',
            ),
            const SizedBox(height: 8),
            Text(
              '$percent% of ${model.profile.sizeLabel}. Keep the app open and '
              'stay on Wi-Fi.',
              style: AppText.subtitle(14),
            ),
            const SizedBox(height: 14),
            WonderButton(
              label: 'Cancel',
              style: WonderButtonStyle.outlined,
              showIcon: false,
              height: 50,
              onPressed: cubit.cancel,
            ),
          ],
        ),
      ),
      ModelInstalled() => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Message(
              icon: Icons.check_circle_rounded,
              text:
                  '${model.profile.model} is installed (${model.profile.sizeLabel}).',
              color: AppColors.olive,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _confirmDelete(context, cubit),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(
                'Remove model',
                style: AppText.label(15, color: AppColors.incorrect),
              ),
            ),
          ],
        ),
      ),
      ModelNotInstalled() || ModelFailed() => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (model.status case ModelFailed(:final message)) ...[
              _Message(
                icon: Icons.error_outline_rounded,
                text: message,
                color: AppColors.incorrect,
              ),
              const SizedBox(height: 12),
            ],
            Text('Choose a model', style: AppText.heading(18)),
            const SizedBox(height: 10),
            for (final profile in ModelProfile.values)
              _ProfileTile(
                profile: profile,
                selected: profile == model.profile,
                onTap: () {
                  unawaited(settings.setModelProfile(profile.name));
                  unawaited(cubit.selectProfile(profile));
                },
              ),
            const SizedBox(height: 6),
            Text('One-time download. Use Wi-Fi.', style: AppText.subtitle(14)),
            const SizedBox(height: 12),
            WonderButton(
              label: 'Download ${model.profile.sizeLabel}',
              icon: Icons.download_rounded,
              onPressed: () => _download(context, cubit),
            ),
          ],
        ),
      ),
    };
  }

  Future<void> _download(BuildContext context, ModelCubit cubit) async {
    final start = await cubit.download();
    if (start != DownloadStart.needsWifiConfirmation || !context.mounted) {
      return;
    }
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Not on Wi-Fi'),
        content: Text(
          'This download is ${cubit.state.profile.sizeLabel}. On mobile data '
          'it may use a lot of your plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Wait for Wi-Fi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download anyway'),
          ),
        ],
      ),
    );
    if (proceed ?? false) await cubit.download(allowMetered: true);
  }

  Future<void> _confirmDelete(BuildContext context, ModelCubit cubit) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove the model?'),
        content: const Text(
          'Smart Buddy will stop writing new quizzes. Questions already '
          'written stay on the phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok ?? false) await cubit.delete();
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final ModelProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: selected,
        label:
            '${profile.title}, ${profile.model}, ${profile.sizeLabel}. ${profile.description}',
        excludeSemantics: true,
        child: Material(
          color: selected ? AppColors.butter : AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: selected ? AppColors.ink : AppColors.sand,
              width: 3,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${profile.title} · ${profile.sizeLabel}',
                          style: AppText.heading(17),
                        ),
                        Text(profile.model, style: AppText.label(14)),
                        const SizedBox(height: 2),
                        Text(profile.description, style: AppText.subtitle(14)),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenerationCard extends StatelessWidget {
  const _GenerationCard({required this.generation, required this.enabled});

  final GenerationState generation;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsCubit>();
    final cubit = context.read<GenerationCubit>();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Write new quizzes', style: AppText.heading(18)),
              ),
              WonderSwitch(
                value: enabled,
                label: 'Write new quizzes in the background',
                onChanged: (v) {
                  unawaited(settings.setAiEnabled(value: v));
                  if (v) {
                    unawaited(cubit.maybeStart(force: true));
                  } else {
                    cubit.stop();
                  }
                },
              ),
            ],
          ),
          Text(
            '${generation.bankTotal} questions written on this phone'
            '${generation.bankMissing > 0 ? ', ${generation.bankMissing} to go' : ''}.',
            style: AppText.subtitle(15),
          ),
          if (generation.running) ...[
            const SizedBox(height: 10),
            WonderProgressBar(
              value: generation.wanted == 0
                  ? 0
                  : generation.made / generation.wanted,
              height: 10,
              track: AppColors.sand,
              semanticLabel: 'Writing questions',
            ),
            const SizedBox(height: 6),
            Text(
              'Writing ${generation.setTitle ?? 'questions'}… '
              '${generation.made} of ${generation.wanted}',
              style: AppText.subtitle(14),
            ),
          ],
          if (generation.lowBattery) ...[
            const SizedBox(height: 8),
            Text(
              'Paused: battery is low. Plug in to continue.',
              style: AppText.subtitle(14),
            ),
          ],
          const SizedBox(height: 12),
          if (generation.running)
            WonderButton(
              label: 'Pause',
              style: WonderButtonStyle.outlined,
              showIcon: false,
              height: 50,
              onPressed: cubit.stop,
            )
          else if (generation.bankMissing > 0)
            WonderButton(
              label: 'Write now',
              icon: Icons.auto_awesome_rounded,
              height: 50,
              onPressed: enabled ? () => cubit.maybeStart(force: true) : null,
            ),
        ],
      ),
    );
  }
}

/// Download or remove the natural reading voice.
class _VoiceCard extends StatelessWidget {
  const _VoiceCard();

  @override
  Widget build(BuildContext context) {
    final voice = sl<NaturalVoice>();
    return ValueListenableBuilder<VoiceStatus>(
      valueListenable: voice.status,
      builder: (context, status, _) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Natural voice', style: AppText.heading(18)),
            const SizedBox(height: 6),
            Text(
              status.isReady
                  ? 'A friendly human-sounding voice reads questions aloud, '
                        'even without internet.'
                  : 'Download a friendly human-sounding voice for reading '
                        'questions aloud (${voice.model.sizeLabel}, once).',
              style: AppText.body(15),
            ),
            const SizedBox(height: 12),
            switch (status.stage) {
              VoiceStage.downloading => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WonderProgressBar(
                    value: status.percent / 100,
                    height: 12,
                    track: AppColors.sand,
                    semanticLabel: 'Voice download progress',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${status.percent}%. Keep the app open and stay on Wi-Fi.',
                    style: AppText.subtitle(14),
                  ),
                ],
              ),
              VoiceStage.installing => Text(
                'Getting the voice ready...',
                style: AppText.subtitle(14),
              ),
              VoiceStage.ready => TextButton.icon(
                onPressed: voice.remove,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(
                  'Remove voice',
                  style: AppText.label(15, color: AppColors.incorrect),
                ),
              ),
              VoiceStage.notInstalled || VoiceStage.failed => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (status.message != null) ...[
                    _Message(
                      icon: Icons.info_outline_rounded,
                      text: status.message!,
                    ),
                    const SizedBox(height: 10),
                  ],
                  WonderButton(
                    label: 'Download natural voice',
                    icon: Icons.download_rounded,
                    onPressed: () => unawaited(voice.install()),
                  ),
                ],
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.text,
    this.color = AppColors.muted,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: AppText.body(15))),
    ],
  );
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) => Text(
    'Everything runs on this phone. Questions, answers and your child’s '
    'name are never sent anywhere. The only downloads are the model and the '
    'reading voice.',
    style: AppText.subtitle(14),
    textAlign: TextAlign.center,
  );
}
