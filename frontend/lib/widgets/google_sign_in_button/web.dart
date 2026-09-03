import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

import 'stub.dart';

/// Web: renders Google's own "Sign in with Google" button via the Identity
/// Services SDK. [onPressed] is ignored here — the click handler is owned
/// by Google's JS, and completion is observed instead via
/// GoogleSignIn().onCurrentUserChanged, same as the mobile path. This is the
/// only web flow that actually returns a real ID token; the imperative
/// GoogleSignIn().signIn() call only ever returns an access token on web.
Widget buildGoogleSignInButton({HandleSignInFn? onPressed, required String label}) {
  return web.renderButton();
}
