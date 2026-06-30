import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thisjowi/data/models/user.dart';
import 'package:thisjowi/data/models/message.dart';
import 'package:thisjowi/screens/messages/ChatScreen.dart';
import 'package:thisjowi/services/messageService.dart';
// If needed for translations:
// import 'package:thisjowi/i18n/translations.dart';

class DialogUtils {
  static Future<void> showNewMessageDialog(BuildContext context,
      {VoidCallback? onSuccess}) async {
    final emailController = TextEditingController();
    final messageService = MessageService();
    
    // Get domain from SharedPreferences to fetch LDAP users
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';
    final domain = email.contains('@') ? email.split('@').last : '';
    
    List<Map<String, dynamic>> ldapUsers = [];
    String? loadingError;

    // Fetch LDAP users
    if (domain.isNotEmpty) {
      final result = await messageService.getLdapUsers(domain);
      
      if (result['success'] == true && result['data'] is List) {
        ldapUsers = List<Map<String, dynamic>>.from(result['data']);
      } else {
        loadingError = result['message'] ?? 'Could not load LDAP users';
      }
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AlertDialog(
          backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
        title:
            Text('New Message', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ldapUsers.isEmpty)
                Text('Enter email of the recipient',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13))
              else
                Text('Select a contact or enter an email',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13)),
              const SizedBox(height: 16),
              // LDAP Users List
              if (ldapUsers.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(minHeight: 100, maxHeight: 250),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: ldapUsers.length,
                    itemBuilder: (context, index) {
                      final user = ldapUsers[index];
                      final userEmail = user['email'] ?? '';
                      final fullName = user['fullName'] ?? user['ldapUsername'] ?? userEmail;
                      
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        title: Text(
                          fullName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          userEmail,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          emailController.text = userEmail;
                        },
                        selected: emailController.text == userEmail,
                        selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      );
                    },
                  ),
                ),
              if (ldapUsers.isNotEmpty)
                const SizedBox(height: 16),
              // Email Input
              TextField(
                controller: emailController,
                autofocus: true,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'or type email',
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
              ),
              if (loadingError != null) ...[
                const SizedBox(height: 8),
                Text(
                  loadingError,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () =>
                Navigator.pop(context, emailController.text.trim()),
            child: const Text('Start Chat'),
          ),
        ],
      ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Try to find real user ID from LDAP data for avatar loading
      final ldapUser = ldapUsers.cast<Map<String, dynamic>?>().firstWhere(
        (u) => u?['email']?.toString() == result,
        orElse: () => null,
      );
      final realId = ldapUser?['userId']?.toString() ?? ldapUser?['id']?.toString();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversation: Conversation(
              id: 'new', // Flag for new conversation
              participants: [
                User(
                  id: realId ?? 'recipient',
                  email: result,
                  fullName: ldapUser?['fullName']?.toString(),
                  avatarUrl: ldapUser?['avatarUrl']?.toString() ?? ldapUser?['avatar_url']?.toString(),
                ),
              ],
              updatedAt: DateTime.now(),
            ),
          ),
        ),
      ).then((_) {
        if (onSuccess != null) onSuccess();
      });
    }
  }
}
