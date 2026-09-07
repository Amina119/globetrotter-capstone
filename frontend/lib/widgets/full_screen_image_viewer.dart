import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../utils/download_asset/download_asset.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String assetPath;
  final String title;

  const FullScreenImageViewer({super.key, required this.assetPath, required this.title});

  Future<void> _download(BuildContext context) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      await downloadAsset(bytes, '$title.jpg');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image saved')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: () => _download(context)),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.asset(assetPath),
        ),
      ),
    );
  }
}
