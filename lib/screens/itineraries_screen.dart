import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/itinerary.dart';
import '../services/api_service.dart';
import '../services/session.dart';

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
      setState(() => _error = 'Could not load itineraries.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openItineraryDialog({Itinerary? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final destinationsController = TextEditingController(text: existing?.destinations.join(', ') ?? '');
    final startController = TextEditingController(text: existing?.startDate ?? '');
    final endController = TextEditingController(text: existing?.endDate ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'New itinerary' : 'Edit itinerary'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: destinationsController,
                  decoration: const InputDecoration(labelText: 'Destinations (comma separated)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: startController,
                  decoration: const InputDecoration(labelText: 'Start date (YYYY-MM-DD)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: endController,
                  decoration: const InputDecoration(labelText: 'End date (YYYY-MM-DD)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, true);
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    final destinations = destinationsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete itinerary?'),
        content: Text('"${it.title}" will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share itinerary'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: "Friend or family member's email"),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email address';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(context, emailController.text.trim());
            },
            child: const Text('Share'),
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
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Mine'),
              Tab(text: 'Shared with me'),
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
                            OutlinedButton(onPressed: _load, child: const Text('Retry')),
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
    if (items.isEmpty) return const Center(child: Text('No itineraries yet. Tap + to create one.'));
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
                      IconButton(icon: const Icon(Icons.share_outlined), tooltip: 'Share', onPressed: () => onShare(it)),
                      IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: () => onEdit(it)),
                      IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete', onPressed: () => onDelete(it)),
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
    if (items.isEmpty) return const Center(child: Text('No itineraries have been shared with you yet.'));
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
              subtitle: Text('${it.destinations.join(", ")}\n${it.startDate} → ${it.endDate}\nShared by ${it.email}'),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
