import '../../../core/deletable_chip.dart';
import '../../../core/add_chip.dart';

import '../../../core/draft_guard.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/database.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../common/forms.dart';
import '../../labour/ui/saved_tick.dart';
import '../data/farm_crops.dart';

class SimpleFarmForm extends ConsumerStatefulWidget {
  const SimpleFarmForm({super.key, required this.isSetup});
  final bool isSetup;
  @override
  ConsumerState<SimpleFarmForm> createState() => _SimpleFarmState();
}

class _SimpleFarmState extends ConsumerState<SimpleFarmForm> {
  final form = GlobalKey<FormState>(),
      name = TextEditingController(),
      location = TextEditingController(),
      crop = TextEditingController();
  Farm? farm;
  List<String> crops = [];
  bool loading = true, saving = false;
  Object? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final saved = await ref.read(farmRepositoryProvider).getFarm();
      final existing = await loadFarmCrops(ref.read(databaseProvider));
      if (!mounted) return;
      setState(() {
        farm = saved;
        name.text = saved?.name ?? '';
        location.text = saved?.village ?? '';
        crops = existing;
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    name.dispose();
    location.dispose();
    crop.dispose();
    super.dispose();
  }

  void addCrop() {
    final text = crop.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        if (!crops.contains(text)) crops.add(text);
        crop.clear();
      });
    }
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    addCrop();
    setState(() => saving = true);
    try {
      await ref.read(databaseProvider).transaction(() async {
        await ref
            .read(farmRepositoryProvider)
            .saveFarm(
              id: farm?.id,
              name: name.text,
              village: location.text,
              seasonStartMonth: farm?.seasonStartMonth ?? 6,
            );
        await saveFarmCrops(ref.read(databaseProvider), crops);
      });
      if (mounted) {
        acceptDrafts();
        showSavedTick(context, context.l.saved);
        if (widget.isSetup) {
          context.go('/');
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) showSnack(context, failureText(context, e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSetup ? l.setupTitle : l.farm),
        automaticallyImplyLeading: !widget.isSetup,
        actions: [
          if (widget.isSetup)
            IconButton(
              tooltip: l.aBackupRestore,
              onPressed: () => context.push('/backup'),
              icon: const Icon(Icons.backup_outlined),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(l.xError))
          : DraftGuard(
              controllers: [name, location, crop],
              extra: () => crops,
              child: Form(
                key: form,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (widget.isSetup) ...[
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'en', label: Text(l.english)),
                          ButtonSegment(value: 'kn', label: Text(l.kannada)),
                        ],
                        selected: {ref.watch(localeProvider).languageCode},
                        onSelectionChanged: (v) =>
                            ref.read(localeProvider.notifier).set(v.first),
                      ),
                      const SizedBox(height: 18),
                    ],
                    TextFormField(
                      controller: name,
                      decoration: InputDecoration(labelText: l.farmName),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? l.requiredField : null,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: location,
                      decoration: InputDecoration(labelText: l.village),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l.whatDoYouGrow,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in crops)
                          DeletableChip(
                            label: c,
                            onRemove: () => setState(() => crops.remove(c)),
                          ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AddChip(
                        title: l.addCrop,
                        onAdd: (value) {
                          crop.text = value;
                          addCrop();
                        },
                      ),
                    ),
                    Text(l.cropHistorySafe),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: saving ? null : save,
                      child: Text(widget.isSetup ? l.startUsing : l.save),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
