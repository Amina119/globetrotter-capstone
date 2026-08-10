import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/cameroon_colors.dart';

const LatLng _defaultCenter = LatLng(3.8480, 11.5021);

/// Lets an admin add/edit/delete destinations in the catalogue, including
/// pinning their position on the map (tap the mini-map to set a point).
class AdminDestinationsScreen extends StatefulWidget {
  const AdminDestinationsScreen({super.key});

  @override
  State<AdminDestinationsScreen> createState() => _AdminDestinationsScreenState();
}

class _AdminDestinationsScreenState extends State<AdminDestinationsScreen> {
  List<Destination> _destinations = [];
  bool _loading = true;
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
      final data = await _api().searchDestinations();
      setState(() => _destinations = data.map((e) => Destination.fromJson(e)).toList());
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not load destinations.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor({Destination? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _DestinationEditorSheet(api: _api(), existing: existing),
    );
    if (saved == true) await _load();
  }

  Future<void> _confirmDelete(Destination destination) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete destination?'),
        content: Text('"${destination.name}" will be permanently removed from the catalogue.'),
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
      await _api().adminDeleteDestination(destination.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _destinations.isEmpty
                      ? const Center(child: Text('No destinations yet. Tap + to add one.'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _destinations.length,
                          itemBuilder: (context, i) {
                            final d = _destinations[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: Icon(
                                  d.hasPosition ? Icons.location_on : Icons.location_off,
                                  color: d.hasPosition ? CameroonColors.green : Colors.grey,
                                ),
                                title: Text(d.name),
                                subtitle: Text(
                                  [d.quarter, d.town].where((s) => s.isNotEmpty).join(', ') +
                                      (d.hasPosition ? '' : ' · no map position set'),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _openEditor(existing: d),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _confirmDelete(d),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DestinationEditorSheet extends StatefulWidget {
  final ApiService api;
  final Destination? existing;

  const _DestinationEditorSheet({required this.api, this.existing});

  @override
  State<_DestinationEditorSheet> createState() => _DestinationEditorSheetState();
}

class _DestinationEditorSheetState extends State<_DestinationEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _townController;
  late final TextEditingController _quarterController;
  late final TextEditingController _sectorController;
  late final TextEditingController _tagsController;
  late final TextEditingController _costController;

  LatLng? _position;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _nameController = TextEditingController(text: d?.name ?? '');
    _townController = TextEditingController(text: d?.town ?? '');
    _quarterController = TextEditingController(text: d?.quarter ?? '');
    _sectorController = TextEditingController(text: d?.sector ?? '');
    _tagsController = TextEditingController(text: d?.tags.join(', ') ?? '');
    _costController = TextEditingController(text: d?.avgCostPerDay?.toString() ?? '');
    if (d != null && d.hasPosition) _position = LatLng(d.latitude!, d.longitude!);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _townController.dispose();
    _quarterController.dispose();
    _sectorController.dispose();
    _tagsController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final tags = _tagsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final cost = int.tryParse(_costController.text.trim());

    try {
      if (widget.existing == null) {
        await widget.api.adminCreateDestination(
          name: _nameController.text.trim(),
          town: _townController.text.trim(),
          quarter: _quarterController.text.trim(),
          sector: _sectorController.text.trim(),
          tags: tags,
          avgCostPerDay: cost,
          latitude: _position?.latitude,
          longitude: _position?.longitude,
        );
      } else {
        await widget.api.adminUpdateDestination(
          widget.existing!.id,
          name: _nameController.text.trim(),
          town: _townController.text.trim(),
          quarter: _quarterController.text.trim(),
          sector: _sectorController.text.trim(),
          tags: tags,
          avgCostPerDay: cost,
          latitude: _position?.latitude,
          longitude: _position?.longitude,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existing == null ? 'New destination' : 'Edit destination',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(controller: _townController, decoration: const InputDecoration(labelText: 'Town')),
                const SizedBox(height: 8),
                TextFormField(controller: _quarterController, decoration: const InputDecoration(labelText: 'Quarter')),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sectorController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Average cost per day (FCFA)'),
                ),
                const SizedBox(height: 16),
                Text('Map position', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Tap the map to place the pin.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 220,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _position ?? _defaultCenter,
                        initialZoom: 14,
                        onTap: (_, point) => setState(() => _position = point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.globetrotter.frontend',
                        ),
                        if (_position != null)
                          MarkerLayer(markers: [
                            Marker(
                              point: _position!,
                              width: 36,
                              height: 36,
                              child: const Icon(Icons.location_on, color: CameroonColors.red, size: 36),
                            ),
                          ]),
                      ],
                    ),
                  ),
                ),
                if (_position != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(widget.existing == null ? 'Create' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
