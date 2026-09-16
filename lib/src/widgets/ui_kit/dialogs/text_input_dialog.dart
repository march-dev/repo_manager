import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../buttons/primary_button.dart';
import '../text/app_text_field.dart';
import 'dialog_shell.dart';

/// A single-line text prompt (e.g. naming a new collection) shown as a
/// modal dialog. Resolves to the trimmed, non-empty text the user
/// confirmed, or `null` if they cancelled/dismissed it instead.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String hintText,
  required String confirmLabel,
  String? initialValue,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextInputDialog(
      title: title,
      hintText: hintText,
      confirmLabel: confirmLabel,
      initialValue: initialValue,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.hintText,
    required this.confirmLabel,
    this.initialValue,
  });

  final String title;
  final String hintText;
  final String confirmLabel;
  final String? initialValue;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return DialogShell(
      title: widget.title,
      actions: [
        PrimaryButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(CupertinoIcons.xmark, size: AppSizes.iconMedium),
          label: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        PrimaryButton(
          onPressed: _submit,
          icon: const Icon(CupertinoIcons.checkmark_alt,
              size: AppSizes.iconMedium),
          label: Text(widget.confirmLabel),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ],
      child: AppTextField(
        controller: _controller,
        hintText: widget.hintText,
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
