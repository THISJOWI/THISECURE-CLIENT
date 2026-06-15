import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/services/token_manager.dart';
import 'package:thisjowi/services/messageService.dart';
import 'package:thisjowi/services/sync_service.dart';
import 'package:thisjowi/data/models/message.dart';
import 'package:thisjowi/services/cryptoService.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final String? title;

  const ChatScreen({super.key, required this.conversation, this.title});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final TokenManager _tokenManager = TokenManager();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _syncSub;

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isE2EEAvailable = false;
  String? _currentUserId;
  String _chatTitle = 'Chat';
  final CryptoService _cryptoService = CryptoService();

  @override
  void initState() {
    super.initState();
    _initUser();
    _listenToSyncEvents();
  }

  /// Listen to SSE sync events for new messages in this conversation
  void _listenToSyncEvents() {
    _syncSub = SyncService().events.listen((event) {
      if (event.serviceName == 'message') {
        final conversationId = event.payload['conversationId']?.toString();
        if (conversationId == widget.conversation.id && mounted && !_isLoading) {
          _loadMessages(isPolling: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initUser() async {
    final userId = await _tokenManager.getUserId();
    if (userId != null && mounted) {
      setState(() {
        _currentUserId = userId;
        _chatTitle =
          widget.title ?? widget.conversation.getTitle(_currentUserId!);
      });
      _loadMessages();
      _markRead();
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMessages({bool isPolling = false}) async {
    if (!isPolling) {
      setState(() => _isLoading = true);
    }

    _checkE2EE();

    // Find recipient ID for 'new' conversations
    String? recipientId;
    try {
      recipientId = widget.conversation.participants
          .firstWhere((p) => p.id != _currentUserId)
          .id;
    } catch (_) {}

    final result = await _messageService.getMessages(
      widget.conversation.id,
      recipientId: recipientId,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final List<Message> loadedMessages = result['data'];

      // Explicitly sort by timestamp descending so index 0 is the newest message
      // With reverse: true in ListView, index 0 will be at the bottom
      loadedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        // Merge: Keep all server messages + local optimistic ones not yet on server
        final Set<String> serverIds = loadedMessages.map((m) => m.id).toSet();
        final List<Message> localOnly = _messages
            .where((m) => m.id.startsWith('temp_') && !serverIds.contains(m.id))
            .toList();

        _messages = [...loadedMessages, ...localOnly];
        _messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (!isPolling) _isLoading = false;
        if (loadedMessages
            .any((m) => m.recipientId == _currentUserId && !m.isRead)) {
          _markRead();
        }
      });
    } else {
      if (!isPolling) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkE2EE() async {
    try {
      final recipient = widget.conversation.participants
          .firstWhere((p) => p.id != _currentUserId);
      final key = await _cryptoService.fetchRecipientPublicKey(recipient.id!);

      final isAvailable = key != null && key.isNotEmpty;

      // Only update state if the status has actually changed to avoid UI rebuilds
      if (mounted && _isE2EEAvailable != isAvailable) {
        setState(() {
          _isE2EEAvailable = isAvailable;
        });
        print(
            '🔒 E2EE Status changed to: ${isAvailable ? "Encrypted" : "Not Encrypted"}');
      }
    } catch (e) {
      // On network error, we DON'T revert to "No cifrado" if we already had a key.
      // This prevents flickering during bad connection.
      print('⚠️ Silent error checking E2EE: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    // Optimistic UI update
    final currentId = _currentUserId;
    if (currentId == null) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = Message(
      id: tempId,
      conversationId: widget.conversation.id,
      senderId: currentId,
      content: text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    setState(() {
      _messages.insert(0, optimisticMessage);
    });

    // Find recipient ID (first participant that isn't me)
    String? recipientId;
    try {
      recipientId = widget.conversation.participants
          .firstWhere((p) => p.id != _currentUserId)
          .id;
    } catch (_) {
      // In case of empty participants or only me
    }

    final result = await _messageService.sendMessage(
      widget.conversation.id,
      text,
      recipientId: recipientId,
    );

    if (result['success'] == true) {
      final actualMessage = result['data'] as Message;
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = actualMessage; // Replace optimistic with actual
        }
      });
    } else {
      // Failed, remove optimistic
      setState(() {
        _messages.removeWhere((m) => m.id == tempId);
      });
      // Show error
    }
  }

  Future<void> _markRead() async {
    if (widget.conversation.id != 'new') {
      await _messageService.markAsRead(widget.conversation.id);
    }
  }

  Future<void> _deleteMessage(String id) async {
    final success = await _messageService.deleteMessage(id);
    if (success['success'] == true) {
      setState(() {
        _messages.removeWhere((m) => m.id == id);
      });
    }
  }

  void _showMessageOptions(Message msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading:
                      Icon(Icons.copy_rounded, color: Theme.of(context).colorScheme.primary),
                  title: Text('Copy message'.i18n,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg.content));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Message copied!'.i18n),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
                if (msg.senderId == _currentUserId)
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_rounded,
                        color: Colors.red),
                    title: Text('Delete message'.i18n,
                        style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(msg);
                    },
                  ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Message msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_sweep_rounded,
                      color: Colors.red, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete message?'.i18n,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'This action cannot be undone and the message will disappear for everyone.'.i18n,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 14),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          child: Text('Cancel'.i18n),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteMessage(msg.id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          child: Text('Delete'.i18n,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9), // Glassmorphism-ish
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(_chatTitle,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isE2EEAvailable
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  size: 10,
                  color: _isE2EEAvailable ? Theme.of(context).colorScheme.primary : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  _isE2EEAvailable ? 'Encrypted'.i18n : 'Not encrypted'.i18n,
                  style: TextStyle(
                    color: _isE2EEAvailable ? Theme.of(context).colorScheme.primary : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Avatar in app bar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                _chatTitle.isNotEmpty ? _chatTitle[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                : _messages.isEmpty
                    ? Center(
                        child: Text('Start the conversation!'.i18n,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))))
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true, // Newest at bottom
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderId == _currentUserId;
                          final showTail = index == 0 ||
                              _messages[index - 1].senderId != msg.senderId;

                          return GestureDetector(
                            onLongPress: () => _showMessageOptions(msg),
                            child: _buildMessageBubble(msg, isMe, showTail),
                          );
                        },
                      ),
          ),

          // Input Area
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16,
                    24), // account for safe area implicitly or add SafeArea
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
                  border: Border(
                      top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1))),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {}, // Attachments
                        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                          ),
                          child: TextField(
                            controller: _textController,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'THISMessages',
                              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                              border: InputBorder.none,
                            ),
                            minLines: 1,
                            maxLines: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _sendMessage,
                        icon: Icon(Icons.arrow_upward_rounded,
                            color: Theme.of(context).colorScheme.onSurface),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool showTail) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: showTail ? 12 : 4,
          left: isMe ? 50 : 0,
          right: isMe ? 0 : 50,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
            ),
            if (message.isEncrypted)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 10,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
