import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/cameroon_colors.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/gradient_button.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'welcome_screen.dart';

/// Google OAuth Web Client ID, from Google Cloud Console → Credentials.
///
/// Override at build/run time, e.g.:
///   flutter run -d chrome --dart-define=GOOGLE_CLIENT_ID=xxxx.apps.googleusercontent.com
const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  // A single shared GoogleSignIn instance: on web, the rendered "Sign in
  // with Google" button (see google_sign_in_button.dart) reports completion
  // through *this* instance's onCurrentUserChanged stream, not through a
  // return value — so the button and the listener must share one instance.
  late final GoogleSignIn _googleSignIn = GoogleSignIn(clientId: googleClientId);
  StreamSubscription<GoogleSignInAccount?>? _googleSub;
  bool _handlingGoogleAccount = false;

  @override
  void initState() {
    super.initState();
    if (googleClientId.isNotEmpty) {
      _googleSub = _googleSignIn.onCurrentUserChanged.listen(_onGoogleAccount);
    }
  }

  @override
  void dispose() {
    _googleSub?.cancel();
    super.dispose();
  }

  /// Fires once sign-in actually completes, on both platforms: on mobile
  /// this follows GoogleSignIn().signIn() being called from the button; on
  /// web it follows the user completing Google's own rendered button flow,
  /// which is the only web path that returns a real ID token (see
  /// google_sign_in_button/web.dart for why the imperative signIn() call
  /// can't be used for this on web).
  Future<void> _onGoogleAccount(GoogleSignInAccount? account) async {
    if (account == null || _handlingGoogleAccount) return;
    _handlingGoogleAccount = true;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        setState(() => _error = 'Google sign-in did not return a credential.');
        return;
      }

      final api = ApiService();
      final (token, name, isAdmin) = await api.loginWithGoogle(idToken);
      if (!mounted) return;
      await context.read<Session>().login(email: account.email, token: token, name: name, isAdmin: isAdmin);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WelcomeScreen(name: name)),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not sign in with Google.');
    } finally {
      _handlingGoogleAccount = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final email = _emailController.text.trim();
      final (token, name, isAdmin) = await api.login(email, _passwordController.text);
      if (!mounted) return;
      await context.read<Session>().login(email: email, token: token, name: name, isAdmin: isAdmin);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WelcomeScreen(name: name)),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not reach the server. Is the API running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthScaffold(
      heroIcon: Icons.flight_takeoff,
      heroVideoAsset: 'assets/videos/login_hero.mp4',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [CameroonColors.greenDark, CameroonColors.green],
              ).createShader(bounds),
              child: Text(
                l10n.loginWelcomeBack,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.loginSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.email_outlined)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.emailRequired;
                if (!v.contains('@')) return l10n.emailInvalid;
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? l10n.passwordRequired : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            GradientButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.logIn),
            ),
            if (googleClientId.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(l10n.or, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              buildGoogleSignInButton(
                onPressed: _loading ? null : () => _googleSignIn.signIn(),
                label: l10n.continueWithGoogle,
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
              child: Text(l10n.noAccountRegister),
            ),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      ),
              child: Text(l10n.forgotPassword),
            ),
          ],
        ),
      ),
    );
  }
}
