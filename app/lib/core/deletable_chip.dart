import 'dart:async';

import 'package:flutter/material.dart';

import 'l10n.dart';
import 'v1.dart';
import '../features/common/forms.dart';

/// Removes a category choice, never a historical record.
class DeletableChip extends StatelessWidget {
  const DeletableChip({
    super.key,
    required this.label,
    required this.onRemove,
    this.selected = false,
    this.onPressed,
  });
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final FutureOr<void> Function() onRemove;
  Future<void> remove(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(v1Text(c, 'Remove crop?', 'ಬೆಳೆ ತೆಗೆದುಹಾಕಬೇಕೇ?')),
            content: Text(
              v1Text(
                c,
                'Remove "$label" from crop choices? Saved harvests and sales stay unchanged.',
                'ಬೆಳೆ ಆಯ್ಕೆಗಳಿಂದ "$label" ತೆಗೆದುಹಾಕಬೇಕೇ? ಉಳಿಸಿದ ಕೊಯ್ಲು ಮತ್ತು ಮಾರಾಟ ದಾಖಲೆಗಳು ಬದಲಾಗುವುದಿಲ್ಲ.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(c.l.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(v1Text(c, 'Remove', 'ತೆಗೆದುಹಾಕಿ')),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) await onRemove();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress: () => perform(context, () => remove(context)),
    child: InputChip(
      label: Text(label),
      selected: selected,
      onPressed: onPressed,
      onDeleted: () => perform(context, () => remove(context)),
    ),
  );
}
