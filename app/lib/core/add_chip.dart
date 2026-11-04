import 'dart:async';

import 'package:flutter/material.dart';

import 'draft_guard.dart';
import 'l10n.dart';
import 'v1.dart';
import 'widgets.dart';
import '../features/common/forms.dart';

class AddChip extends StatelessWidget {
  const AddChip({super.key, required this.title, required this.onAdd});
  final String title;
  final FutureOr<void> Function(String) onAdd;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: title,
    child: ActionChip(
      label: Icon(Icons.add, semanticLabel: title),
      onPressed: () async {
        final value = await showDialog<String>(
          context: context,
          builder: (_) => _NameDialog(title: title),
        );
        if (value == null || !context.mounted) return;
        try {
          await onAdd(value);
        } catch (e) {
          if (context.mounted) showSnack(context, failureText(context, e));
        }
      },
    ),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title});
  final String title;
  @override
  State<_NameDialog> createState() => _NameState();
}

class _NameState extends State<_NameDialog> {
  final name = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  void save() {
    if (!form.currentState!.validate()) return;
    acceptDrafts();
    Navigator.pop(context, name.text.trim());
  }

  @override
  Widget build(BuildContext context) => DraftGuard(
    controllers: [name],
    child: AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: form,
        child: TextFormField(
          autofocus: true,
          controller: name,
          decoration: InputDecoration(
            labelText: v1Text(context, 'Name', 'ಹೆಸರು'),
          ),
          validator: (v) =>
              (v ?? '').trim().isEmpty ? context.l.requiredField : null,
          onFieldSubmitted: (_) => save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (await confirmLeaving(context) && context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Text(context.l.cancel),
        ),
        TextButton(onPressed: save, child: Text(context.l.save)),
      ],
    ),
  );
}
