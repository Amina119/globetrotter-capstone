import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/cameroon_colors.dart';
import '../theme/locale_controller.dart';
import '../theme/theme_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _availableTags = ['city', 'culture', 'food', 'nature', 'adventure'];

  final _nameController = TextEditingController();
  final Set<String> _selectedTags = {};

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  ApiService _api() => ApiService(token: context.read<Session>().token);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _api().getProfile();
      _nameController.text = (profile['name'] as String?) ?? '';
      _selectedTags
        ..clear()
        ..addAll((profile['preferences'] as List).map((e) => e.toString()));
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      if (!mounted) return;
      _error = AppLocalizations.of(context)!.loadingProfileError;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.nameRequired)));
      return;
    }

    setState(() => _saving = true);
    try {
      await _api().updateProfile(name: name, preferences: _selectedTags.toList());
      if (!mounted) return;
      // Updates Session immediately, so every screen watching it (app bar
      // greeting, etc.) reflects the change right away — no re-login needed.
      await context.read<Session>().updateProfile(name: name, preferences: _selectedTags.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.profileUpdated)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: Text(AppLocalizations.of(context)!.retry)),
          ],
        ),
      );
    }

    final session = context.watch<Session>();
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: CameroonColors.heroGradient),
            child: Center(
              child: Text(
                (session.name?.isNotEmpty == true ? session.name![0] : session.email?[0] ?? '?').toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Text(session.email ?? '', style: Theme.of(context).textTheme.bodyMedium)),
        const SizedBox(height: 24),
        Text(l10n.profileName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 24),
        Text(l10n.travelPreferences, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          l10n.profilePreferencesHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
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
              labelStyle: TextStyle(color: selected ? Colors.white : null),
              onSelected: (v) => setState(() => v ? _selectedTags.add(tag) : _selectedTags.remove(tag)),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined),
          label: Text(l10n.profileSaveChanges),
        ),
        const Divider(height: 48),
        Text(l10n.profileAppearance, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const _ThemeModePicker(),
        const SizedBox(height: 24),
        Text('Language / Langue', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const _LanguagePicker(),
      ],
    );
  }
}

class _ThemeModePicker extends StatelessWidget {
  const _ThemeModePicker();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight), icon: const Icon(Icons.light_mode_outlined)),
        ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark), icon: const Icon(Icons.dark_mode_outlined)),
        ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem), icon: const Icon(Icons.brightness_auto_outlined)),
      ],
      selected: {controller.mode},
      onSelectionChanged: (selection) => context.read<ThemeController>().setMode(selection.first),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    final current = controller.locale?.languageCode ?? 'system';
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'en', label: Text('English')),
        ButtonSegment(value: 'fr', label: Text('Français')),
        ButtonSegment(value: 'system', label: Text('Auto')),
      ],
      selected: {current},
      onSelectionChanged: (selection) {
        final value = selection.first;
        context.read<LocaleController>().setLocale(value == 'system' ? null : Locale(value));
      },
    );
  }
}
