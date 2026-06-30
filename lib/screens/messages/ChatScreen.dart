import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/services/token_manager.dart';
import 'package:thisjowi/services/messageService.dart';
import 'package:thisjowi/services/sync_service.dart';
import 'package:thisjowi/data/models/message.dart';
import 'package:thisjowi/services/cryptoService.dart';
import 'package:thisjowi/services/messaging_socket_service.dart';
import 'package:thisjowi/components/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final String? title;
  final String? recipientAvatarUrl;

  const ChatScreen({super.key, required this.conversation, this.title, this.recipientAvatarUrl});

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
  bool _isTyping = false;
  String? _currentUserId;
  String _conversationId = '';
  String _chatTitle = 'Chat';
  String? _recipientId;
  String? _recipientAvatarUrl;
  Timer? _pollingTimer;
  final CryptoService _cryptoService = CryptoService();
  final MessagingSocketService _messagingSocket = MessagingSocketService();
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    _initUser();
    _listenToSyncEvents();
    _listenToSocket();
    _textController.addListener(_onTextChanged);
  }

  void _listenToSocket() {
    _socketSub?.cancel();
    _socketSub = _messagingSocket.events.listen((event) {
      if (!mounted) return;
      if (event.type == 'newMessage') {
        final data = event.payload;
        final convId = data['conversationId']?.toString();
        if (convId != null && convId != _conversationId) return;
        _handleIncomingWsMessage(data);
      } else if (event.type == 'readUpdated') {
        final data = event.payload;
        final convId = data['conversationId']?.toString();
        if (convId != _conversationId) return;
        final readerId = data['userId']?.toString();
        if (readerId == _currentUserId) return;
        setState(() {
          for (var i = 0; i < _messages.length; i++) {
            if (_messages[i].senderId == _currentUserId && !_messages[i].isRead) {
              _messages[i] = Message(
                id: _messages[i].id,
                conversationId: _messages[i].conversationId,
                senderId: _messages[i].senderId,
                content: _messages[i].content,
                timestamp: _messages[i].timestamp,
                isRead: true,
                isEncrypted: _messages[i].isEncrypted,
                ephemeralPublicKey: _messages[i].ephemeralPublicKey,
              );
            }
          }
        });
      }
    });
  }

  Future<void> _handleIncomingWsMessage(Map<String, dynamic> data) async {
    final msg = Message.fromJson(data);

    // Handle E2EE decryption
    Message displayMsg = msg;
    if (msg.isEncrypted && msg.ephemeralPublicKey != null && msg.senderId != _currentUserId) {
      final decrypted = await _cryptoService.decryptMessage(
        msg.content,
        msg.ephemeralPublicKey!,
      );
      if (decrypted != null) {
        displayMsg = Message(
          id: msg.id,
          conversationId: msg.conversationId,
          senderId: msg.senderId,
          content: decrypted,
          timestamp: msg.timestamp,
          isRead: msg.isRead,
          isEncrypted: true,
          ephemeralPublicKey: msg.ephemeralPublicKey,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m.id == displayMsg.id);
      _messages.insert(0, displayMsg);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    if (msg.senderId != _currentUserId) {
      await _markRead();
    }
  }

  void _onTextChanged() {
    if (_textController.text.isNotEmpty && _currentUserId != null) {
      // Send typing event to server if API exists
      try {
        _messageService.sendTyping(_conversationId);
      } catch (_) {}
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && !_isLoading && !_messagingSocket.isConnected) {
        _loadMessages(isPolling: true);
      }
    });
  }

  /// Listen to SSE sync events for new messages in this conversation
  void _listenToSyncEvents() {
    _syncSub = SyncService().events.listen((event) {
      if (event.serviceName == 'message') {
        final eventConvId = event.payload['conversationId']?.toString();
        if (eventConvId != _conversationId) return;
        if (!mounted) return;
        if (event.action == 'typing' && mounted) {
          setState(() => _isTyping = true);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _isTyping = false);
          });
          return;
        }
        if (event.action == 'read') {
          if (!_isLoading) _loadMessages(isPolling: true);
          return;
        }
        if (!_isLoading) {
          _loadMessages(isPolling: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _socketSub?.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initUser() async {
    final userId = await _tokenManager.getUserId();
    if (userId != null && mounted) {
      String? recipientId;
      try {
        final recipient = widget.conversation.participants
            .firstWhere((p) => p.id != userId);
        _recipientAvatarUrl = widget.recipientAvatarUrl ?? recipient.avatarUrl;
        recipientId = recipient.id;
      } catch (_) {
        _recipientAvatarUrl = widget.recipientAvatarUrl;
      }
      setState(() {
        _currentUserId = userId;
        _conversationId = widget.conversation.id;
        _recipientId = recipientId;
        _chatTitle =
          widget.title ?? widget.conversation.getTitle(_currentUserId!);
      });
      _loadMessages();
      _startPolling();
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
      _conversationId,
      recipientId: recipientId,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final List<Message> loadedMessages = result['data'];
      if (result['conversationId'] != null) {
        _conversationId = result['conversationId'] as String;
      }

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

      // Auto-scroll to bottom when new messages arrive
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
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
      conversationId: _conversationId,
      senderId: currentId,
      content: text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    setState(() {
      _messages.insert(0, optimisticMessage);
    });

    // Auto-scroll to bottom (index 0 with reverse: true)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
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
      _conversationId,
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
    if (_conversationId != 'new') {
      await _messageService.markAsRead(_conversationId);
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.copy_rounded, color: Theme.of(context).colorScheme.primary),
              title: Text('Copy message'.i18n,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: msg.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Message copied!'.i18n),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Theme.of(context).colorScheme.primary,
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
                    style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(msg);
                },
              ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Message msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                      ),
                      child: Text('Cancel'.i18n),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteMessage(msg.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Delete'.i18n,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(
              _chatTitle.isNotEmpty ? _chatTitle[0].toUpperCase() : '?',
              _recipientId,
              _recipientAvatarUrl,
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(_chatTitle,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
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

          // Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 4),
              child: Row(
                children: [
                  Text(
                    'Writing...'.i18n,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'THISMessages',
                          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 16),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
        ],
      ),
    );
  }

  Widget _buildAvatar(String initial, String? userId, String? avatarUrl, {double size = 48}) {
    return UserAvatar(
      userId: userId,
      avatarUrl: avatarUrl,
      initial: initial,
      size: size,
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool showTail) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && showTail)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: _buildAvatar(
                _chatTitle.isNotEmpty ? _chatTitle[0].toUpperCase() : '?',
                _recipientId,
                _recipientAvatarUrl,
                size: 24,
              ),
            ),
          Container(
            margin: EdgeInsets.only(
              bottom: showTail ? 4 : 2,
              left: isMe ? 60 : 0,
              right: isMe ? 0 : 60,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : (showTail ? 4 : 20)),
                bottomRight: Radius.circular(isMe ? (showTail ? 4 : 20) : 20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: isMe
                            ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.check,
                        size: 14,
                        color: message.isRead
                            ? Colors.lightBlue.shade200
                            : Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
