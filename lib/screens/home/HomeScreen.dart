import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thisjowi/data/models/password_entry.dart';
import 'package:thisjowi/data/models/note_entry.dart';
import 'package:thisjowi/data/repository/passwordsRepository.dart';
import 'package:thisjowi/data/repository/notes_repository.dart';
import 'package:thisjowi/components/button.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/components/liquid_glass.dart';
import 'package:thisjowi/core/providers/sync_provider.dart';
import 'package:thisjowi/screens/password/EditPasswordScreen.dart';
import 'package:thisjowi/screens/notes/EditNoteScreen.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/utils/GlobalActions.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/components/search_debounce.dart';
import 'package:thisjowi/services/autofillService.dart';
import 'package:thisjowi/services/telemetry_service.dart';
import 'package:thisjowi/screens/home/components/password_item.dart';
import 'package:thisjowi/screens/home/components/note_item.dart';
import 'package:thisjowi/screens/home/components/empty_state.dart';
import 'package:thisjowi/components/animations/animated_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PasswordsRepository _passwordsRepository;
  late final NotesRepository _notesRepository;
  final _searchDebounce = SearchDebounce();

  List<PasswordEntry> _passwords = [];
  List<Note> _notes = [];
  bool _isLoading = true;
  bool _showSkeletons = false;
  Timer? _skeletonTimer;
  String _searchQuery = '';
  VoidCallback? _syncListener;
  SyncProvider? _syncProvider;

  @override
  void dispose() {
    _skeletonTimer?.cancel();
    _searchDebounce.dispose();
    _syncProvider?.removeListener(_syncListener!);
    _syncListener = null;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initRepositories();
    _syncProvider = context.read<SyncProvider>();
    _loadData();
    _checkAutofill();
    _listenToSyncEvents();
  }

  void _listenToSyncEvents() {
    final syncProvider = _syncProvider;
    if (syncProvider == null) return;
    _syncListener = () {
      final info = syncProvider.lastEventInfo;
      if (info.startsWith('password/') ||
          info.startsWith('note/')) {
        _loadData();
      }
    };
    syncProvider.addListener(_syncListener!);
  }

  Future<void> _checkAutofill() async {
    // Delay slightly to allow the screen to render
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final autofillService = AutofillService();
    final status = await autofillService.getAutofillStatus();

    if (status.isSupported && !status.isEnabled) {
      final prefs = await SharedPreferences.getInstance();
      final hasPrompted = prefs.getBool('autofill_prompt_shown') ?? false;

      if (!hasPrompted) {
        _showAutofillPopup();
      }
    }
  }

  void _showAutofillPopup() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: LiquidGlass.wrap(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Password Manager'.i18n,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Make THISECURE your primary password manager to automatically fill in data in all your applications.'
                    .i18n,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('autofill_prompt_shown', true);
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Later'.i18n,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('autofill_prompt_shown', true);
                        if (context.mounted) Navigator.pop(context);
                        AutofillService().openAutofillSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Configure'.i18n,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          context,
          padding: const EdgeInsets.all(24),
          borderRadius: 24,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  void _initRepositories() {
    
    _passwordsRepository = PasswordsRepository();
    _notesRepository = NotesRepository();
  }

  /// Extrae el texto plano del contenido JSON Delta de una nota
  String _extractPlainText(String content) {
    try {
      if (content.isEmpty) return '';
      final json = jsonDecode(content);

      if (json is List) {
        // Delta format: List of operations
        final buffer = StringBuffer();
        for (final op in json) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is String) {
              buffer.write(insert);
            }
          }
        }
        return buffer.toString().replaceAll('\n', ' ').trim();
      } else if (json is Map && json.containsKey('ops')) {
        // Alternative Delta format
        final buffer = StringBuffer();
        for (final op in json['ops'] ?? []) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is String) {
              buffer.write(insert);
            }
          }
        }
        return buffer.toString().replaceAll('\n', ' ').trim();
      }
    } catch (e) {
      // If it's not JSON, treat as plain text
      return content;
    }
    return content;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _showSkeletons = false;
    });
    _skeletonTimer?.cancel();
    _skeletonTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _showSkeletons = true);
    });

    // Load both in parallel - WAIT for sync to complete
    final results = await Future.wait([
      _passwordsRepository.getAllPasswords(),
      _notesRepository.getAllNotes(),
    ]);

    if (!mounted) return;

    final passwordResult = results[0];
    final notesResult = results[1];

    List<PasswordEntry> passwords = [];
    List<Note> notes = [];

    if (passwordResult['success'] == true) {
      final rawPasswords = passwordResult['data'] as List<PasswordEntry>? ?? [];
      // Deduplicate passwords to prevent UI duplicates
      final seenPasswords = <String>{};
      for (final p in rawPasswords) {
        final key = '${p.title}|${p.username}';
        if (!seenPasswords.contains(key)) {
          seenPasswords.add(key);
          passwords.add(p);
        }
      }
    }

    if (notesResult['success'] == true) {
      final rawNotes = notesResult['data'] as List<Note>? ?? [];
      // Deduplicate notes to prevent UI duplicates
      final seenNotes = <String>{};
      for (final n in rawNotes) {
        if (!seenNotes.contains(n.title)) {
          seenNotes.add(n.title);
          notes.add(n);
        }
      }
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      passwords = passwords
          .where((p) =>
              p.title.toLowerCase().contains(query) ||
              p.username.toLowerCase().contains(query))
          .toList();
      notes = notes
          .where((n) =>
              n.title.toLowerCase().contains(query) ||
              n.content.toLowerCase().contains(query))
          .toList();
    }

    setState(() {
      _passwords = passwords;
      _notes = notes;
_isLoading = false;
});
}

Future<bool> _showDeletePasswordConfirmation(PasswordEntry entry) async {
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
            content: Text(
                '${'Are you sure you want to delete'.i18n} "${entry.title}"?',
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
    final confirm = await _showDeletePasswordConfirmation(entry);
    if (!confirm) return;

    final result = await _passwordsRepository.deletePassword(entry.id,
        serverId: entry.serverId);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() => _passwords.removeWhere((p) => p.id == entry.id));
      ErrorSnackBar.showSuccess(context, 'Password deleted'.i18n);
    } else {
      ErrorSnackBar.show(context, result['message'] ?? 'Error deleting');
    }
  }

  Future<bool> _showDeleteNoteConfirmation(Note note) async {
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
          title: Text('Delete Note?'.i18n,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            content: Text(
                '${'Are you sure you want to delete'.i18n} "${note.title}"?',
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

  Future<void> _deleteNote(Note note) async {
    final confirm = await _showDeleteNoteConfirmation(note);
    if (!confirm) return;

    final noteId = note.localId ?? note.id?.toString() ?? '';
    if (noteId.isEmpty) return;

    final result = await _notesRepository.deleteNote(noteId,
        serverId: note.serverId?.toString() ?? note.id?.toString());

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() => _notes.removeWhere((n) =>
          (n.localId != null && n.localId == note.localId) ||
          (n.id != null && n.id == note.id)));
      ErrorSnackBar.showSuccess(context, 'Note deleted'.i18n);
    } else {
      ErrorSnackBar.show(
          context, result['message'] ?? 'Error deleting note'.i18n);
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
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
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
                                fontWeight: FontWeight.bold),
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
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(entry.website,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (entry.username.isNotEmpty) ...[
                      Text('User'.i18n,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8)),
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
                              tooltip: 'Copy username'.i18n,
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
                          borderRadius: BorderRadius.circular(8)),
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
                                size: 18),
                            tooltip: showPassword ? 'Hide password'.i18n : 'Show password'.i18n,
                            onPressed: () =>
                                setState(() => showPassword = !showPassword),
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                            padding: const EdgeInsets.only(right: 8),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.copy,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                size: 18),
                            tooltip: 'Copy password'.i18n,
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
                            style: const TextStyle(
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
      ),
    );
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
      child: Stack(
        children: [
SafeArea(
            child: Column(
              children: [
// Header with icon and title
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Icon(Icons.home_rounded,
                          color: Theme.of(context).colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Home'.i18n,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF5F5F5)),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Search'.i18n,
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
                                tooltip: 'Clear search'.i18n,
                                onPressed: () {
                                  setState(() => _searchQuery = '');
                                  _loadData();
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
                        if (value.isNotEmpty) {
                          TelemetryService.trackEvent('search_performed');
                        }
                        _searchDebounce.debounce(() => _loadData());
                      },
                    ),
                  ),
                ),
              ),
              ),
                // Content
                Expanded(
                  child: _isLoading
                      ? (_showSkeletons
                          ? _buildSkeletonList()
                          : Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ))
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: Theme.of(context).colorScheme.onSurface,
                          child: _passwords.isEmpty && _notes.isEmpty
                              ? _buildEmptyState()
                              : ListView(
                                  padding: const EdgeInsets.only(bottom: 150),
                                  children: [
                                    // Passwords Section
                                    if (_passwords.isNotEmpty) ...[
                                      _buildSectionHeader(
                                        icon: Icons.lock_outline,
                                        title: 'Passwords'.i18n,
                                        count: _passwords.length,
                                      ),
                                      ..._passwords.map(
                                          (entry) => _buildPasswordItem(entry)),
                                    ],

                                    // Divider between sections
                                    if (_passwords.isNotEmpty &&
                                        _notes.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 8),
                                        child: Divider(
                                          color:
                                              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                          thickness: 1,
                                        ),
                                      ),

                                    // Notes Section
                                    if (_notes.isNotEmpty) ...[
                                      _buildSectionHeader(
                                        icon: Icons.description_outlined,
                                        title: 'Notes'.i18n,
                                        count: _notes.length,
                                      ),
                                      ..._notes
                                          .map((note) => _buildNoteItem(note)),
                                    ],
                                  ],
                                ),
                        ),
                ),
              ],
            ),
          ),
          // FAB
          Positioned(
            bottom: 130.0,
            right: 16.0,
            child: ExpandableActionButton(
              onCreatePassword: () =>
                  GlobalActions.createPassword(context, onSuccess: _loadData),
              onCreateNote: () =>
                  GlobalActions.createNote(context, onSuccess: _loadData),
              onCreateOtp: () => GlobalActions.createOtp(context),
              onCreateMessage: () => GlobalActions.createMessage(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordItem(PasswordEntry entry) {
    return PasswordItem(
      entry: entry,
      onTap: () => _showPasswordDetails(entry),
      onEdit: () async {
        final edited = await showDialog<bool>(
          context: context,
          builder: (context) => Center(
            child: SizedBox(
              width: 400,
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: EditPasswordScreen(
                  passwordsRepository: _passwordsRepository,
                  passwordEntry: entry,
                ),
              ),
            ),
          ),
        );
        if (edited == true) _loadData();
      },
      onDelete: () => _deletePassword(entry),
    );
  }

  Widget _buildNoteItem(Note note) {
    return NoteItem(
      note: note,
      onTap: () async {
        final edited = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => EditNoteScreen(
              notesRepository: _notesRepository,
              note: note,
            ),
          ),
        );
        if (edited == true) _loadData();
      },
      onDelete: () => _deleteNote(note),
    );
  }

  Widget _buildSkeletonList() {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);

    Widget skeletonPasswordItem() {
      return ShimmerAnimation(
        shimmerColor: Theme.of(context).colorScheme.onSurface,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
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
                    horizontal: 16.0, vertical: 16.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 13,
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

    Widget skeletonNoteItem() {
      return ShimmerAnimation(
        shimmerColor: Theme.of(context).colorScheme.onSurface,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
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
                    horizontal: 16.0, vertical: 16.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
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
                            width: 100,
                            height: 13,
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

    Widget skeletonSectionHeader() {
      return ShimmerAnimation(
        shimmerColor: Theme.of(context).colorScheme.onSurface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 150),
      children: [
        skeletonSectionHeader(),
        ...List.generate(4, (_) => skeletonPasswordItem()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Divider(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            thickness: 1,
          ),
        ),
        skeletonSectionHeader(),
        ...List.generate(4, (_) => skeletonNoteItem()),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const HomeEmptyState();
  }
}
