import 'dart:io';
import 'package:flutter/services.dart';

Future<Uint8List> fileToBytes(File f) async {
  return await f.readAsBytes();
}

Future<Uint8List> assetToBytes(String path) async {
  final data = await rootBundle.load(path);
  return data.buffer.asUint8List();
}
