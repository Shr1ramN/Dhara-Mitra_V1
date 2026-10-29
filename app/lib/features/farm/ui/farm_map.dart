import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n.dart';
import '../../../core/widgets.dart';

class FarmMap extends StatefulWidget {
  const FarmMap({super.key, this.initial});
  final LatLng? initial;

  @override
  State<FarmMap> createState() => _FarmMapState();
}

class _FarmMapState extends State<FarmMap> {
  final _map = MapController();
  late LatLng? _point = widget.initial;
  bool _locating = false;
  bool _tileError = false;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission denied');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() => _point = point);
      _map.move(point, 17);
    } catch (_) {
      if (mounted) showSnack(context, context.l.fLocationUnavailable);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l.fChooseLocation)),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.l.fMapHint),
        ),
        if (_tileError)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(context.l.fMapOffline),
          ),
        Expanded(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _point ?? const LatLng(13.4, 75.0),
              initialZoom: _point == null ? 8 : 16,
              maxZoom: 19,
              onTap: (_, point) => setState(() => _point = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'in.dharamitra.app',
                maxNativeZoom: 19,
                errorTileCallback: (_, _, _) {
                  if (!_tileError && mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _tileError = true);
                    });
                  }
                },
              ),
              if (_point != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _point!,
                      width: 48,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.location_pin,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              Align(
                alignment: Alignment.bottomRight,
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: TextButton(
                    onPressed: () async {
                      await launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      );
                    },
                    child: const Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _locating ? null : _locate,
                  icon: const Icon(Icons.my_location),
                  label: Text(context.l.xUseLocation),
                ),
                FilledButton.icon(
                  onPressed: _point == null
                      ? null
                      : () => Navigator.pop(context, _point),
                  icon: const Icon(Icons.check),
                  label: Text(context.l.fUsePin),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
