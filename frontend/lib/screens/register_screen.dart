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
import 'login_screen.dart' show googleClientId;
import 'welcome_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const _availableTags = ['city', 'culture', 'food', 'nature', 'adventure'];
  final Set<String> _selectedTags = {};

  bool _loading = false;
  String? _error;

  // See login_screen.dart's identical setup for why a single shared
  // GoogleSignIn instance + onCurrentUserChanged listener is required
  // (rather than awaiting signIn() directly) to get a real ID token on web.
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
      // The backend's /auth/google route auto-registers a brand-new account
      // on first sign-in, so this is the same call used for logging in —
      // there's no separate "register with Google" endpoint needed.
      final (token, name, isAdmin) = await api.loginWithGoogle(idToken);
      if (!mounted) return;
      await context.read<Session>().login(email: account.email, token: token, name: name, isAdmin: isAdmin);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => WelcomeScreen(name: name)),
        (route) => false,
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
      final password = _passwordController.text;
      await api.register(_nameController.text.trim(), email, password, _selectedTags.toList());
      final (token, name, isAdmin) = await api.login(email, password);
      if (!mounted) return;
      await context.read<Session>().login(
            email: email,
            token: token,
            name: name,
            isAdmin: isAdmin,
            preferences: _selectedTags.toList(),
          );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => WelcomeScreen(name: name)),
        (route) => false,
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
      heroIcon: Icons.person_add_alt_1,
      maxWidth: 460,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.registerTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              l10n.registerSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.fullName, prefixIcon: const Icon(Icons.person_outline)),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.nameRequired : null,
            ),
            const SizedBox(height: 12),
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
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.password, prefixIcon: const Icon(Icons.lock_outline)),
              validator: (v) => (v == null || v.length < 4) ? l10n.passwordTooShort : null,
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.travelPreferences, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _availableTags.map((tag) {
                final selected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: CameroonColors.green,
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                  onSelected: (v) => setState(() => v ? _selectedTags.add(tag) : _selectedTags.remove(tag)),
                );
              }).toList(),
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
                  : Text(l10n.createAccount),
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
            const SizedBox(height: 4),
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.alreadyHaveAccount),
            ),
          ],
        ),
      ),
    );
  }
}
