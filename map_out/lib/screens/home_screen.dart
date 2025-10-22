import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../widgets/result_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _queryController = TextEditingController();
  late ApiService api;

  @override
  void initState() {
    super.initState();
    api = ApiService(baseUrl: 'http://127.0.0.1:5000/api');
  }

  Future<void> pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, maxHeight: 1600, maxWidth: 1600, imageQuality: 85);
    if (file == null) return;
    final data = await file.readAsBytes();
    Provider.of<AppState>(context, listen: false).setUploadedImage(data);
  }

  Future<void> takePhoto() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera, maxHeight: 1600, maxWidth: 1600, imageQuality: 85);
    if (file == null) return;
    final data = await file.readAsBytes();
    Provider.of<AppState>(context, listen: false).setUploadedImage(data);
  }

  Future<void> submit() async {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.uploadedImage == null) return;
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    appState.setLastQuery(query);
    appState.setLoading(true);
    try {
      final resp = await api.sendImageAndQuery(appState.uploadedImage!, 'upload.png', query);
      final imgBytes = await api.fetchImageFromBase64(resp['image_base64'] ?? '');
      final dirs = List<String>.from(resp['directions'] ?? []);
      appState.setResult(imgBytes, dirs);
    } catch (e) {
      appState.setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('MapReroute Chatbot'),
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => appState.clear(),
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            Flexible(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                        ),
                        child: appState.uploadedImage == null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.photo, size: 48, color: Colors.indigoAccent),
                                    const SizedBox(height: 8),
                                    const Text('Tap to select image', style: TextStyle(fontSize: 16)),
                                    const SizedBox(height: 6),
                                    TextButton.icon(
                                      onPressed: takePhoto,
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Or take photo'),
                                    )
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(appState.uploadedImage!, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _queryController,
                      decoration: InputDecoration(
                        hintText: 'Enter disruption query (e.g., Avoid RK Beach)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.edit_location),
                      ),
                      minLines: 1,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: appState.loading ? null : submit,
                            icon: const Icon(Icons.alt_route),
                            label: appState.loading ? const Text('Processing...') : const Text('Reroute'),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Query History', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            if (appState.lastQuery.isEmpty)
                              const Text('No queries yet')
                            else
                              Text(appState.lastQuery),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Status', style: TextStyle(color: Colors.grey[600])),
                                if (appState.loading) const Text('Working...', style: TextStyle(color: Colors.orange)) else const Text('Idle'),
                              ],
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right:16.0, top:16, bottom:16),
                child: ResultView(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
