import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/api_service.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/gradient_button.dart';
import 'login_screen.dart';

/// Second step of the forgot-password flow: enter the reset token (received
/// via [ForgotPasswordScreen]) together with a new password.
class ResetPasswordScreen extends StatefulWidget {
  final String resetToken;

  const ResetPasswordScreen({super.key, required this.resetToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _tokenController = TextEditingController(text: widget.resetToken);
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      await api.resetPassword(_tokenController.text.trim(), _passwordController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.passwordUpdatedSnack)),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthScaffold(
      heroIcon: Icons.lock_reset,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.resetTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              l10n.resetSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _tokenController,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.resetTokenLabel, prefixIcon: const Icon(Icons.vpn_key_outlined)),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.resetTokenRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.newPassword, prefixIcon: const Icon(Icons.lock_outline)),
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.newPasswordRequired;
                if (v.length < 6) return l10n.passwordMinLength;
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.confirmNewPassword, prefixIcon: const Icon(Icons.lock_outline)),
              validator: (v) {
                if (v != _passwordController.text) return l10n.passwordsDoNotMatch;
                return null;
              },
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
                  : Text(l10n.resetPasswordButton),
            ),
          ],
        ),
      ),
    );
  }
}
