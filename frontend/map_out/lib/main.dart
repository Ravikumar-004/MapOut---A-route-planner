import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) =>
      MaterialApp(debugShowCheckedModeBanner: false, home: HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final startCtrl = TextEditingController();
  final endCtrl = TextEditingController();
  final queryCtrl = TextEditingController();

  List<LatLng> polylinePoints = [];
  LatLng? startPoint;
  LatLng? endPoint;
  LatLng? currentLocation;

  List<Marker> placeMarkers = [];
  final mapController = MapController();

  bool isPanelOpen = true;
  final ValueNotifier<bool> isRunning = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    final pos = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      currentLocation = LatLng(pos.latitude, pos.longitude);
    });

    mapController.move(currentLocation!, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: LatLng(20.29606, 85.82454),
            initialZoom: 13,
            interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c'],
            ),

            if (polylinePoints.isNotEmpty)
              PolylineLayer(polylines: [
                Polyline(
                    points: polylinePoints,
                    color: Colors.blueAccent,
                    strokeWidth: 5.5)
              ]),

            if (startPoint != null)
              MarkerLayer(markers: [
                Marker(
                  point: startPoint!,
                  width: 120,
                  height: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_pin, color: Colors.green, size: 34),
                      SizedBox(
                        width: 100,
                        child: Text(
                          startCtrl.text.trim(),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            backgroundColor: Colors.white54,
                          ),
                        ),
                      )
                    ],
                  ),
                )

              ]),

            if (endPoint != null)
              MarkerLayer(markers: [
                Marker(
                  point: endPoint!,
                  width: 120,
                  height: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, color: Colors.red, size: 34),
                      SizedBox(
                        width: 100,
                        child: Text(
                          endCtrl.text.trim(),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            backgroundColor: Colors.white54,
                          ),
                        ),
                      )
                    ],
                  ),
                )

              ]),

            if (currentLocation != null)
              MarkerLayer(markers: [
                Marker(
                point: currentLocation!,
                width: 120,
                height: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location, color: Colors.blueAccent, size: 32),
                    SizedBox(
                      width: 80,
                      child: Text(
                        "You",
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          backgroundColor: Colors.white54,
                        ),
                      ),
                    )
                  ],
                ),
              )

              ]),

            if (placeMarkers.isNotEmpty)
              MarkerLayer(markers: placeMarkers),
          ],
        ),

        AnimatedPositioned(
          duration: Duration(milliseconds: 250),
          left: isPanelOpen ? 0 : -300,
          top: 0,
          height: 300,
          width: 300,
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("MAPOUT",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () =>
                          setState(() => isPanelOpen = false))
                ],
              ),
              SizedBox(height: 10),
              TextField(
                  controller: startCtrl,
                  decoration: InputDecoration(labelText: "Start point")),
              SizedBox(height: 10),
              TextField(
                  controller: endCtrl,
                  decoration: InputDecoration(labelText: "Destination")),
              SizedBox(height: 10),
              TextField(
                  controller: queryCtrl,
                  decoration: InputDecoration(labelText: "Query")),
              SizedBox(height: 20),
              ElevatedButton.icon(
                  onPressed: _getRoute,
                  icon: Icon(Icons.directions),
                  label: Text("Get Route")),
            ]),
          ),
        ),

        if (!isPanelOpen)
          Positioned(
            top: 20,
            left: 20,
            child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () =>
                    setState(() => isPanelOpen = true),
                child: Icon(Icons.menu, color: Colors.black)),
          ),

        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                if (currentLocation != null) {
                  mapController.move(currentLocation!, 14.0);
                }
              },
              child: Icon(Icons.my_location, color: Colors.blueAccent)),
        )
      ]),
    );
  }

  Future<void> _getRoute() async {
    isRunning.value = true;

    final start = startCtrl.text.trim();
    final end = endCtrl.text.trim();
    final query = queryCtrl.text.trim();

    final apiBase = dotenv.env['BACKEND_URL'] ?? "http://127.0.0.1:8000";
    final body = {"start": start, "end": end, "query": query};

    final res = await http.post(
      Uri.parse("$apiBase/route"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      List route = data["route"] ?? [];
      List includes = data["all_pois"] ?? [];

      setState(() {
        polylinePoints =
            route.map<LatLng>((c) => LatLng(c[0], c[1])).toList();

        startPoint = polylinePoints.isNotEmpty ? polylinePoints.first : null;
        endPoint = polylinePoints.isNotEmpty ? polylinePoints.last : null;

        placeMarkers = includes.map<Marker>((p) {
        final name = p["name"];
        final lat = p["lat"];
        final lon = p["lon"];

        return Marker(
          point: LatLng(lat, lon),
          width: 180,
          height: 70,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                constraints: const BoxConstraints(maxWidth: 160),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              const Icon(Icons.flag_circle,
                  color: Colors.deepOrange, size: 34),
            ],
          ),
        );
      }).toList();

      });

      if (polylinePoints.isNotEmpty) {
        mapController.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(polylinePoints),
          padding: const EdgeInsets.all(50),
        ));
      }
    }

    isRunning.value = false;
  }
}
