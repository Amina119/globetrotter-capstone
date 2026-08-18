import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_places.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/itinerary.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/cameroon_colors.dart';

class ItinerariesScreen extends StatefulWidget {
  const ItinerariesScreen({super.key});

  @override
  State<ItinerariesScreen> createState() => _ItinerariesScreenState();
}

class _ItinerariesScreenState extends State<ItinerariesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  List<Itinerary> _mine = [];
  List<Itinerary> _shared = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ApiService _api() => ApiService(token: context.read<Session>().token);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final mine = await _api().getItineraries();
      final shared = await _api().getSharedItineraries();
      setState(() {
        _mine = mine.map((e) => Itinerary.fromJson(e)).toList();
        _shared = shared.map((e) => Itinerary.fromJson(e)).toList();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!.couldNotLoadItineraries);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openItineraryDialog({Itinerary? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final startController = TextEditingController(text: existing?.startDate ?? '');
    final endController = TextEditingController(text: existing?.endDate ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final selectedDestinations = <String>{...?existing?.destinations};
    final formKey = GlobalKey<FormState>();
    String? destinationsError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? l10n.itinNew : l10n.itinEdit),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: l10n.titleField),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.required : null,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.itinPlacesToVisit, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (destinationsError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(destinationsError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: allNkolmbongPlaces.map((place) {
                          final selected = selectedDestinations.contains(place.name);
                          return FilterChip(
                            label: Text(place.name),
                            selected: selected,
                            showCheckmark: false,
                            selectedColor: CameroonColors.green,
                            labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontSize: 12.5),
                            onSelected: (v) => setDialogState(() {
                              if (v) {
                                selectedDestinations.add(place.name);
                              } else {
                                selectedDestinations.remove(place.name);
                              }
                              destinationsError = null;
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: startController,
                    decoration: InputDecoration(labelText: l10n.startDateField),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.required : null,
                  ),
                  TextFormField(
                    controller: endController,
                    decoration: InputDecoration(labelText: l10n.endDateField),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.required : null,
                  ),
                  TextFormField(
                    controller: notesController,
                    decoration: InputDecoration(labelText: l10n.notesOptional),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () {
                final formValid = formKey.currentState!.validate();
                if (selectedDestinations.isEmpty) {
                  setDialogState(() => destinationsError = l10n.itinSelectAtLeastOne);
                  return;
                }
                if (formValid) Navigator.pop(context, true);
              },
              child: Text(existing == null ? l10n.create : l10n.save),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final destinations = selectedDestinations.toList();

    try {
      if (existing == null) {
        await _api().createItinerary(
          title: titleController.text.trim(),
          destinations: destinations,
          startDate: startController.text.trim(),
          endDate: endController.text.trim(),
          notes: notesController.text.trim(),
        );
      } else {
        await _api().updateItinerary(
          existing.id,
          title: titleController.text.trim(),
          destinations: destinations,
          startDate: startController.text.trim(),
          endDate: endController.text.trim(),
          notes: notesController.text.trim(),
        );
      }
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmDelete(Itinerary it) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.itinDeleteTitle),
        content: Text(l10n.itinDeleteBody(it.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api().deleteItinerary(it.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openShareDialog(Itinerary it) async {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.itinShareTitle),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: l10n.itinShareEmailLabel),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.emailRequired;
              if (!v.contains('@')) return l10n.emailInvalid;
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, emailController.text.trim());
            },
            child: Text(l10n.itinShare),
          ),
        ],
      ),
    );
    if (email == null) return;

    try {
      await _api().shareItinerary(it.id, email);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _unshare(Itinerary it, String email) async {
    try {
      await _api().unshareItinerary(it.id, email);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.itinTabMine),
              Tab(text: l10n.itinTabShared),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                            OutlinedButton(onPressed: _load, child: Text(l10n.retry)),
                          ],
                        ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _MineList(
                            items: _mine,
                            onRefresh: _load,
                            onEdit: (it) => _openItineraryDialog(existing: it),
                            onDelete: _confirmDelete,
                            onShare: _openShareDialog,
                            onUnshare: _unshare,
                          ),
                          _SharedList(items: _shared, onRefresh: _load),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openItineraryDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MineList extends StatelessWidget {
  final List<Itinerary> items;
  final Future<void> Function() onRefresh;
  final void Function(Itinerary) onEdit;
  final void Function(Itinerary) onDelete;
  final void Function(Itinerary) onShare;
  final void Function(Itinerary, String) onUnshare;

  const _MineList({
    required this.items,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    required this.onUnshare,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) return Center(child: Text(l10n.itinNoneMine));
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final it = items[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('${it.destinations.join(", ")}\n${it.startDate} → ${it.endDate}'),
                  if (it.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(it.notes, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                  ],
                  if (it.sharedWith.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: it.sharedWith
                          .map((email) => Chip(
                                label: Text(email, style: const TextStyle(fontSize: 12)),
                                visualDensity: VisualDensity.compact,
                                onDeleted: () => onUnshare(it, email),
                              ))
                          .toList(),
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(icon: const Icon(Icons.share_outlined), tooltip: l10n.itinShareTooltip, onPressed: () => onShare(it)),
                      IconButton(icon: const Icon(Icons.edit_outlined), tooltip: l10n.itinEditTooltip, onPressed: () => onEdit(it)),
                      IconButton(icon: const Icon(Icons.delete_outline), tooltip: l10n.itinDeleteTooltip, onPressed: () => onDelete(it)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SharedList extends StatelessWidget {
  final List<Itinerary> items;
  final Future<void> Function() onRefresh;

  const _SharedList({required this.items, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) return Center(child: Text(l10n.itinNoneShared));
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final it = items[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.card_travel),
              title: Text(it.title),
              subtitle: Text('${it.destinations.join(", ")}\n${it.startDate} → ${it.endDate}\n${l10n.itinSharedBy(it.email)}'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
