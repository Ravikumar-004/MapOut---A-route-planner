import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
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
  Widget build(BuildContext c) => MaterialApp(debugShowCheckedModeBanner: false, home: HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final startCtrl = TextEditingController();
  final endCtrl = TextEditingController();
  final queryCtrl = TextEditingController();
  List<LatLng> polylinePoints = [];
  LatLng? startPoint;
  LatLng? endPoint;
  LatLng? currentLocation;
  final mapController = MapController();
  bool isPanelOpen = true;
  final ValueNotifier<bool> isRunning = ValueNotifier<bool>(false);

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

    // ignore: deprecated_member_use
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      currentLocation = LatLng(pos.latitude, pos.longitude);
    });
    mapController.move(currentLocation!, 14.0);
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: LatLng(20.29606, 85.82454),
            initialZoom: 13,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", subdomains: ['a', 'b', 'c']),
            if (polylinePoints.isNotEmpty)
              PolylineLayer(polylines: [
                Polyline(points: polylinePoints, color: Colors.blueAccent, strokeWidth: 5.5)
              ]),
            if (startPoint != null)
              MarkerLayer(markers: [
                Marker(
                    point: startPoint!,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_pin, color: Colors.green, size: 38))
              ]),
            if (endPoint != null)
              MarkerLayer(markers: [
                Marker(
                    point: endPoint!,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.flag, color: Colors.red, size: 36))
              ]),
            if (currentLocation != null)
              MarkerLayer(markers: [
                Marker(
                    point: currentLocation!,
                    width: 25,
                    height: 25,
                    child: const Icon(Icons.circle, color: Colors.blueAccent, size: 15))
              ])
          ],
        ),
        AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          left: isPanelOpen ? 0 : -280,
          top: 0,
          bottom: 0,
          width: 280,
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("MAPOUT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => setState(() => isPanelOpen = false))
              ]),
              SizedBox(height: 10),
              TextField(controller: startCtrl, decoration: InputDecoration(labelText: "Start point")),
              SizedBox(height: 10),
              TextField(controller: endCtrl, decoration: InputDecoration(labelText: "Destination")),
              SizedBox(height: 10),
              TextField(controller: queryCtrl, decoration: InputDecoration(labelText: "Avoid (optional)")),
              SizedBox(height: 20),
              ElevatedButton.icon(onPressed: _getRoute, icon: Icon(Icons.directions), label: Text("Get Route")),
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
                onPressed: () => setState(() => isPanelOpen = true),
                child: Icon(Icons.menu, color: Colors.black)),
          ),
        Positioned(
          bottom: 20,
          left: 20,
          child: ValueListenableBuilder<bool>(
            valueListenable: isRunning,
            builder: (context, running, _) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: running ? Colors.redAccent : Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  running ? "Backend: Running" : "Backend: Idle",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                if (currentLocation != null) mapController.move(currentLocation!, 14.0);
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
    final r = await http.post(Uri.parse("$apiBase/route"),
        headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body);
      List coords = data["coords"] ?? [];
      setState(() {
        polylinePoints = coords.map<LatLng>((c) => LatLng(c[0], c[1])).toList();
        startPoint = polylinePoints.isNotEmpty ? polylinePoints.first : null;
        endPoint = polylinePoints.isNotEmpty ? polylinePoints.last : null;
      });
      if (polylinePoints.isNotEmpty) {
        mapController.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(polylinePoints),
          padding: const EdgeInsets.all(50),
        ));
      }
    } else {
      setState(() {
        polylinePoints = [];
        startPoint = null;
        endPoint = null;
      });
    }
    isRunning.value = false;
  }
}
