import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> downloadAsset(Uint8List bytes, String filename) async {
  final status = await Permission.photos.request();
  if (!status.isGranted) {
    throw Exception('Photo permission denied');
  }
  await Gal.putImageBytes(bytes, name: filename);
}
