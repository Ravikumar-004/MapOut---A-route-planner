import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  final String baseUrl;
  ApiService({required this.baseUrl});

  Future<Map<String, dynamic>> sendImageAndQuery(Uint8List imageBytes, String filename, String query) async {
    final uri = Uri.parse('$baseUrl/reroute');
    final request = http.MultipartRequest('POST', uri);
    final mimeType = lookupMimeType(filename, headerBytes: imageBytes) ?? 'image/png';
    final parts = mimeType.split('/');
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
        contentType: MediaType(parts[0], parts[1]),
      ),
    );
    request.fields['query'] = query;
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      throw Exception('Server error: ${res.statusCode}');
    }
    final map = json.decode(res.body) as Map<String, dynamic>;
    return map;
  }

  Future<Uint8List> fetchImageFromBase64(String b64) async {
    return base64Decode(b64);
  }
}
