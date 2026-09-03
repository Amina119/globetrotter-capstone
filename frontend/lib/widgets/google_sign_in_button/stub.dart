import 'package:flutter/material.dart';

/// The type of the onPressed callback for the (mobile) Sign In button —
/// ignored on web, where the click handler is owned by Google's own JS SDK.
typedef HandleSignInFn = Future<void> Function();

/// Fallback used only if neither the web nor mobile/desktop conditional
/// import matches (shouldn't happen in practice).
Widget buildGoogleSignInButton({HandleSignInFn? onPressed, required String label}) {
  return const SizedBox.shrink();
}
