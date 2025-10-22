import 'dart:typed_data';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  Uint8List? uploadedImage;
  Uint8List? resultImage;
  List<String> directions = [];
  bool loading = false;
  String lastQuery = '';

  void setUploadedImage(Uint8List img) {
    uploadedImage = img;
    resultImage = null;
    directions = [];
    notifyListeners();
  }

  void setResult(Uint8List img, List<String> dirs) {
    resultImage = img;
    directions = dirs;
    loading = false;
    notifyListeners();
  }

  void setLoading(bool v) {
    loading = v;
    notifyListeners();
  }

  void setLastQuery(String q) {
    lastQuery = q;
  }

  void clear() {
    uploadedImage = null;
    resultImage = null;
    directions = [];
    lastQuery = '';
    loading = false;
    notifyListeners();
  }
}
