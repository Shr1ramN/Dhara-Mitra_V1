import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/database.dart';
import '../../../core/enums.dart';
import '../../../core/form_fields.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/quantity.dart';
import '../../../core/widgets.dart';
import 'crop_details_screen.dart';

/// Add or edit a plot with its crop counts (F1.2, F1.3).
class PlotFormScreen extends ConsumerStatefulWidget {
  const PlotFormScreen({super.key, this.plotId});

  final String? plotId;

  @override
  ConsumerState<PlotFormScreen> createState() => _PlotFormScreenState();
}

class _PlotFormScreenState extends ConsumerState<PlotFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _acres = TextEditingController();
  final _soil = TextEditingController();
  final _areca = TextEditingController();
  final _coconut = TextEditingController();
  final _pepper = TextEditingController();
  final _banana = TextEditingController();
  Irrigation _irrigation = Irrigation.sprinkler;

  @override
  void initState() {
    super.initState();
    final plot = (ref.read(plotsProvider).value ?? const <Plot>[])
        .where((p) => p.id == widget.plotId)
        .firstOrNull;
    if (plot != null) {
      _name.text = plot.name;
      _acres.text = plot.acres > 0 ? qtyToInput(plot.acres) : '';
      _soil.text = plot.soil;
      _areca.text = _count(plot.arecaPalms);
      _coconut.text = _count(plot.coconutTrees);
      _pepper.text = _count(plot.pepperVines);
      _banana.text = _count(plot.bananaClumps);
      _irrigation = plot.irrigation;
    }
  }

  static String _count(int n) => n > 0 ? '$n' : '';

  static int _parseCount(TextEditingController c) =>
      parseQty(c.text)?.round() ?? 0;

  @override
  void dispose() {
    for (final c in [
      _name,
      _acres,
      _soil,
      _areca,
      _coconut,
      _pepper,
      _banana,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await ref
        .read(farmRepositoryProvider)
        .savePlot(
          PlotsCompanion(
            id: widget.plotId == null
                ? const Value.absent()
                : Value(widget.plotId!),
            name: Value(_name.text.trim()),
            acres: Value(parseQty(_acres.text) ?? 0),
            soil: Value(_soil.text.trim()),
            irrigation: Value(_irrigation),
            arecaPalms: Value(_parseCount(_areca)),
            coconutTrees: Value(_parseCount(_coconut)),
            pepperVines: Value(_parseCount(_pepper)),
            bananaClumps: Value(_parseCount(_banana)),
          ),
        );
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final l = context.l;
    if (!await confirm(
      context,
      title: l.deletePlot,
      body: l.deleteCannotUndo,
    )) {
      return;
    }
    await ref.read(farmRepositoryProvider).deletePlot(widget.plotId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plotId == null ? l.addPlot : l.editPlot),
        actions: [
          if (widget.plotId != null)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              tooltip: l.delete,
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.plotName,
                hintText: l.plotNameHint,
              ),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l.requiredField : null,
            ),
            fieldGap,
            Row(
              children: [
                Expanded(
                  child: QtyField(controller: _acres, label: l.acres),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _soil,
                    decoration: InputDecoration(
                      labelText: l.soil,
                      hintText: l.soilHint,
                    ),
                  ),
                ),
              ],
            ),
            fieldGap,
            FieldLabel(l.irrigation),
            ChoiceChips(
              values: Irrigation.values,
              selected: _irrigation,
              label: l.irrigationType,
              onSelected: (v) => setState(() => _irrigation = v),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: QtyField(
                    controller: _areca,
                    label: l.arecaPalms,
                    decimals: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QtyField(
                    controller: _coconut,
                    label: l.coconutTrees,
                    decimals: false,
                  ),
                ),
              ],
            ),
            fieldGap,
            Row(
              children: [
                Expanded(
                  child: QtyField(
                    controller: _pepper,
                    label: l.pepperVines,
                    decimals: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QtyField(
                    controller: _banana,
                    label: l.bananaClumps,
                    decimals: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (widget.plotId != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.park_outlined),
                label: Text(l.xCropDetails),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CropDetailsScreen(widget.plotId!),
                  ),
                ),
              ),
            FilledButton(onPressed: _save, child: Text(l.save)),
          ],
        ),
      ),
    );
  }
}
