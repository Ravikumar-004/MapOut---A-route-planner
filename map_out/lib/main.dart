import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/app_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MapRerouteApp(),
    ),
  );
}

class MapRerouteApp extends StatelessWidget {
  const MapRerouteApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MapReroute Chatbot',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
