import 'package:audioplayers/audioplayers.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

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
  bool _sending = false;
  final _newMessageController = TextEditingController();
  final _replyController = TextEditingController();
  String? _replyingToId;

  // Which text field the emoji picker and attachment picker currently target:
  // null = the main composer, otherwise the id of the message being replied to.
  String? _activeFieldId;
  bool _showEmojiPicker = false;

  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _playingUrl;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingUrl = null);
    });
  }

  @override
  void dispose() {
    _newMessageController.dispose();
    _replyController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  ApiService _api() => ApiService(token: context.read<Session>().token);

  List<ChatMessage> _repliesTo(String messageId) => _messages.where((m) => m.parentId == messageId).toList();

  TextEditingController _controllerFor(String? fieldId) => fieldId == null ? _newMessageController : _replyController;

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

  Future<void> _postMessage({String? parentId, required String text, String? mediaUrl, String? mediaType}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && mediaUrl == null) return;
    setState(() => _sending = true);
    try {
      await _api().postChatMessage(text: trimmed, parentId: parentId, mediaUrl: mediaUrl, mediaType: mediaType);
      await _loadMessages();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
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

  void _toggleEmojiPicker(String? fieldId) {
    setState(() {
      if (_showEmojiPicker && _activeFieldId == fieldId) {
        _showEmojiPicker = false;
      } else {
        _activeFieldId = fieldId;
        _showEmojiPicker = true;
      }
    });
  }

  void _insertEmoji(Emoji emoji) {
    final controller = _controllerFor(_activeFieldId);
    final selection = controller.selection;
    final text = controller.text;
    final insertAt = selection.start >= 0 ? selection.start : text.length;
    final newText = text.replaceRange(insertAt, selection.end >= 0 ? selection.end : insertAt, emoji.emoji);
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: insertAt + emoji.emoji.length);
  }

  Future<void> _pickAndSendMedia({String? parentId, required ImageSource source, required bool isVideo}) async {
    final picker = ImagePicker();
    final XFile? file = isVideo
        ? await picker.pickVideo(source: source)
        : await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    await _uploadAndSend(parentId: parentId, file: file);
  }

  Future<void> _uploadAndSend({String? parentId, required XFile file}) async {
    setState(() => _sending = true);
    try {
      final bytes = await file.readAsBytes();
      final uploaded = await _api().uploadChatMedia(bytes: bytes, filename: file.name);
      await _postMessage(
        parentId: parentId,
        text: '',
        mediaUrl: uploaded['url'] as String,
        mediaType: uploaded['media_type'] as String,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startRecording() async {
    if (!await _audioRecorder.hasPermission()) return;
    await _audioRecorder.start(const RecordConfig(), path: 'chat_voice_note.m4a');
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecordingAndSend(String? parentId) async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path == null) return;
    await _uploadAndSend(parentId: parentId, file: XFile(path));
  }

  void _showAttachmentSheet(String? parentId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendMedia(parentId: parentId, source: ImageSource.gallery, isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendMedia(parentId: parentId, source: ImageSource.camera, isVideo: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendMedia(parentId: parentId, source: ImageSource.gallery, isVideo: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleVoicePlayback(String url) async {
    final resolved = _api().resolveMediaUrl(url);
    if (_playingUrl == url) {
      await _audioPlayer.stop();
      setState(() => _playingUrl = null);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(resolved));
      setState(() => _playingUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final email = context.watch<Session>().email;
    final topLevel = _messages.where((m) => m.parentId == null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : topLevel.isEmpty
                    ? Center(child: Text(l10n.noCommentsYet))
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: topLevel.map((m) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MessageBubble(
                                message: m,
                                isMine: m.email == email,
                                api: _api(),
                                playingUrl: _playingUrl,
                                onTogglePlay: _toggleVoicePlayback,
                                onReply: () => setState(() {
                                  _replyingToId = _replyingToId == m.id ? null : m.id;
                                  _showEmojiPicker = false;
                                }),
                                onDelete: () => _deleteMessage(m.id),
                              ),
                              for (final reply in _repliesTo(m.id))
                                Padding(
                                  padding: const EdgeInsets.only(left: 32, top: 4),
                                  child: _MessageBubble(
                                    message: reply,
                                    isMine: reply.email == email,
                                    api: _api(),
                                    playingUrl: _playingUrl,
                                    onTogglePlay: _toggleVoicePlayback,
                                    onReply: () => setState(() {
                                      _replyingToId = _replyingToId == m.id ? null : m.id;
                                      _showEmojiPicker = false;
                                    }),
                                    onDelete: () => _deleteMessage(reply.id),
                                  ),
                                ),
                              if (_replyingToId == m.id)
                                Padding(
                                  padding: const EdgeInsets.only(left: 32, bottom: 8),
                                  child: _Composer(
                                    controller: _replyController,
                                    hint: l10n.writeAReplyHint,
                                    sending: _sending,
                                    onSend: () {
                                      _postMessage(parentId: m.id, text: _replyController.text);
                                      _replyController.clear();
                                      setState(() => _replyingToId = null);
                                    },
                                    onAttach: () => _showAttachmentSheet(m.id),
                                    onToggleEmoji: () => _toggleEmojiPicker(m.id),
                                    isRecording: _isRecording,
                                    onStartRecording: _startRecording,
                                    onStopRecording: () => _stopRecordingAndSend(m.id),
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
          ),
          if (_showEmojiPicker)
            SizedBox(
              height: 280,
              child: EmojiPicker(onEmojiSelected: (category, emoji) => _insertEmoji(emoji)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _Composer(
                controller: _newMessageController,
                hint: l10n.writeACommentHint,
                sending: _sending,
                onSend: () {
                  _postMessage(text: _newMessageController.text);
                  _newMessageController.clear();
                },
                onAttach: () => _showAttachmentSheet(null),
                onToggleEmoji: () => _toggleEmojiPicker(null),
                isRecording: _isRecording,
                onStartRecording: _startRecording,
                onStopRecording: () => _stopRecordingAndSend(null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The row of controls used both for the main composer and for inline
/// replies: text field, emoji toggle, attachment picker, and a
/// press-and-release voice note recorder that becomes the send button when
/// there's no text typed.
class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onToggleEmoji;
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const _Composer({
    required this.controller,
    required this.hint,
    required this.sending,
    required this.onSend,
    required this.onAttach,
    required this.onToggleEmoji,
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.emoji_emotions_outlined),
          onPressed: sending ? null : onToggleEmoji,
        ),
        IconButton(
          icon: const Icon(Icons.attach_file_rounded),
          onPressed: sending ? null : onAttach,
        ),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !sending && !isRecording,
            decoration: InputDecoration(hintText: isRecording ? 'Recording…' : hint),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final hasText = value.text.trim().isNotEmpty;
            if (hasText) {
              return IconButton(
                icon: const Icon(Icons.send_rounded),
                onPressed: sending ? null : onSend,
              );
            }
            return IconButton(
              icon: Icon(isRecording ? Icons.stop_circle_rounded : Icons.mic_none_rounded,
                  color: isRecording ? Colors.red : null),
              onPressed: sending ? null : (isRecording ? onStopRecording : onStartRecording),
            );
          },
        ),
      ],
    );
  }
}

Color _colorForEmail(String email) {
  const palette = [
    Colors.teal, Colors.indigo, Colors.deepOrange, Colors.purple, Colors.blueGrey,
    Colors.brown, Colors.pink, Colors.green,
  ];
  return palette[email.hashCode.abs() % palette.length];
}

String _timeLabel(String isoTimestamp) {
  final parsed = DateTime.tryParse(isoTimestamp)?.toLocal();
  if (parsed == null) return '';
  final hh = parsed.hour.toString().padLeft(2, '0');
  final mm = parsed.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final ApiService api;
  final String? playingUrl;
  final void Function(String url) onTogglePlay;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.api,
    required this.playingUrl,
    required this.onTogglePlay,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDeleted = message.text == '[deleted]';
    final avatarLetter = message.name.isNotEmpty ? message.name[0].toUpperCase() : '?';

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMine ? Colors.green.withValues(alpha: 0.16) : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isMine ? 14 : 2),
          bottomRight: Radius.circular(isMine ? 2 : 14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(message.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          if (!isDeleted && message.mediaUrl != null) _MediaPreview(message: message, api: api, playingUrl: playingUrl, onTogglePlay: onTogglePlay),
          if (!isDeleted && message.text.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: message.mediaUrl != null ? 6 : 0),
              child: Text(message.text),
            ),
          if (isDeleted)
            Text(
              l10n.deletedCommentPlaceholder,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black45),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_timeLabel(message.createdAt), style: const TextStyle(fontSize: 10, color: Colors.black45)),
              if (!isDeleted) ...[
                TextButton(
                  onPressed: onReply,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero),
                  child: Text(l10n.replyAction, style: const TextStyle(fontSize: 11)),
                ),
                if (isMine)
                  TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero),
                    child: Text(l10n.deleteAction, style: const TextStyle(fontSize: 11, color: Colors.red)),
                  ),
              ],
            ],
          ),
        ],
      ),
    );

    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: _colorForEmail(message.email),
      child: Text(avatarLetter, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMine
            ? [Flexible(child: bubble), const SizedBox(width: 6), avatar]
            : [avatar, const SizedBox(width: 6), Flexible(child: bubble)],
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final ChatMessage message;
  final ApiService api;
  final String? playingUrl;
  final void Function(String url) onTogglePlay;

  const _MediaPreview({required this.message, required this.api, required this.playingUrl, required this.onTogglePlay});

  @override
  Widget build(BuildContext context) {
    final url = message.mediaUrl!;
    final resolved = api.resolveMediaUrl(url);
    final headers = api.token != null ? {'Authorization': 'Bearer ${api.token}'} : null;

    switch (message.mediaType) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            resolved,
            headers: headers,
            width: 220,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              width: 220,
              height: 140,
              child: Center(child: Icon(Icons.broken_image_outlined)),
            ),
          ),
        );
      case 'video':
        return _ChatVideoPreview(url: resolved, headers: headers);
      case 'audio':
        final isPlaying = playingUrl == url;
        return SizedBox(
          width: 200,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 32),
                onPressed: () => onTogglePlay(url),
              ),
              const Expanded(child: Text('Voice note', style: TextStyle(fontSize: 13))),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ChatVideoPreview extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;

  const _ChatVideoPreview({required this.url, required this.headers});

  @override
  State<_ChatVideoPreview> createState() => _ChatVideoPreviewState();
}

class _ChatVideoPreviewState extends State<_ChatVideoPreview> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url), httpHeaders: widget.headers ?? {});
    _controller.initialize().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(width: 220, height: 140, child: Center(child: CircularProgressIndicator()));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 220,
        height: (220 / _controller.value.aspectRatio).toDouble(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            IconButton(
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: Colors.white,
                size: 40,
              ),
              onPressed: () => setState(() {
                _controller.value.isPlaying ? _controller.pause() : _controller.play();
              }),
            ),
          ],
        ),
      ),
    );
  }
}
