// lib/services/tomtom_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
class TomTomService{
  final String key=dotenv.env['TOMTOM_API_KEY'] ?? '';
  Future<Map<String,double>?> geocode(String q) async{
    final url=Uri.parse('https://api.tomtom.com/search/2/geocode/${Uri.encodeComponent(q)}.json?limit=1&key=$key');
    final r=await http.get(url);
    if(r.statusCode!=200) return null;
    final j=json.decode(r.body);
    if(j['results']!=null && j['results'].isNotEmpty){
      final pos=j['results'][0]['position'];
      return {'lat':pos['lat'].toDouble(),'lon':pos['lon'].toDouble()};
    }
    return null;
  }
  Future<List<Map<String,double>>?> calculateRoute({required double startLat,required double startLon,required double endLat,required double endLon, List<String>? avoids}) async{
    final start='$startLat,$startLon';
    final end='$endLat,$endLon';
    final buffer=StringBuffer();
    if(avoids!=null && avoids.isNotEmpty){
      for(final a in avoids){
        buffer.write('&avoid=${Uri.encodeComponent(a)}');
      }
    }
    final url=Uri.parse('https://api.tomtom.com/routing/1/calculateRoute/$start:$end/json?routeRepresentation=polyline${buffer.toString()}&key=$key');
    final r=await http.get(url);
    if(r.statusCode!=200) return null;
    final j=json.decode(r.body);
    if(j['routes']!=null && j['routes'].isNotEmpty){
      final points=j['routes'][0]['legs'][0]['points'] ?? j['routes'][0]['points'];
      if(points==null) return null;
      final List<Map<String,double>> list=[];
      for(final p in points){
        list.add({'lat':(p['latitude'] as num).toDouble(),'lon':(p['longitude'] as num).toDouble()});
      }
      return list;
    }
    return null;
  }
}
