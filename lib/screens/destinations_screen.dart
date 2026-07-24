import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/destination.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../widgets/destination_card.dart';

class DestinationsScreen extends StatefulWidget {
  final String initialQuery;

  const DestinationsScreen({super.key, this.initialQuery = ''});

  @override
  State<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends State<DestinationsScreen> {
  late final _searchController = TextEditingController(text: widget.initialQuery);
  List<Destination> _results = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = context.read<Session>().token;
      final api = ApiService(token: token);
      final data = await api.searchDestinations(q: _searchController.text.trim());
      setState(() => _results = data.map((e) => Destination.fromJson(e)).toList());
    } catch (e) {
      setState(() => _error = 'Could not load destinations.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search destinations (name, country, description)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _search),
            ),
            onSubmitted: (_) => _search(),
          ),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? const Center(child: Text('No destinations found.'))
                  : RefreshIndicator(
                      onRefresh: _search,
                      child: ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, i) => DestinationCard(destination: _results[i]),
                      ),
                    ),
        ),
      ],
    );
  }
}
