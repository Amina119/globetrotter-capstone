import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/api_service.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/gradient_button.dart';
import 'reset_password_screen.dart';

/// First step of the forgot-password flow: request a reset token for an
/// email address.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
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
      final email = _emailController.text.trim();
      await api.forgotPassword(email);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: email, resetToken: '')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      debugPrint('forgot-password request failed: $e');
      setState(() => _error = 'Could not reach the server. Is the API running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AuthScaffold(
      heroIcon: Icons.lock_outline,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.forgotTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              l10n.forgotSubtitle,
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            GradientButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(l10n.sendResetToken),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: Text(l10n.backToLogin),
            ),
          ],
        ),
      ),
    );
  }
}
