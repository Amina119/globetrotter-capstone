import 'dart:typed_data';

import 'stub.dart' if (dart.library.html) 'web.dart' if (dart.library.io) 'mobile.dart' as impl;

/// Saves [bytes] as a file named [filename] to the user's device
/// (browser download on web, photo gallery on mobile).
Future<void> downloadAsset(Uint8List bytes, String filename) => impl.downloadAsset(bytes, filename);
