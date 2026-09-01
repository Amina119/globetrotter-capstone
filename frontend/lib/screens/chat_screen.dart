import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/session.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatMessage> _messages = [];
  bool _loading = true;
  final _newMessageController = TextEditingController();
  final _replyController = TextEditingController();
  String? _replyingToId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }



  @override
  void dispose() {
    _newMessageController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  ApiService _api() => ApiService(token: context.read<Session>().token);

  List<ChatMessage> _repliesTo(String messageId) => _messages.where((m) => m.parentId == messageId).toList();

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final data = await _api().getChatMessages();
      setState(() => _messages = data.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList());
    } catch (_) {
      // leave _messages as whatever it was before
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _postMessage({String? parentId, required String text}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      await _api().postChatMessage(text: trimmed, parentId: parentId);
      await _loadMessages();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _api().deleteChatMessage(messageId);
      await _loadMessages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.commentDeletedMessage)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

    @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final email = context.watch<Session>().email;
    final topLevel = _messages.where((m) => m.parentId == null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : topLevel.isEmpty
              ? Center(child: Text(l10n.noCommentsYet))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: topLevel.map((m) {
                                      return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MessageTile(
                          message: m,
                          isMine: m.email == email,
                          onReply: () => setState(() => _replyingToId = _replyingToId == m.id ? null : m.id),
                          onDelete: () => _deleteMessage(m.id),
                        ),
                        for (final reply in _repliesTo(m.id))
                          Padding(
                            padding: const EdgeInsets.only(left: 24, top: 4),
                            child: _MessageTile(
                              message: reply,
                              isMine: reply.email == email,
                              onReply: () => setState(() => _replyingToId = _replyingToId == m.id ? null : m.id),
                              onDelete: () => _deleteMessage(reply.id),
                            ),
                          ),
                        if (_replyingToId == m.id)
                          Padding(
                            padding: const EdgeInsets.only(left: 24, bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _replyController,
                                    autofocus: true,
                                    decoration: InputDecoration(hintText: l10n.writeAReplyHint),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send_rounded, size: 20),
                                  onPressed: () {
                                    _postMessage(parentId: m.id, text: _replyController.text);
                                    _replyController.clear();
                                    setState(() => _replyingToId = null);
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    );

                  }).toList(),
                   ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newMessageController,
                  decoration: InputDecoration(hintText: l10n.writeACommentHint),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded),
                onPressed: () {
                  _postMessage(text: _newMessageController.text);
                  _newMessageController.clear();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }



}

class _MessageTile extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _MessageTile({required this.message, required this.isMine, required this.onReply, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDeleted = message.text == '[deleted]';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMine ? Colors.green.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMine ? '${message.name} (you)' : message.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            isDeleted ? l10n.deletedCommentPlaceholder : message.text,
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



