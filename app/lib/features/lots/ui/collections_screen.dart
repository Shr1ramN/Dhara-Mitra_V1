import '../../../core/v1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/database.dart';
import '../../../core/form_fields.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/quantity.dart';
import '../../../core/widgets.dart';
import '../data/collections_repository.dart';

final collectionsRepositoryProvider = Provider(
  (ref) => CollectionsRepository(ref.watch(databaseProvider)),
);
final collectionsProvider = StreamProvider(
  (ref) => ref.watch(collectionsRepositoryProvider).watch(),
);

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});
  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.fCollections)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const CollectionForm()),
        ),
        icon: const Icon(Icons.add),
        label: Text(l.fNewCollection),
      ),
      body: AsyncBody(
        value: ref.watch(collectionsProvider),
        builder: (rows) {
          final pending = rows.where((c) => c.lotId == null).toList();
          _selected.removeWhere((id) => !pending.any((c) => c.id == id));
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Text(l.fCollectionHint),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.wb_sunny_outlined),
                label: Text('${l.fDrySelected} (${_selected.length})'),
                onPressed: _selected.isEmpty
                    ? null
                    : () async {
                        final selected = pending
                            .where((c) => _selected.contains(c.id))
                            .toList();
                        if (selected.map((c) => c.unit).toSet().length != 1) {
                          showSnack(context, l.fMixedUnits);
                          return;
                        }
                        final id = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DryCollectionsForm(selected),
                          ),
                        );
                        if (id != null && context.mounted) {
                          setState(_selected.clear);
                          await context.push('/lot/$id');
                        }
                      },
              ),
              SectionTitle(l.fUnassigned),
              for (final row in pending)
                PaddedCard(
                  child: Column(
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _selected.contains(row.id),
                        title: Text(
                          '${context.fmt.date(row.collectedOn)} · ${collectionQuantity(context, row)}',
                        ),
                        subtitle: row.notes.isEmpty ? null : Text(row.notes),
                        onChanged: (value) => setState(() {
                          if (value == true) {
                            _selected.add(row.id);
                          } else {
                            _selected.remove(row.id);
                          }
                        }),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(l.edit),
                          onPressed: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CollectionForm(existing: row),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (rows.any((c) => c.lotId != null)) SectionTitle(l.fAssigned),
              for (final row in rows.where((c) => c.lotId != null))
                ListTile(
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: Text(
                    '${context.fmt.date(row.collectedOn)} · ${collectionQuantity(context, row)}',
                  ),
                  subtitle: Text(row.notes),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/lot/${row.lotId}'),
                ),
            ],
          );
        },
      ),
    );
  }
}

String collectionQuantity(BuildContext context, ArecaCollection row) =>
    row.quantity == null
    ? context.l.fQuantityUnknown
    : '${formatQty(row.quantity!)} ${row.unit == 'bags' ? context.l.bags : 'kg'}';

class CollectionForm extends ConsumerStatefulWidget {
  const CollectionForm({super.key, this.existing});
  final ArecaCollection? existing;
  @override
  ConsumerState<CollectionForm> createState() => _CollectionFormState();
}

class _CollectionFormState extends ConsumerState<CollectionForm> {
  final _form = GlobalKey<FormState>();
  late DateTime _on = widget.existing?.collectedOn ?? ref.read(entryDayProvider);
  late String _unit = widget.existing?.unit ?? 'bags';
  late Set<String> _plots = widget.existing?.plotIds.toSet() ?? {};
  late final _quantity = TextEditingController(
    text: qtyToInput(widget.existing?.quantity),
  );
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing == null) {
      ref.read(databaseProvider).setting('harvest_unit').then((unit) {
        if (mounted && unit != null) setState(() => _unit = unit);
      });
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(collectionsRepositoryProvider)
          .save(
            id: widget.existing?.id,
            on: _on,
            plotIds: _plots.toList(),
            unit: _unit,
            quantity: parseQty(_quantity.text),
            notes: _notes.text,
            kind: widget.existing?.kind ?? 'daily',
          );
      await ref.read(databaseProvider).putSetting('harvest_unit', _unit);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) showSnack(context, context.l.xInvalid);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final plots = ref.watch(plotsProvider).value ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.fCollections),
        actions: [
          if (widget.existing != null && widget.existing!.lotId == null)
            IconButton(
              tooltip: l.deleteEntry,
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy
                  ? null
                  : () async {
                      if (!await confirm(context, title: l.deleteEntry)) return;
                      setState(() => _busy = true);
                      try {
                        await ref
                            .read(collectionsRepositoryProvider)
                            .remove(widget.existing!.id);
                        if (context.mounted) Navigator.pop(context);
                      } catch (_) {
                        if (context.mounted) {
                          showSnack(context, l.fCollectionLocked);
                        }
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.existing?.lotId == null) ...[
              DateField(
                label: l.date,
                value: _on,
                lastDate: ref.read(todayProvider),
                onChanged: (d) => setState(() => _on = d),
              ),
              fieldGap,
              FieldLabel(l.whichPlots),
              MultiChoiceChips(
                values: plots.map((p) => p.id).toList(),
                selected: _plots,
                label: (id) => plots.firstWhere((p) => p.id == id).name,
                onChanged: (v) => setState(() => _plots = v),
              ),
              fieldGap,
              ChoiceChips(
                values: const ['bags', 'kg'],
                selected: _unit,
                label: (u) => u == 'bags' ? l.fBagsMode : l.fKgMode,
                onSelected: (v) => setState(() {
                  _unit = v;
                  _quantity.clear();
                }),
              ),
              fieldGap,
            ],
            QtyField(
              controller: _quantity,
              label: _unit == 'bags' ? l.fFreshBags : l.freshKg,
              hint: l.fQuantityUnknown,
              validator: (v) => (parseQty(v) ?? 0) <= 0 ? l.xInvalid : null,
            ),
            fieldGap,
            TextField(
              controller: _notes,
              decoration: InputDecoration(labelText: l.notes),
              maxLines: 3,
            ),
            fieldGap,
            FilledButton(onPressed: _busy ? null : _save, child: Text(l.save)),
          ],
        ),
      ),
    );
  }
}

class DryCollectionsForm extends ConsumerStatefulWidget {
  const DryCollectionsForm(this.rows, {super.key});
  final List<ArecaCollection> rows;
  @override
  ConsumerState<DryCollectionsForm> createState() => _DryCollectionsFormState();
}

class _DryCollectionsFormState extends ConsumerState<DryCollectionsForm> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _yard = TextEditingController();
  late DateTime _on = ref.read(entryDayProvider);
  bool _busy = false;
  @override
  void dispose() {
    _title.dispose();
    _yard.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.fDrySelected)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final row in widget.rows)
              ListTile(
                title: Text(context.fmt.date(row.collectedOn)),
                trailing: Text(collectionQuantity(context, row)),
              ),
            fieldGap,
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: l.lotTitle),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l.requiredField : null,
            ),
            fieldGap,
            DateField(
              label: l.startDrying,
              value: _on,
              lastDate: ref.read(todayProvider),
              onChanged: (d) => setState(() => _on = d),
            ),
            fieldGap,
            TextField(
              controller: _yard,
              decoration: InputDecoration(labelText: l.yard),
            ),
            fieldGap,
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      if (!_form.currentState!.validate()) return;
                      if (widget.rows.any((c) => c.collectedOn.isAfter(_on))) {
                        showSnack(context, l.fCollectionDateError);
                        return;
                      }
                      setState(() => _busy = true);
                      try {
                        final id = await ref
                            .read(collectionsRepositoryProvider)
                            .dryTogether(
                              widget.rows.map((c) => c.id).toSet(),
                              on: _on,
                              title: _title.text,
                              yard: _yard.text,
                              seasonStartMonth:
                                  ref
                                      .read(farmProvider)
                                      .value
                                      ?.seasonStartMonth ??
                                  6,
                            );
                        if (context.mounted) Navigator.pop(context, id);
                      } catch (_) {
                        if (context.mounted) {
                          showSnack(context, l.fCollectionLocked);
                        }
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(l.startDrying),
            ),
          ],
        ),
      ),
    );
  }
}

class LotCollections extends ConsumerWidget {
  const LotCollections(this.lotId, {super.key});
  final String lotId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = (ref.watch(collectionsProvider).value ?? [])
        .where((c) => c.lotId == lotId)
        .toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(context.l.fCollections),
        for (final row in rows)
          ListTile(
            contentPadding: EdgeInsets.zero,
            trailing: IconButton(
              tooltip: context.l.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => CollectionForm(existing: row),
                ),
              ),
            ),
            title: Text(
              '${context.fmt.date(row.collectedOn)} · ${collectionQuantity(context, row)}',
            ),
            subtitle: row.notes.isEmpty ? null : Text(row.notes),
          ),
      ],
    );
  }
}
