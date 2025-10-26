// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/tomtom_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TomTomService _service = TomTomService();
  final TextEditingController startCtrl = TextEditingController();
  final TextEditingController queryCtrl = TextEditingController();
  final TextEditingController stopCtrl = TextEditingController();
  final MapController mapController = MapController();
  List<LatLng> routePoints = [];
  LatLng? startMarker;
  LatLng? endMarker;
  bool loading = false;
  String status = 'Ready';
  bool collapsed = false;

  List<String> _mapQueryToAvoids(String q) {
    final List<String> avoids = [];
    final s = q.toLowerCase();
    if (s.contains('toll')) avoids.add('tollRoads');
    if (s.contains('motorway') || s.contains('highway')) avoids.add('motorways');
    if (s.contains('ferry')) avoids.add('ferries');
    if (s.contains('unpaved') || s.contains('gravel') || s.contains('dirt')) avoids.add('unpavedRoads');
    if (s.contains('carpool') || s.contains('hov')) avoids.add('carpoolLanes');
    return avoids;
  }

  Future<void> _planRoute() async {
    setState(() => loading = true);
    final s = startCtrl.text.trim();
    final e = stopCtrl.text.trim();
    if (s.isEmpty || e.isEmpty) {
      setState(() {
        status = 'Enter both addresses';
        loading = false;
      });
      return;
    }

    final startLoc = await _service.geocode(s);
    final endLoc = await _service.geocode(e);
    if (startLoc == null || endLoc == null) {
      setState(() {
        status = 'Could not geocode addresses';
        loading = false;
      });
      return;
    }

    final avoids = _mapQueryToAvoids(queryCtrl.text);
    final route = await _service.calculateRoute(
      startLat: startLoc['lat']!,
      startLon: startLoc['lon']!,
      endLat: endLoc['lat']!,
      endLon: endLoc['lon']!,
      avoids: avoids,
    );

    if (route == null || route.isEmpty) {
      setState(() {
        status = 'No route found';
        loading = false;
      });
      return;
    }

    final points = route.map((p) => LatLng(p['lat']!, p['lon']!)).toList();
    setState(() {
      routePoints = points;
      startMarker = LatLng(startLoc['lat']!, startLoc['lon']!);
      endMarker = LatLng(endLoc['lat']!, endLoc['lon']!);
      mapController.move(points.first, 8);
      status = 'Route ready';
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: mapController,
          options: const MapOptions(
            initialCenter: LatLng(20.5937, 78.9629),
            initialZoom: 10,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  "https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key={key}",
              additionalOptions: {"key": TomTomService().key},
            ),
            if (routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(points: routePoints, strokeWidth: 5.0, color: Colors.indigo)
                ],
              ),
            MarkerLayer(
              markers: [
                if (startMarker != null)
                  Marker(
                    point: startMarker!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.place, size: 36, color: Colors.green),
                  ),
                if (endMarker != null)
                  Marker(
                    point: endMarker!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.flag, size: 36, color: Colors.red),
                  ),
              ],
            ),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!collapsed) ...[
                      TextField(
                        controller: startCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Start address', border: InputBorder.none),
                      ),
                      const Divider(),
                      TextField(
                        controller: stopCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Stop address', border: InputBorder.none),
                      ),
                      const Divider(),
                      TextField(
                        controller: queryCtrl,
                        decoration: const InputDecoration(
                            hintText:
                                'Query (e.g. avoid tolls / avoid ferry / avoid motorways)',
                            border: InputBorder.none),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.alt_route),
                            label: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text('Plan route')),
                            onPressed: loading ? null : _planRoute,
                          ),
                        )
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(
                            child: Text(status,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)))
                      ]),
                    ],
                    IconButton(
                      icon: Icon(
                        collapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        size: 28,
                        color: Colors.grey[700],
                      ),
                      onPressed: () => setState(() => collapsed = !collapsed),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
