import 'package:flutter/material.dart';
import 'package:wonderly/core/theme/app_colors.dart';
import 'package:wonderly/core/theme/app_text.dart';

/// Static copy for the in-app info sheets. Everything is offline, so there are
/// no external links a child could follow.
abstract final class InfoCopy {
  static const help =
      'Wonderly works without internet.\n\n'
      '• Tap Read aloud on a question to hear it.\n'
      '• Tap Hint if you are stuck.\n'
      '• Grown-ups can set a daily play limit and set up Smart Buddy in the '
      'Grown-ups zone.\n\n'
      'Questions or ideas? Ask a grown-up to contact the app publisher '
      'through the app store listing.';

  static const privacy =
      'Wonderly keeps your child safe.\n\n'
      '• No account, no sign-in and no ads.\n'
      '• Name, buddy and progress stay on this device only.\n'
      '• Smart Buddy writes quizzes on this phone. Nothing you or your child '
      'type or answer is ever sent anywhere.\n'
      '• The only download is the Smart Buddy model file, and only after a '
      'grown-up approves it.\n'
      '• No analytics or tracking tools are used.\n'
      '• There are no links to other websites or apps.\n\n'
      'Removing the app erases everything it stored.';
}

/// Shows [body] in a rounded bottom sheet.
Future<void> showInfoSheet(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.heading(24)),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Text(body, style: AppText.body(16, height: 1.45)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
