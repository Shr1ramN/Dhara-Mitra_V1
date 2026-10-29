import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/database.dart';
import '../../../core/enums.dart';
import '../../../core/form_fields.dart';
import '../../../core/l10n.dart';
import '../../../core/money.dart';
import '../../../core/indian_phone.dart';
import '../data/labour_repository.dart';
import '../../../core/providers.dart';

/// Add or edit a worker and their rates (F3.1, F3.2).
class WorkerFormScreen extends ConsumerStatefulWidget {
  const WorkerFormScreen({super.key, this.workerId});

  final String? workerId;

  @override
  ConsumerState<WorkerFormScreen> createState() => _WorkerFormScreenState();
}

class _WorkerFormScreenState extends ConsumerState<WorkerFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _telephone = TextEditingController();
  final _newRole = TextEditingController();
  Set<String> _customRoles = {};
  final Set<String> _availableRoles = {};

  final _village = TextEditingController();
  final _dayRate = TextEditingController();
  final _halfRate = TextEditingController();
  final _pieceRate = TextEditingController();
  Set<WorkerRole> _roles = {};
  RateUnit _pieceUnit = RateUnit.palm;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    ref.read(databaseProvider).setting('custom_worker_roles').then((stored) {
      if (!mounted || stored == null) return;
      final roles = (jsonDecode(stored) as List<dynamic>).cast<String>();
      setState(() => _availableRoles.addAll(roles));
    });
    if (widget.workerId != null) {
      ref.read(labourRepositoryProvider).getWorker(widget.workerId!).then((w) {
        if (w == null || !mounted) return;
        setState(() {
          _name.text = w.name;
          _phone.text = w.phone;
          _telephone.text = w.telephone;
          _customRoles = w.customRoles.toSet();
          _availableRoles.addAll(w.customRoles);
          _village.text = w.village;
          _dayRate.text = w.dayRate > 0 ? paiseToInput(w.dayRate) : '';
          _halfRate.text = paiseToInput(w.halfDayRate);
          _pieceRate.text = paiseToInput(w.pieceRate);
          _pieceUnit = w.pieceUnit ?? RateUnit.palm;
          _roles = w.roles.toSet();
          _active = w.active;
        });
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _telephone,
      _newRole,
      _village,
      _dayRate,
      _halfRate,
      _pieceRate,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// A sensible piece-work unit for the roles picked.
  void _onRoles(Set<WorkerRole> roles) => setState(() {
    final added = roles.difference(_roles);
    _roles = roles;
    if (_pieceRate.text.isEmpty && added.isNotEmpty) {
      _pieceUnit = switch (added.first) {
        WorkerRole.climber => RateUnit.palm,
        WorkerRole.peeler => RateUnit.kg,
        WorkerRole.plucker => RateUnit.tree,
        _ => _pieceUnit,
      };
    }
  });

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final pieceRate = parseRupees(_pieceRate.text);
    await ref
        .read(labourRepositoryProvider)
        .saveWorker(
          WorkersCompanion(
            id: widget.workerId == null
                ? const Value.absent()
                : Value(widget.workerId!),
            name: Value(_name.text.trim()),
            phone: Value(
              _phone.text.trim().isEmpty ? '' : indianPhone(_phone.text)!,
            ),
            telephone: Value(
              _telephone.text.trim().isEmpty
                  ? ''
                  : indianPhone(_telephone.text, landline: true)!,
            ),
            customRoles: Value(_customRoles.toList()..sort()),
            village: Value(_village.text.trim()),
            roles: Value(WorkerRole.values.where(_roles.contains).toList()),
            dayRate: Value(parseRupees(_dayRate.text) ?? 0),
            halfDayRate: Value(parseRupees(_halfRate.text)),
            pieceRate: Value(pieceRate),
            pieceUnit: Value(pieceRate == null ? null : _pieceUnit),
            active: Value(_active),
          ),
        );
    await ref
        .read(databaseProvider)
        .putSetting(
          'custom_worker_roles',
          jsonEncode(_availableRoles.toList()..sort()),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    for (final summary
        in ref.watch(workerSummariesProvider).value ??
            const <WorkerSummary>[]) {
      _availableRoles.addAll(summary.worker.customRoles);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workerId == null ? l.addWorker : l.editWorker),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.workerName),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l.requiredField : null,
            ),
            fieldGap,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: l.phone,
                      hintText: '9876543210',
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty || indianPhone(v!) != null
                        ? null
                        : l.fMobileError,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _village,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l.village),
                  ),
                ),
              ],
            ),
            fieldGap,
            TextFormField(
              controller: _telephone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l.fTelephone,
                hintText: '0824 2345678',
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ||
                      indianPhone(v!, landline: true) != null
                  ? null
                  : l.fTelephoneError,
            ),
            fieldGap,
            FieldLabel(l.roles),
            MultiChoiceChips(
              values: WorkerRole.values,
              selected: _roles,
              label: l.role,
              onChanged: _onRoles,
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final role in _availableRoles.toList()..sort())
                  FilterChip(
                    label: Text(role),
                    selected: _customRoles.contains(role),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _customRoles.add(role);
                      } else {
                        _customRoles.remove(role);
                      }
                    }),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newRole,
                    maxLength: 40,
                    decoration: InputDecoration(
                      labelText: l.fAddRole,
                      hintText: l.fRoleHint,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.fAddRole,
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    final name = _newRole.text.trim().replaceAll(',', ' ');
                    if (name.isEmpty) return;
                    final existing = _availableRoles
                        .where((r) => r.toLowerCase() == name.toLowerCase())
                        .firstOrNull;
                    setState(() {
                      _availableRoles.add(existing ?? name);
                      _customRoles.add(existing ?? name);
                      _newRole.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: MoneyField(controller: _dayRate, label: l.dayRate),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MoneyField(
                    controller: _halfRate,
                    label: l.halfDayRate,
                    hint: l.halfDayHint,
                  ),
                ),
              ],
            ),
            fieldGap,
            MoneyField(controller: _pieceRate, label: l.pieceRate),
            const SizedBox(height: 10),
            FieldLabel(l.pieceUnit),
            ChoiceChips(
              values: const [
                RateUnit.palm,
                RateUnit.tree,
                RateUnit.kg,
                RateUnit.nut,
              ],
              selected: _pieceUnit,
              label: l.unit,
              onSelected: (u) => setState(() => _pieceUnit = u),
            ),
            if (widget.workerId != null) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.activeWorker),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: Text(l.save)),
          ],
        ),
      ),
    );
  }
}
