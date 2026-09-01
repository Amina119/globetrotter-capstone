import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/destination.dart';
import '../models/local_place.dart';
import '../models/place_comment.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/cameroon_colors.dart';
import '../widgets/place_media.dart';
import 'place_map_screen.dart';

/// Full-screen detail view for a single place: photo, description, the
/// minimum amount needed to spend time there, and everyone's ratings/
/// comments on it (real, shared across users — not just the current one).
class PlaceDetailScreen extends StatefulWidget {
  final LocalPlace place;
  final IconData icon;
  final Color accent;

  const PlaceDetailScreen({super.key, required this.place, required this.icon, required this.accent});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  double? _average;
  int _count = 0;
  List<Map<String, dynamic>> _entries = [];
  bool _loadingReviews = true;

  /// Places (the curated list with photos/videos) don't carry coordinates
  /// themselves — those live in the backend's admin-managed destination
  /// catalogue, keyed by the same id. Null until checked, or if the place
  /// isn't in the catalogue at all.
  Destination? _matchedDestination;

  List<PlaceComment> _comments = [];
  bool _loadingComments = true;
  final _newCommentController = TextEditingController();
  final _replyController = TextEditingController();
  String? _replyingToId;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadPlacePosition();
    _loadComments();
  }

  @override
  void dispose() {
    _newCommentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  ApiService _api() => ApiService(token: context.read<Session>().token);

  List<PlaceComment> get _topLevelComments => _comments.where((c) => c.parentId == null).toList();

  List<PlaceComment> _repliesTo(String commentId) => _comments.where((c) => c.parentId == commentId).toList();

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    try {
      final data = await _api().getPlaceComments(widget.place.id);
      setState(() => _comments = data.map((e) => PlaceComment.fromJson(e as Map<String, dynamic>)).toList());
    } catch (_) {
      // Comments are a bonus on top of the place's own details — a failure
      // here shouldn't block the rest of the page from showing.
    } finally {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _postComment({String? parentId, required String text}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      await _api().postPlaceComment(widget.place.id, text: trimmed, parentId: parentId);
      await _loadComments();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _api().deletePlaceComment(widget.place.id, commentId);
      await _loadComments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.commentDeletedMessage)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  bool get _hasMapPosition => _matchedDestination?.hasPosition ?? false;

  Future<void> _loadPlacePosition() async {
    try {
      final data = await _api().searchDestinations();
      final match = data
          .map((e) => Destination.fromJson(e as Map<String, dynamic>))
          .where((d) => d.id == widget.place.id)
          .firstOrNull;
      if (mounted) setState(() => _matchedDestination = match);
    } catch (_) {
      // The "show on map" button just won't appear — not worth surfacing
      // an error for a bonus feature on top of the place's own details.
    }
  }

  void _showOnMap() {
    final match = _matchedDestination;
    if (match == null || !match.hasPosition) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaceMapScreen(
          placeName: widget.place.name,
          latitude: match.latitude!,
          longitude: match.longitude!,
        ),
      ),
    );
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final data = await _api().getPlaceReviews(widget.place.id);
      setState(() {
        _average = (data['average'] as num?)?.toDouble();
        _count = (data['count'] as num?)?.toInt() ?? 0;
        _entries = (data['entries'] as List).cast<Map<String, dynamic>>();
      });
    } catch (_) {
      // Reviews are a bonus on top of the place's own details — a failure
      // here shouldn't block the rest of the page from showing.
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  Future<void> _openReviewDialog({Map<String, dynamic>? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    var rating = (existing?['rating'] as num?)?.toInt() ?? 5;
    final commentController = TextEditingController(text: existing?['comment'] as String? ?? '');

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? l10n.rateXTitle(widget.place.name) : l10n.updateYourReview),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
                decoration: InputDecoration(labelText: l10n.feedbackComment),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.feedbackSubmit)),
          ],
        ),
      ),
    );

    if (submitted != true) return;

    try {
      await _api().submitPlaceReview(widget.place.id, rating: rating, comment: commentController.text.trim());
      await _loadReviews();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteOwnReview() async {
    try {
      await _api().deletePlaceReview(widget.place.id);
      await _loadReviews();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final icon = widget.icon;
    final accent = widget.accent;
    final email = context.watch<Session>().email;
    final myReview = _entries.where((e) => e['email'] == email).firstOrNull;
    final displayRating = _average ?? place.rating;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: accent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, right: 16, bottom: 14),
              title: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 8, color: Colors.black45)]),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PlaceMedia(videoAsset: place.videoAsset, imageAsset: place.imageAsset, icon: icon, color: accent, placeName: place.name),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black45],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Chip(icon: Icons.category_outlined, label: place.category, color: accent),
                      _Chip(
                        icon: Icons.star_rounded,
                        label: '${displayRating.toStringAsFixed(1)}${_count > 0 ? ' ($_count)' : ''}',
                        color: CameroonColors.gold,
                        dark: true,
                      ),
                    ],
                  ),
                  if (_hasMapPosition) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showOnMap,
                        icon: const Icon(Icons.map_outlined),
                        label: Text(l10n.showOnMap),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    l10n.aboutThisPlace,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.description ?? l10n.noDescriptionYet,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [CameroonColors.greenDark, CameroonColors.green],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: CameroonColors.gold,
                          child: Icon(Icons.payments_outlined, color: CameroonColors.greenDark),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.minAmountToBeThere, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                place.priceTier,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.reviewsLabel,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openReviewDialog(existing: myReview),
                        icon: Icon(myReview == null ? Icons.star_outline_rounded : Icons.edit_outlined),
                        label: Text(myReview == null ? l10n.rateThisPlace : l10n.editYourReview),
                      ),
                    ],
                  ),
                  if (myReview != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _deleteOwnReview,
                        child: Text(l10n.removeMyReview, style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  if (_loadingReviews)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l10n.noReviewsYet),
                    )
                  else
                    ..._entries.map((e) => _ReviewTile(entry: e, isMine: e['email'] == email)),
                  const SizedBox(height: 32),
                  Text(
                    l10n.commentsLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newCommentController,
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(hintText: l10n.writeACommentHint),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send_rounded),
                        onPressed: () {
                          _postComment(text: _newCommentController.text);
                          _newCommentController.clear();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loadingComments)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_topLevelComments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l10n.noCommentsYet),
                    )
                  else
                    ..._topLevelComments.map(
                      (c) => _CommentThread(
                        comment: c,
                        replies: _repliesTo(c.id),
                        currentEmail: email,
                        replyingToId: _replyingToId,
                        replyController: _replyController,
                        onReplyTap: (id) => setState(() => _replyingToId = _replyingToId == id ? null : id),
                        onSubmitReply: (parentId, text) {
                          _postComment(parentId: parentId, text: text);
                          _replyController.clear();
                          setState(() => _replyingToId = null);
                        },
                        onDelete: _deleteComment,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _ReviewTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isMine;

  const _ReviewTile({required this.entry, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final rating = (entry['rating'] as num?)?.toInt() ?? 0;
    final comment = entry['comment'] as String? ?? '';
    final name = entry['name'] as String? ?? AppLocalizations.of(context)!.aTraveler;

    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(isMine ? '$name (you)' : name, style: const TextStyle(fontWeight: FontWeight.bold))),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(i < rating ? Icons.star_rounded : Icons.star_border_rounded, size: 15, color: CameroonColors.gold),
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

/// One top-level comment plus its direct replies (rendered indented, one
/// level deep — a reply to a reply still attaches to the same top-level
/// thread rather than nesting further, to keep the thread readable).
class _CommentThread extends StatelessWidget {
  final PlaceComment comment;
  final List<PlaceComment> replies;
  final String? currentEmail;
  final String? replyingToId;
  final TextEditingController replyController;
  final void Function(String commentId) onReplyTap;
  final void Function(String parentId, String text) onSubmitReply;
  final void Function(String commentId) onDelete;

  const _CommentThread({
    required this.comment,
    required this.replies,
    required this.currentEmail,
    required this.replyingToId,
    required this.replyController,
    required this.onReplyTap,
    required this.onSubmitReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentTile(
            comment: comment,
            isMine: comment.email == currentEmail,
            onReply: () => onReplyTap(comment.id),
            onDelete: () => onDelete(comment.id),
          ),
          for (final reply in replies)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 8),
              child: _CommentTile(
                comment: reply,
                isMine: reply.email == currentEmail,
                onReply: () => onReplyTap(comment.id),
                onDelete: () => onDelete(reply.id),
              ),
            ),
          if (replyingToId == comment.id)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: replyController,
                      autofocus: true,
                      decoration: InputDecoration(hintText: l10n.writeAReplyHint),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, size: 20),
                    onPressed: () => onSubmitReply(comment.id, replyController.text),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final PlaceComment comment;
  final bool isMine;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _CommentTile({required this.comment, required this.isMine, required this.onReply, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDeleted = comment.text == '[deleted]';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMine ? '${comment.name} (you)' : comment.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            isDeleted ? l10n.deletedCommentPlaceholder : comment.text,
            style: TextStyle(
              fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
              color: isDeleted ? Colors.black45 : null,
            ),
          ),
          if (!isDeleted)
            Row(
              children: [
                TextButton(onPressed: onReply, child: Text(l10n.replyAction, style: const TextStyle(fontSize: 12))),
                if (isMine)
                  TextButton(
                    onPressed: onDelete,
                    child: Text(l10n.deleteAction, style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool dark;

  const _Chip({required this.icon, required this.label, required this.color, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: dark ? Colors.amber.shade800 : color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: dark ? Colors.amber.shade800 : color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
