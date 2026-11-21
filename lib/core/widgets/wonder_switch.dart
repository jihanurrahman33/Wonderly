import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';

/// Toggle styled like the design: olive when on, grey when off.
class WonderSwitch extends StatelessWidget {
  const WonderSwitch({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  /// Spoken description, for example "Sound effects".
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      toggled: value,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.white,
        activeTrackColor: AppColors.olive,
        inactiveThumbColor: AppColors.white,
        inactiveTrackColor: AppColors.toggleOff,
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}
