import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/services/token_manager.dart';
import 'package:thisjowi/services/messageService.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';
import 'package:thisjowi/data/models/message.dart';
import 'package:thisjowi/data/models/user.dart';
import 'package:thisjowi/services/cryptoService.dart';
import 'package:thisjowi/screens/messages/ChatScreen.dart';
import 'package:thisjowi/components/animations/animated_widgets.dart';
import 'package:thisjowi/components/user_avatar.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessageService _messageService = MessageService();
  final TokenManager _tokenManager = TokenManager();

  List<Map<String, dynamic>> _ldapUsers = [];
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  bool _showSkeletons = true;
  String _searchQuery = '';
  String? _currentUserId;
  Timer? _skeletonTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeCrypto();
    _skeletonTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showSkeletons = false);
    });
  }

  Future<void> _initializeCrypto() async {
    final crypto = CryptoService();
    await crypto.initKeys();
    print('🔐 Crypto initialized for messaging');
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _currentUserId = await _tokenManager.getUserId();

    // Fetch Conversations
    final convResult = await _messageService.getConversations();
    if (mounted && convResult['success'] == true) {
      setState(() {
        _conversations = List<Conversation>.from(convResult['data']);
      });
    }

    // Get user email to extract LDAP domain
    String? email;
    final token = await _tokenManager.getToken();
    if (token != null && token.isNotEmpty) {
      final payload = _tokenManager.decodeTokenPayload();
      email = payload?['email']?.toString();
    }
    final secureStorage = SecureStorageService();
    if (email == null || email.isEmpty) {
      email = await secureStorage.getValue('cached_email');
    }

    String? domain;
    if (email != null && email.contains('@')) {
      domain = email.split('@').last;
    }
    // Fallback: saved ldap_domain from SecureStorage
    if (domain == null || domain.isEmpty) {
      domain = await secureStorage.getValue('ldap_domain');
    }

    if (domain != null) {
      final ldapResult = await _messageService.getLdapUsers(domain);
      if (mounted) {
        if (ldapResult['success'] == true && ldapResult['data'] is List) {
          final allUsers = List<Map<String, dynamic>>.from(ldapResult['data']);
          final filteredUsers = allUsers
            .where((u) => (u['userId'] ?? u['id'])?.toString() != _currentUserId?.toString())
            .toList();
      _skeletonTimer?.cancel();
      _showSkeletons = false;
      setState(() {
        _ldapUsers = filteredUsers;
        _isLoading = false;
      });
      return;
        }
      }
    }

    _skeletonTimer?.cancel();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _skeletonTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.dark
            : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // -- Header --
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: Theme.of(context).colorScheme.primary, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Messages'.i18n,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // -- Search Bar --
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Search'.i18n,
                              hintStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontSize: 16),
                              prefixIcon: Icon(Icons.search,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  size: 22),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.close,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                          size: 20),
                                      onPressed: () {
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // -- List --
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      child: _isLoading && _showSkeletons
                          ? _buildSkeletonList()
                          : _buildUnifiedList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);

    Widget skeletonItem() {
      return ShimmerAnimation(
        shimmerColor: Theme.of(context).colorScheme.onSurface,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.light
                          ? Colors.white
                          : const Color(0xFF2A2A2A))
                      .withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 18),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 140,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 200,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: 10,
      itemBuilder: (context, index) => skeletonItem(),
    );
  }

  Widget _buildUnifiedList() {
    // 1. Create a map of LDAP users for easy lookup by ID
    final Map<String, dynamic> userMap = {
      for (var u in _ldapUsers) (u['userId'] ?? u['id'])?.toString() ?? '': u
    };

    // 2. Filter recent conversations
    final recentConvs = _conversations.where((conv) {
      if (_searchQuery.isEmpty) return true;
      final title = conv.getTitle(_currentUserId ?? '').toLowerCase();

      final otherParticipant = conv.participants.firstWhere(
        (p) => p.id != _currentUserId,
        orElse: () => User(id: '', email: ''),
      );

      final ldap = userMap[otherParticipant.id];
      final ldapName = (ldap?['fullName']?.toString() ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return title.contains(query) || ldapName.contains(query);
    }).toList();

    // Sort recent by date
    recentConvs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // 3. Filter other contacts
    final filteredContacts = _ldapUsers.where((user) {
      final String name = (user['fullName']?.toString() ?? '').toLowerCase();
      final String email = (user['email']?.toString() ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    // Sort contacts alphabetically
    filteredContacts.sort((a, b) {
      final String nameA = (a['fullName']?.toString() ?? '').toLowerCase();
      final String nameB = (b['fullName']?.toString() ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });

    // 4. Build items for the list
    final List<dynamic> listItems = [];

    // Add search-filtered conversations
    if (recentConvs.isNotEmpty) {
      listItems.add('Conversaciones');
      listItems.addAll(recentConvs);
    }

    // Add search-filtered contacts (only those that are NOT in active conversations)
    final Set<String?> activeIds =
        recentConvs.expand((c) => c.participants.map((p) => p.id)).toSet();
    final List<dynamic> otherContacts = filteredContacts
        .where((u) => !activeIds.contains((u['userId'] ?? u['id'])?.toString()))
        .toList();

    if (otherContacts.isNotEmpty) {
      listItems.add('Encuentra a alguien');
      listItems.addAll(otherContacts);
    }

    if (!_isLoading && listItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'No results found'.i18n,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: listItems.length,
      itemBuilder: (context, index) {
        final item = listItems[index];

        if (item is String) {
          // It's a header
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            child: Text(
              item.toUpperCase().i18n,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          );
        }

        if (item is Conversation) {
          final otherId = item.participants
              .firstWhere((p) => p.id != _currentUserId,
                  orElse: () => User(id: '', email: ''))
              .id;
          return _buildConversationItem(
            item,
            _currentUserId ?? '',
            ldapData: userMap[otherId],
          );
        }

        // It's a contact (LDAP User map)
        final contact = item as Map<String, dynamic>;
        final String name = contact['fullName']?.toString() ??
            contact['email']?.toString() ??
            'Unknown';
        final String contactId = contact['userId']?.toString() ?? contact['id']?.toString() ?? '';
        final bool canMessage = contactId.isNotEmpty;

        return _buildConversationItem(
          Conversation(
            id: 'new',
            participants: [
              User.fromJson({
                'id': contactId,
                'email': contact['email'],
                'fullName': name,
              })
            ],
            updatedAt: DateTime.now(),
          ),
          _currentUserId ?? '',
          ldapData: contact,
          onTapDisabled: !canMessage,
        );
      },
    );
  }

  Widget _buildAvatar(String initial, String? userId, String? avatarUrl) {
    return UserAvatar(
      userId: userId,
      avatarUrl: avatarUrl,
      initial: initial,
      size: 48,
    );
  }

  Widget _buildConversationItem(Conversation conv, String currentUserId,
      {Map<String, dynamic>? ldapData, bool onTapDisabled = false}) {
    String title = conv.getTitle(currentUserId);
    if (ldapData != null) {
      title = ldapData['fullName']?.toString() ??
          ldapData['ldapUsername']?.toString() ??
          ldapData['email']?.toString() ??
          title;
    }

    final String lastMsg = conv.lastMessage?.content ?? 'No messages';
    final String initial = (title.isNotEmpty ? title[0] : '?').toUpperCase();
    final bool isUnread = conv.unreadCount > 0;
    String? avatarUrl;
    String? otherUserId;
    try {
      final other = conv.participants.firstWhere((p) => p.id != currentUserId);
      otherUserId = other.id;
    } catch (_) {}
    if (ldapData != null) {
      avatarUrl = (ldapData['avatarUrl'] ?? ldapData['avatar_url'] ?? ldapData['jpegPhoto'] ?? ldapData['thumbnailPhoto'] ?? ldapData['photo'])?.toString();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isUnread
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          onTap: onTapDisabled
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('This user has not logged in yet.'.i18n),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        conversation: conv,
                        title: title,
                        recipientAvatarUrl: avatarUrl,
                      ),
                    ),
                  );
                  if (mounted) {
                    setState(() {
                      final index = _conversations.indexWhere((c) => c.id == conv.id);
                      if (index != -1) {
                        _conversations[index] = Conversation(
                          id: conv.id,
                          participants: conv.participants,
                          lastMessage: conv.lastMessage,
                          unreadCount: 0,
                          updatedAt: DateTime.now(),
                        );
                      }
                    });
                  }
                },
          leading: _buildAvatar(initial, otherUserId, avatarUrl),
          title: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUnread
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ),
          trailing: isUnread
              ? Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                )
              : Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                ),
        ),
      ),
    );
  }
}
