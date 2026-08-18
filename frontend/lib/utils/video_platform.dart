import 'package:flutter/foundation.dart';

/// The video_player package has no Windows/Linux desktop implementation, so
/// those platforms use media_kit_video instead. Shared by every widget that
/// plays a local video asset (login background, place media, ...).
bool get useMediaKitVideo =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux);
