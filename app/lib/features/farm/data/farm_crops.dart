import 'dart:convert';

import '../../../core/db/database.dart';

Future<List<String>> loadFarmCrops(AppDatabase db) async {
  final stored = await db.setting('my_crops');
  if (stored != null) return (jsonDecode(stored) as List).cast<String>();
  final crops = <String>{};
  for (final row in await db.select(db.plotCrops).get()) {
    if (!row.deleted) {
      crops.add(switch (row.crop) {
        'areca' => 'Arecanut',
        'coconut' => 'Coconut',
        'pepper' => 'Pepper',
        'banana' => 'Banana',
        _ => row.crop,
      });
    }
  }
  for (final plot in await db.select(db.plots).get()) {
    if (plot.deleted) continue;
    if (plot.arecaPalms > 0) crops.add('Arecanut');
    if (plot.coconutTrees > 0) crops.add('Coconut');
    if (plot.pepperVines > 0) crops.add('Pepper');
    if (plot.bananaClumps > 0) crops.add('Banana');
  }
  return crops.toList();
}

Future<void> saveFarmCrops(AppDatabase db, Iterable<String> crops) =>
    db.putSetting(
      'my_crops',
      jsonEncode(
        crops.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList(),
      ),
    );

Future<void> removeFarmCrop(AppDatabase db, String crop) =>
    db.transaction(() async {
      final crops = await loadFarmCrops(db);
      crops.removeWhere((value) => value == crop);
      await saveFarmCrops(db, crops);
    });
