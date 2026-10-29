import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n.dart';
import 'money.dart';
import 'quantity.dart';
import 'theme.dart';

const fieldGap = SizedBox(height: 14);

/// Tappable date shown as text; opens the date picker.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.lastDate,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: DateTime(2015),
        lastDate: lastDate ?? DateTime(2100),
      );
      if (picked != null) onChanged(picked);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
      ),
      child: Text(context.fmt.date(value)),
    ),
  );
}

class _NumberFieldBase extends StatelessWidget {
  const _NumberFieldBase({
    required this.controller,
    required this.label,
    required this.parser,
    this.hint,
    this.required = false,
    this.decimals = true,
    this.prefix,
    this.suffix,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final bool decimals;
  final String? prefix;
  final String? suffix;
  final Object? Function(String) parser;
  final String? Function(String text)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimals),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(decimals ? r'[0-9.,]' : r'[0-9,]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        suffixText: suffix,
      ),
      onChanged: onChanged,
      validator: (text) {
        final value = text ?? '';
        if (value.trim().isEmpty) return required ? l.requiredField : null;
        if (parser(value) == null) return l.invalidNumber;
        return validator?.call(value);
      },
    );
  }
}

class QtyField extends StatelessWidget {
  const QtyField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.decimals = true,
    this.suffix,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final bool decimals;
  final String? suffix;
  final String? Function(String text)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => _NumberFieldBase(
    controller: controller,
    label: label,
    hint: hint,
    required: required,
    decimals: decimals,
    suffix: suffix,
    parser: parseQty,
    validator: validator,
    onChanged: onChanged,
  );
}

class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required;
  final String? Function(String text)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => _NumberFieldBase(
    controller: controller,
    label: label,
    hint: hint,
    required: required,
    prefix: '₹ ',
    parser: parseRupees,
    validator: validator,
    onChanged: onChanged,
  );
}

/// Single choice as a row of chips (big tap targets instead of typing, F2.2).
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T? selected;
  final String Function(T value) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final v in values)
        ChoiceChip(
          label: Text(label(v)),
          selected: v == selected,
          showCheckmark: false,
          onSelected: (_) => onSelected(v),
        ),
    ],
  );
}

class MultiChoiceChips<T> extends StatelessWidget {
  const MultiChoiceChips({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final List<T> values;
  final Set<T> selected;
  final String Function(T value) label;
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final v in values)
        FilterChip(
          label: Text(label(v)),
          selected: selected.contains(v),
          onSelected: (on) =>
              onChanged(on ? {...selected, v} : ({...selected}..remove(v))),
        ),
    ],
  );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      ),
    ),
  );
}
