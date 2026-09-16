import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../buttons/primary_button.dart';
import 'dialog_shell.dart';

/// A yes/no prompt (e.g. confirming a delete) shown as a modal dialog.
/// Resolves to `true` only if the user picked the confirm action —
/// cancelling or dismissing it any other way resolves to `false`.
/// [destructive] colors the confirm button as a warning (red) rather than
/// the theme's own accent, for an action that can't be undone.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: destructive,
    ),
  );
  return confirmed ?? false;
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.destructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DialogShell(
      title: title,
      actions: [
        PrimaryButton(
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(CupertinoIcons.xmark, size: AppSizes.iconMedium),
          label: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurface,
        ),
        PrimaryButton(
          onPressed: () => Navigator.of(context).pop(true),
          icon: Icon(
            destructive ? CupertinoIcons.delete : CupertinoIcons.checkmark_alt,
            size: AppSizes.iconMedium,
          ),
          label: Text(confirmLabel),
          backgroundColor: destructive ? Colors.red : colorScheme.primary,
          foregroundColor: destructive ? Colors.white : colorScheme.onPrimary,
        ),
      ],
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
