import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/cameroon_colors.dart';

/// Lets users rate GlobeTrotter (1-5 stars) and leave a comment, and shows
/// what every other user has actually submitted — the average is computed
/// live from real entries, not a hardcoded number.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  double? _average;
  int _count = 0;
  List<Map<String, dynamic>> _entries = [];
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
      final data = await _api().getFeedback();
      setState(() {
        _average = (data['average'] as num?)?.toDouble();
        _count = (data['count'] as num?)?.toInt() ?? 0;
        _entries = (data['entries'] as List).cast<Map<String, dynamic>>();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!.loadingFeedbackError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSubmitDialog({Map<String, dynamic>? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    var rating = (existing?['rating'] as num?)?.toInt() ?? 5;
    final commentController = TextEditingController(text: existing?['comment'] as String? ?? '');

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? l10n.feedbackRateApp : l10n.feedbackUpdateRating),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starValue = i + 1;
                  return IconButton(
                    onPressed: () => setDialogState(() => rating = starValue),
                    icon: Icon(
                      starValue <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: CameroonColors.gold,
                      size: 32,
                    ),
                  );
                }),
              ),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.feedbackComment,
                  hintText: l10n.feedbackCommentHint,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.feedbackCancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.feedbackSubmit)),
          ],
        ),
      ),
    );

    if (submitted != true) return;

    try {
      await _api().submitFeedback(rating: rating, comment: commentController.text.trim());
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteOwn() async {
    try {
      await _api().deleteFeedback();
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<Session>().email;
    final myEntry = _entries.where((e) => e['email'] == email).firstOrNull;
    final l10n = AppLocalizations.of(context)!;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: Text(l10n.retry)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AverageCard(average: _average, count: _count),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _openSubmitDialog(existing: myEntry),
            icon: Icon(myEntry == null ? Icons.star_outline_rounded : Icons.edit_outlined),
            label: Text(myEntry == null ? l10n.feedbackRateApp : l10n.feedbackUpdateRating),
          ),
          if (myEntry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _deleteOwn,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: Text(l10n.feedbackRemoveMine, style: const TextStyle(color: Colors.red)),
            ),
          ],
          const SizedBox(height: 20),
          Text(l10n.feedbackWhatPeopleSaying, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(l10n.feedbackNoneYet)),
            )
          else
            ..._entries.map((e) => _FeedbackTile(entry: e, isMine: e['email'] == email)),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _AverageCard extends StatelessWidget {
  final double? average;
  final int count;

  const _AverageCard({required this.average, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: CameroonColors.heroGradient, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Text(
            average != null ? average!.toStringAsFixed(1) : '—',
            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (i) {
                    final filled = average != null && i < average!.round();
                    return Icon(filled ? Icons.star_rounded : Icons.star_border_rounded, color: CameroonColors.gold, size: 20);
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  count == 0 ? 'No ratings yet' : 'Based on $count real ${count == 1 ? 'rating' : 'ratings'}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isMine;

  const _FeedbackTile({required this.entry, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final rating = (entry['rating'] as num?)?.toInt() ?? 0;
    final comment = entry['comment'] as String? ?? '';
    final name = entry['name'] as String? ?? AppLocalizations.of(context)!.aTraveler;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isMine ? '$name (you)' : name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 16,
                      color: CameroonColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(comment, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
