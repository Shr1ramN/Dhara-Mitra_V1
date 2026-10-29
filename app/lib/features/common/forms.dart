import 'package:flutter/material.dart';

import '../../core/form_fields.dart';
import '../../core/l10n.dart';
import '../../core/money.dart';
import '../../core/quantity.dart';
import '../../core/validation.dart';
import '../../core/widgets.dart';

enum InputKind {
  text,
  notes,
  money,
  quantity,
  integer,
  date,
  choice,
  multiple,
  toggle,
}

class EntryField {
  const EntryField(
    this.key,
    this.label, {
    this.kind = InputKind.text,
    this.required = false,
    this.options = const {},
    this.initial,
    this.positive = false,
    this.minimum,
    this.maximum,
  });
  final String key;
  final String label;
  final InputKind kind;
  final bool required;
  final bool positive;
  final Map<String, String> options;
  final Object? initial;
  final double? minimum;
  final double? maximum;
}

class EntryValues {
  EntryValues(this.values);
  final Map<String, Object?> values;
  String text(String key) => (values[key] ?? '').toString().trim();
  int money(String key) => parseRupees(text(key)) ?? 0;
  double number(String key) => parseQty(text(key)) ?? 0;
  int integer(String key) => number(key).round();
  bool flag(String key) => values[key] == true;
  DateTime? optionalDate(String key) => values[key] as DateTime?;
  DateTime date(String key) => optionalDate(key)!;
  List<String> selected(String key) =>
      (values[key] as Set<String>? ?? {}).toList();
}

String failureText(BuildContext context, Object error) {
  final l = context.l;
  if (error is FarmException) {
    return switch (error.code) {
      'attendance' => l.xAttendanceUsed,
      'backup' => l.xBackupInvalid,
      'positive' => l.xPositive,
      'stock' => l.xNotEnoughStock,
      'linked' => l.xDeleteBlocked,
      'balance' => l.xAmountTooLarge,
      'sold' => l.xCannotReduceSold,
      'dates' => l.xCheckDates,
      _ => l.xInvalid,
    };
  }
  return l.xError;
}

Future<void> perform(
  BuildContext context,
  Future<void> Function() operation,
) async {
  try {
    await operation();
  } catch (error) {
    if (context.mounted) showSnack(context, failureText(context, error));
  }
}

Future<bool> openEntryForm(
  BuildContext context, {
  required String title,
  required List<EntryField> fields,
  required Future<void> Function(EntryValues) onSave,
}) async =>
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EntryForm(title: title, fields: fields, onSave: onSave),
      ),
    ) ??
    false;

class EntryForm extends StatefulWidget {
  const EntryForm({
    super.key,
    required this.title,
    required this.fields,
    required this.onSave,
  });
  final String title;
  final List<EntryField> fields;
  final Future<void> Function(EntryValues) onSave;
  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, Object?> _values = {};
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      if ([
        InputKind.text,
        InputKind.notes,
        InputKind.money,
        InputKind.quantity,
        InputKind.integer,
      ].contains(f.kind)) {
        _controllers[f.key] = TextEditingController(
          text: f.initial?.toString() ?? '',
        );
      } else {
        _values[f.key] = f.kind == InputKind.multiple
            ? {...?f.initial as Set<String>?}
            : f.initial;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    for (final f in widget.fields) {
      if (f.required && f.kind == InputKind.date && _values[f.key] == null) {
        setState(() => _error = '${f.label}: ${context.l.requiredField}');
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        EntryValues({
          ..._values,
          for (final e in _controllers.entries) e.key: e.value.text,
        }),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = failureText(context, error);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final f in widget.fields) ...[_field(f), fieldGap],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l.save),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );

  Widget _field(EntryField f) {
    final l = context.l;
    String? numberValidator(String value) {
      if (value.isEmpty && !f.required) return null;
      final n = f.kind == InputKind.money
          ? parseRupees(value)?.toDouble()
          : parseQty(value);
      if (n == null || !n.isFinite) return l.invalidNumber;
      if (f.positive && n <= 0) return l.xPositive;
      if (n < (f.minimum ?? 0) || (f.maximum != null && n > f.maximum!)) {
        return l.xInvalid;
      }
      if (f.kind == InputKind.integer && n != n.roundToDouble()) {
        return l.xInvalid;
      }
      return null;
    }

    return switch (f.kind) {
      InputKind.text || InputKind.notes => TextFormField(
        controller: _controllers[f.key],
        maxLines: f.kind == InputKind.notes ? 3 : 1,
        decoration: InputDecoration(labelText: f.label),
        validator: (v) =>
            f.required && (v ?? '').trim().isEmpty ? l.requiredField : null,
      ),
      InputKind.money => MoneyField(
        controller: _controllers[f.key]!,
        label: f.label,
        required: f.required,
        validator: numberValidator,
      ),
      InputKind.quantity || InputKind.integer => QtyField(
        controller: _controllers[f.key]!,
        label: f.label,
        required: f.required,
        decimals: f.kind != InputKind.integer,
        validator: numberValidator,
      ),
      InputKind.choice => DropdownButtonFormField<String>(
        initialValue: _values[f.key] as String?,
        isExpanded: true,
        decoration: InputDecoration(labelText: f.label),
        items: [
          for (final e in f.options.entries)
            DropdownMenuItem(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (v) => setState(() => _values[f.key] = v),
        validator: (v) =>
            f.required && (v == null || v.isEmpty) ? l.requiredField : null,
      ),
      InputKind.toggle => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(f.label),
        value: _values[f.key] == true,
        onChanged: (v) => setState(() => _values[f.key] = v),
      ),
      InputKind.multiple => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FieldLabel(f.label),
          MultiChoiceChips(
            values: f.options.keys.toList(),
            selected: _values[f.key] as Set<String>? ?? {},
            label: (k) => f.options[k]!,
            onChanged: (v) => setState(() => _values[f.key] = v),
          ),
        ],
      ),
      InputKind.date => Row(
        children: [
          Expanded(
            child: _values[f.key] == null
                ? OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _values[f.key] = DateTime.now()),
                    icon: const Icon(Icons.calendar_month),
                    label: Text(f.label),
                  )
                : DateField(
                    label: f.label,
                    value: _values[f.key] as DateTime,
                    onChanged: (v) => setState(() => _values[f.key] = v),
                  ),
          ),
          if (!f.required && _values[f.key] != null)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l.cancel,
              onPressed: () => setState(() => _values[f.key] = null),
            ),
        ],
      ),
    };
  }
}
