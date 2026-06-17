import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/i18n/translations.dart';
import '../services/autofillService.dart';

/// Widget to display autofill status and allow configuration
class AutofillSettingsCard extends StatefulWidget {
  const AutofillSettingsCard({super.key});

  @override
  State<AutofillSettingsCard> createState() => _AutofillSettingsCardState();
}

class _AutofillSettingsCardState extends State<AutofillSettingsCard> {
  final AutofillService _autofillService = AutofillService();
  AutofillStatus? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    final status = await _autofillService.getAutofillStatus();
    if (mounted) {
      setState(() {
        _status = status;
        _loading = false;
      });
    }
  }

  Future<void> _handleAction() async {
    if (Platform.isAndroid) {
      await _autofillService.openAutofillSettings();
      // Refresh status after returning from settings
      await Future.delayed(const Duration(seconds: 1));
      _loadStatus();
    } else if (Platform.isIOS) {
      _showIOSInstructions();
    }
  }

  void _showIOSInstructions() {
    showDialog(
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
          title: Text('Configure AutoFill on iOS'.i18n),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To enable THISECURE as a password manager:'.i18n),
            const SizedBox(height: 16),
            Text('1. Open the Settings app'.i18n),
            Text('2. Go to "Passwords"'.i18n),
            Text('3. Tap "AutoFill Passwords"'.i18n),
            Text('4. Enable "THISECURE"'.i18n),
            const SizedBox(height: 16),
            Text('After this, THISECURE can suggest passwords in Safari and other apps.'.i18n),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_status == null || !_status!.isSupported) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isEnabled = _status!.isEnabled;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEnabled ? Icons.check_circle : Icons.info_outline,
                  color: isEnabled ? Colors.green : theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Autofill passwords'.i18n,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isEnabled && Platform.isAndroid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active'.i18n,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _status!.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (_status!.actionText != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleAction,
                  icon: Icon(isEnabled ? Icons.settings : Icons.lock_open),
                  label: Text(_status!.actionText!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEnabled
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.primary,
                    foregroundColor: isEnabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Screen to select a password for autofill
class AutofillPasswordPicker extends StatefulWidget {
  final AutofillRequest request;
  final List<Map<String, dynamic>> passwords;
  final Function(String username, String password) onPasswordSelected;
  final VoidCallback onCancel;

  const AutofillPasswordPicker({
    super.key,
    required this.request,
    required this.passwords,
    required this.onPasswordSelected,
    required this.onCancel,
  });

  @override
  State<AutofillPasswordPicker> createState() => _AutofillPasswordPickerState();
}

class _AutofillPasswordPickerState extends State<AutofillPasswordPicker> {
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filteredPasswords {
    if (_searchQuery.isEmpty) {
      return widget.passwords;
    }
    
    final query = _searchQuery.toLowerCase();
    return widget.passwords.where((password) {
      final title = (password['title'] ?? '').toString().toLowerCase();
      final username = (password['username'] ?? '').toString().toLowerCase();
      final website = (password['website'] ?? '').toString().toLowerCase();
      
      return title.contains(query) ||
             username.contains(query) ||
             website.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Select password'.i18n),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
      ),
      body: Column(
        children: [
          // Header with app info
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  Icons.apps,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Autofill for:'.i18n,
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        widget.request.appName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search password...'.i18n,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          
          // Password list
          Expanded(
            child: _filteredPasswords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No passwords found'.i18n,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredPasswords.length,
                    itemBuilder: (context, index) {
                      final password = _filteredPasswords[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            (password['title'] ?? '?')[0].toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(password['title'] ?? 'No Title'.i18n),
                        subtitle: Text(password['username'] ?? ''),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          widget.onPasswordSelected(
                            password['username'] ?? '',
                            password['password'] ?? '',
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
