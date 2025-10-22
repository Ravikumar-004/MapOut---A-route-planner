import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class ResultView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              color: Colors.indigo.shade600,
            ),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Rerouted Map', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (appState.loading) const CircularProgressIndicator(color: Colors.white) else const SizedBox.shrink()
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: appState.resultImage != null
                  ? InteractiveViewer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(appState.resultImage!, fit: BoxFit.contain),
                      ),
                    )
                  : appState.uploadedImage != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(appState.uploadedImage!, height: 300)),
                            const SizedBox(height: 12),
                            const Text('No reroute yet. Press Reroute to send request.')
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text('Upload a Google Maps screenshot to start')
                          ],
                        ),
            ),
          ),
          if (appState.directions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                color: Colors.grey[50],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Turn-by-turn (approximate)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      itemCount: appState.directions.length,
                      itemBuilder: (context, index) {
                        final d = appState.directions[index];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(radius: 14, child: Text('${index+1}', style: const TextStyle(fontSize: 12))),
                          title: Text(d),
                        );
                      },
                    ),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }
}
