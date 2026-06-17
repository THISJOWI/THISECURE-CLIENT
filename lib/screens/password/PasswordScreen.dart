import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thisjowi/screens/notes/EditNoteScreen.dart';
import 'package:thisjowi/data/models/password_entry.dart';
import 'package:thisjowi/data/repository/passwordsRepository.dart';
import 'package:thisjowi/data/repository/notes_repository.dart';
import 'package:thisjowi/components/button.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/components/liquid_glass.dart';
import 'package:thisjowi/components/password_generator_dialog.dart';
import 'package:thisjowi/core/providers/sync_provider.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/components/search_debounce.dart';
import 'package:provider/provider.dart';
import 'EditPasswordScreen.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  late final PasswordsRepository _passwordsRepository;
  final _searchDebounce = SearchDebounce();
  List<PasswordEntry> _passwords = [];
  bool _isLoading = true;
  String _searchQuery = '';
  VoidCallback? _syncListener;

  @override
  void initState() {
    super.initState();
    // Initialize repository from singleton
_passwordsRepository = PasswordsRepository();
    _loadPasswords();
    _listenToSyncEvents();
  }

  void _listenToSyncEvents() {
    try {
      final syncProvider = context.read<SyncProvider>();
      _syncListener = () {
        if (syncProvider.lastEventInfo.startsWith('password/')) {
          _loadPasswords();
        }
      };
      syncProvider.addListener(_syncListener!);
    } catch (_) {
      // SyncProvider might not be available in tests
    }
  }

  @override
  void dispose() {
    _searchDebounce.dispose();
    if (_syncListener != null) {
      try {
        context.read<SyncProvider>().removeListener(_syncListener!);
      } catch (_) {}
      _syncListener = null;
    }
    super.dispose();
  }

  Future<void> _loadPasswords() async {
    setState(() => _isLoading = true);

    final result = await _passwordsRepository.getAllPasswords();

    if (!mounted) return;

    if (result['success'] == true) {
      final passwords = result['data'] as List<PasswordEntry>? ?? [];
      setState(() {
        _passwords = _searchQuery.isEmpty
            ? passwords
            : passwords
                .where((p) =>
                    p.title.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _passwords = [];
        _isLoading = false;
      });
      ErrorSnackBar.show(
          context, result['message'] ?? 'Error loading passwords'.i18n);
    }
  }

  Future<bool> _showDeleteConfirmation(PasswordEntry entry) async {
    return await showDialog<bool>(
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
              title: Text('Delete password?'.i18n,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            content: Text('Are you sure you want to delete "${entry.title}"?',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Cancel'.i18n),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Delete'.i18n),
              ),
            ],
          ),
          ),
        ) ??
        false;
  }

  Future<void> _deletePassword(PasswordEntry entry) async {
    final confirm = await _showDeleteConfirmation(entry);
    if (!confirm) return;

    final result = await _passwordsRepository.deletePassword(entry.id,
        serverId: entry.serverId);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _passwords.removeWhere((p) => p.id == entry.id);
      });
      ErrorSnackBar.showSuccess(context, 'Password deleted'.i18n);
    } else {
      ErrorSnackBar.show(context, result['message'] ?? 'Error deleting'.i18n);
    }
  }

  void _showPasswordDetails(PasswordEntry entry) {
    bool showPassword = false;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: LiquidGlass.wrap(
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (entry.website.isNotEmpty) ...[
                    Text('Website'.i18n,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(entry.website,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (entry.username.isNotEmpty) ...[
                    Text('User',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(entry.username,
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface, fontSize: 14))),
                          IconButton(
                            icon: Icon(Icons.copy,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                size: 18),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: entry.username));
                              ErrorSnackBar.showInfo(
                                  context, 'User copied'.i18n);
                            },
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text('Password'.i18n,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            showPassword
                                ? entry.password
                                : '•' * entry.password.length,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                letterSpacing: 1),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => showPassword = !showPassword),
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          padding: const EdgeInsets.only(right: 8),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.copy,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 18),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: entry.password));
                            ErrorSnackBar.showInfo(
                                context, 'Password copied'.i18n);
                          },
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  if (entry.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Notes'.i18n,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(entry.notes,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'.i18n,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              context,
              padding: const EdgeInsets.all(24),
              borderRadius: 20,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createPassword() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EditPasswordScreen(
          passwordsRepository: _passwordsRepository,
        ),
      ),
    );
    if (created == true) {
      _loadPasswords();
    }
  }

  Future<void> _quickGeneratePassword() async {
    await PasswordGeneratorDialog.show(context);
  }

  Future<void> _createNote() async {
    final notesRepository = context.read<NotesRepository>();

    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditNoteScreen(
          notesRepository: notesRepository,
        ),
      ),
    );
    if (created == true) {
      // The note was created successfully, the user is back in PasswordScreen
      // No action needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                      decoration: BoxDecoration(
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? Color.lerp(Theme.of(context).scaffoldBackgroundColor, Colors.white, 0.12)!
                            : Color.lerp(Theme.of(context).scaffoldBackgroundColor, Colors.black, 0.06)!)
                            .withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Search passwords'.i18n,
                          hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 16),
                          prefixIcon: Icon(Icons.search,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 22),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      size: 20),
                                  onPressed: () {
                                    setState(() => _searchQuery = '');
                                    _loadPasswords();
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
                          _searchDebounce.debounce(() => _loadPasswords());
                        },
                      ),
                    ),
                    ),
                  ),
                ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface))
                  : _passwords.isEmpty
                      ? Center(
                          child: Text('No passwords stored'.i18n,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                        )
                      : ListView.builder(
                          itemCount: _passwords.length,
                          itemBuilder: (context, index) {
                            final entry = _passwords[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: (Theme.of(context).brightness == Brightness.light ? Colors.white : const Color(0xFF2A2A2A)).withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                    onTap: () => _showPasswordDetails(entry),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 12.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  entry.title,
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onSurface,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  entry.username.isNotEmpty
                                                      ? entry.username
                                                      : entry.website,
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onSurface
                                                        .withValues(alpha: 0.6),
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            icon: Icon(Icons.edit,
                                                color: Theme.of(context).colorScheme.onSurface
                                                    .withValues(alpha: 0.7),
                                                size: 20),
                                            onPressed: () async {
                                              final edited =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (context) => Center(
                                                  child: SizedBox(
                                                    width: 400,
                                                    child: Dialog(
                                                      backgroundColor: Colors.transparent,
                                                      elevation: 0,
                                                      child: EditPasswordScreen(
                                                        passwordsRepository:
                                                            _passwordsRepository,
                                                        passwordEntry: entry,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                              if (edited == true) {
                                                _loadPasswords();
                                              }
                                            },
                                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Theme.of(context).colorScheme.onSurface
                                                    .withValues(alpha: 0.7),
                                                size: 20),
                                            onPressed: () =>
                                                _deletePassword(entry),
                                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                  ),
                                ),
                              ),
                            );
                            },
                        ),
            ),
          ],
        ),
        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: ExpandableActionButton(
            onCreatePassword: _createPassword,
            onCreateNote: _createNote,
          ),
        ),
      ],
    );
  }
}
