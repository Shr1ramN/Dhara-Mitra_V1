import '../../../core/v1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:latlong2/latlong.dart';

import 'farm_map.dart';

import '../../../core/form_fields.dart';
import '../../../core/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';

/// First-run setup (F1.1, F1.2) and, later, editing the farm from More.
class FarmScreen extends ConsumerStatefulWidget {
  const FarmScreen({super.key, required this.isSetup});

  final bool isSetup;

  @override
  ConsumerState<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends ConsumerState<FarmScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _village = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  int _seasonStart = 6;
  String? _farmId;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref.read(farmRepositoryProvider).getFarm().then((farm) {
      if (!mounted) return;
      setState(() {
        _loaded = true;
        if (farm == null) return;
        _farmId = farm.id;
        _name.text = farm.name;
        _village.text = farm.village;
        _latitude.text = farm.lat?.toString() ?? '';
        _longitude.text = farm.lng?.toString() ?? '';
        _seasonStart = farm.seasonStartMonth;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _village.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l;
    if (!_form.currentState!.validate()) return;
    final plots = ref.read(plotsProvider).value ?? const [];
    if (plots.isEmpty) {
      showSnack(context, l.needOnePlot);
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(farmRepositoryProvider)
        .saveFarm(
          id: _farmId,
          name: _name.text,
          village: _village.text,
          seasonStartMonth: _seasonStart,
          latitude: Value(double.tryParse(_latitude.text.trim())),
          longitude: Value(double.tryParse(_longitude.text.trim())),
        );
    if (!mounted) return;
    if (widget.isSetup) {
      context.go('/');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final fmt = context.fmt;
    final plots = ref.watch(plotsProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSetup ? l.setupTitle : l.farm),
        automaticallyImplyLeading: !widget.isSetup,
        actions: [
          if (widget.isSetup) ...[
            IconButton(
              tooltip: l.aBackupRestore,
              onPressed: () => context.push('/backup'),
              icon: const Icon(Icons.backup_outlined),
            ),
            if (!v1) IconButton(
              tooltip: l.aAccount,
              onPressed: () => context.push('/account'),
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ],
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  if (widget.isSetup) ...[
                    Text(
                      l.setupIntro,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => context.push('/farms'),
                      icon: const Icon(Icons.swap_horiz),
                      label: Text(l.fFarms),
                    ),
                    FieldLabel(l.language),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'en', label: Text(l.english)),
                        ButtonSegment(value: 'kn', label: Text(l.kannada)),
                      ],
                      selected: {locale.languageCode},
                      onSelectionChanged: (v) =>
                          ref.read(localeProvider.notifier).set(v.first),
                    ),
                    const SizedBox(height: 18),
                  ],
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l.farmName,
                      hintText: l.farmNameHint,
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? l.requiredField : null,
                  ),
                  fieldGap,
                  TextFormField(
                    controller: _village,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l.village,
                      hintText: l.villageHint,
                    ),
                  ),
                  fieldGap,
                  DropdownButtonFormField<int>(
                    initialValue: _seasonStart,
                    decoration: InputDecoration(labelText: l.seasonStarts),
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(value: m, child: Text(fmt.month(m))),
                    ],
                    onChanged: (m) => setState(() => _seasonStart = m ?? 6),
                  ),
                  fieldGap,
                  Text(
                    context.l.xLocation,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(l.fLocationOptional),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.map_outlined),
                    label: Text(
                      _latitude.text.isEmpty
                          ? l.fChooseLocation
                          : l.fLocationSaved,
                    ),
                    onPressed: () async {
                      final lat = double.tryParse(_latitude.text);
                      final lng = double.tryParse(_longitude.text);
                      final point = await Navigator.push<LatLng>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FarmMap(
                            initial: lat == null || lng == null
                                ? null
                                : LatLng(lat, lng),
                          ),
                        ),
                      );
                      if (point != null && mounted) {
                        setState(() {
                          _latitude.text = point.latitude.toString();
                          _longitude.text = point.longitude.toString();
                        });
                      }
                    },
                  ),
                  SectionTitle(
                    l.plotsTitle,
                    trailing: TextButton.icon(
                      onPressed: () => context.push('/plot'),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l.addPlot),
                    ),
                  ),
                  AsyncBody(
                    value: plots,
                    builder: (plots) => plots.isEmpty
                        ? PaddedCard(
                            onTap: () => context.push('/plot'),
                            child: Text(
                              l.setupPlotsHint,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final p in plots)
                                PaddedCard(
                                  onTap: () => context.push('/plot?id=${p.id}'),
                                  child: Row(
                                    children: [
                                      const RoundIcon(Icons.park_outlined),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              [
                                                if (p.acres > 0)
                                                  fmt.area(p.acres),
                                                if (p.arecaPalms > 0)
                                                  l.palmsCount(p.arecaPalms),
                                                l.irrigationType(p.irrigation),
                                              ].join(' · '),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(widget.isSetup ? l.startUsing : l.save),
                  ),
                ],
              ),
            ),
    );
  }
}
