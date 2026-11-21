import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wonderly/core/constants/app_constants.dart';
import 'package:wonderly/core/di/injection.dart';
import 'package:wonderly/core/router/routes.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';
import 'package:wonderly/core/widgets/wonder_switch.dart';
import 'package:wonderly/core/widgets/wonder_widgets.dart';
import 'package:wonderly/features/parent/domain/parent_access.dart';
import 'package:wonderly/features/settings/domain/entities/app_settings.dart';
import 'package:wonderly/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:wonderly/features/settings/presentation/widgets/info_sheet.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.me);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Row(
              children: [
                WonderBackButton(
                  onPressed: () => _back(context),
                  label: 'Back',
                  color: AppColors.cream,
                ),
                const SizedBox(width: 12),
                Text('Settings', style: AppText.heading(24)),
              ],
            ),
            const SizedBox(height: 16),
            _Group(
              children: [
                _ToggleRow(
                  icon: Icons.volume_up_rounded,
                  label: 'Sound effects',
                  value: settings.soundEffects,
                  onChanged: (v) => cubit.setSoundEffects(value: v),
                ),
                _ToggleRow(
                  icon: Icons.music_note_rounded,
                  label: 'Music',
                  value: settings.music,
                  onChanged: (v) => cubit.setMusic(value: v),
                ),
                _ToggleRow(
                  icon: Icons.record_voice_over_rounded,
                  label: 'Read questions aloud',
                  value: settings.readAloud,
                  onChanged: (v) => cubit.setReadAloud(value: v),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Group(
              children: [
                _TextSizeRow(
                  selected: settings.textSize,
                  onSelected: cubit.setTextSize,
                ),
                const _InfoRow(
                  icon: Icons.language_rounded,
                  label: 'Language',
                  value: 'English',
                ),
                _ToggleRow(
                  icon: Icons.bedtime_rounded,
                  label: 'Bedtime mode',
                  subtitle: 'After 7:30 pm',
                  value: settings.bedtimeMode,
                  onChanged: (v) {
                    // Bedtime is a grown-up control, so it needs the gate.
                    if (sl<ParentAccess>().isActive) {
                      cubit.setBedtimeMode(value: v);
                    } else {
                      context.push(Routes.parentGate);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Group(
              children: [
                _LinkRow(
                  icon: Icons.help_outline_rounded,
                  label: 'Help and feedback',
                  onTap: () => showInfoSheet(
                    context,
                    title: 'Help and feedback',
                    body: InfoCopy.help,
                  ),
                ),
                _LinkRow(
                  icon: Icons.shield_outlined,
                  label: 'Privacy for families',
                  onTap: () => showInfoSheet(
                    context,
                    title: 'Privacy for families',
                    body: InfoCopy.privacy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                AppConstants.appVersionLabel,
                style: AppText.subtitle(14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 18,
                endIndent: 18,
                color: AppColors.cream,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.icon,
    required this.label,
    required this.trailing,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.heading(17)),
                    if (subtitle != null)
                      Text(subtitle!, style: AppText.subtitle(15)),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      icon: icon,
      label: label,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: ExcludeSemantics(
        child: IgnorePointer(
          child: WonderSwitch(value: value, onChanged: (_) {}, label: label),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      icon: icon,
      label: label,
      trailing: Text(value, style: AppText.subtitle(16)),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      icon: icon,
      label: label,
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
    );
  }
}

class _TextSizeRow extends StatelessWidget {
  const _TextSizeRow({required this.selected, required this.onSelected});

  final TextSize selected;
  final ValueChanged<TextSize> onSelected;

  static const _labels = {
    TextSize.small: ('S', 14.0),
    TextSize.medium: ('M', 18.0),
    TextSize.large: ('L', 22.0),
  };

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      icon: Icons.text_fields_rounded,
      label: 'Text size',
      trailing: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final size in TextSize.values)
              Semantics(
                button: true,
                selected: size == selected,
                label: 'Text size ${_labels[size]!.$1}',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => onSelected(size),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: size == selected
                          ? AppColors.ink
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      _labels[size]!.$1,
                      style: AppText.heading(
                        _labels[size]!.$2,
                        color: size == selected
                            ? AppColors.white
                            : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
