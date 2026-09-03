import 'package:flutter/material.dart';

import 'stub.dart';

/// Mobile/desktop: a plain button whose tap calls [onPressed], which should
/// trigger GoogleSignIn().signIn() — that call reliably returns a real ID
/// token on these platforms (unlike on web).
Widget buildGoogleSignInButton({HandleSignInFn? onPressed, required String label}) {
  return OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.g_mobiledata, size: 28),
    label: Text(label),
  );
}
