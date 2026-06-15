import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/core/service_locator.dart';
import 'package:thisjowi/core/providers/sync_provider.dart';
import 'package:thisjowi/data/models/note_entry.dart';
import 'package:thisjowi/data/repository/notes_repository.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:provider/provider.dart';

import '../../components/animations/animated_widgets.dart';

import 'EditNoteScreen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late final NotesRepository _notesRepository;
  List<Note> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  VoidCallback? _syncListener;

  @override
  void initState() {
    super.initState();
    // Initialize repository from singleton
    final sl = ServiceLocator();
    _notesRepository = sl.notesRepository;
    _loadNotes();
    _listenToSyncEvents();
  }

  void _listenToSyncEvents() {
    try {
      final syncProvider = context.read<SyncProvider>();
      _syncListener = () {
        if (syncProvider.lastEventInfo.startsWith('note/')) {
          _loadNotes();
        }
      };
      syncProvider.addListener(_syncListener!);
    } catch (_) {
      // SyncProvider might not be available in tests
    }
  }

  Future<void> _loadNotes() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final result = _searchQuery.isEmpty
          ? await _notesRepository.getAllNotes()
          : await _notesRepository.searchNotes(_searchQuery);

      if (!mounted) return;

      if (result['success'] == true) {
        final notes = result['data'] as List<Note>? ?? [];
        if (mounted) {
          setState(() {
            _notes = notes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          try {
            ErrorSnackBar.show(
                context, result['message'] ?? 'Error loading notes'.i18n);
          } catch (snackBarError) {
            debugPrint('Error showing snackbar: $snackBarError');
          }
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error loading notes: $e');
      try {
        ErrorSnackBar.show(context, 'Error: $e');
      } catch (snackBarError) {
        debugPrint('Error showing snackbar: $snackBarError');
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showDeleteConfirmation(Note note) async {
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
              title: Text(
                'Delete Note?'.i18n,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            content: Text(
              '${'Are you sure you want to delete'.i18n} "${note.title}"?',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
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

  Future<void> _performDelete(Note note) async {
    try {
      // Usar localId si existe, sino usar id para compatibilidad
      final noteId = note.localId ?? note.id?.toString() ?? '';
      if (noteId.isEmpty) {
        // En caso de error de ID, tal vez no deberíamos hacer nada o loguear
        return;
      }

      // Llamada al repositorio
      final result = await _notesRepository.deleteNote(noteId,
          serverId: note.serverId?.toString() ?? note.id?.toString());

      if (!mounted) return;

      if (result['success'] == true) {
        // No llamamos a setState aquí porque Dismissible espera que el widget se elimine del árbol
        // Pero necesitamos actualizar la lista subyacente _notes para que si hay un rebuild no reaparezca
        // Y para mantener la consistencia.
        // Dismissible remove visualmente, pero nosotros debemos actualizar la data.
        // Si hacemos setState, Flutter reconstruye y Dismissible puede quejarse si no se maneja bien,
        // pero generalmente en onDismissed SI se debe actualizar la data.
        setState(() {
          _notes.removeWhere((n) =>
              (n.localId != null && n.localId == note.localId) ||
              (n.id != null && n.id == note.id));
        });

        // ErrorSnackBar.showSuccess(context, 'Note deleted'.i18n); // Feedback opcional, tal vez demasiado ruidoso para swipe
      } else {
        // Si falla, tendríamos que deshacer el dismiss o mostrar error.
        // Recuperar el item es complejo con Dismissible estándar si ya se fue la animación.
        // Por ahora mostramos error.
        if (mounted) {
          try {
            ErrorSnackBar.show(
                context, result['message'] ?? 'Error deleting note'.i18n);
          } catch (snackBarError) {
            debugPrint('Error showing snackbar: $snackBarError');
          }
        }
        // Recargar notas para restaurar si falló
        _loadNotes();
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error deleting note: $e');
      try {
        ErrorSnackBar.show(context, '${'Error deleting note'.i18n}: $e');
      } catch (snackBarError) {
        debugPrint('Error showing snackbar: $snackBarError');
      }
      _loadNotes();
    }
  }

  Future<void> _createNote() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditNoteScreen(
          notesRepository: _notesRepository,
        ),
      ),
    );
    if (created == true) {
      _loadNotes();
    }
  }

  Widget _buildSkeletons() {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.only(top: 8),
      itemBuilder: (context, index) {
        return ShimmerAnimation(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150 + (index * 20) % 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200 + (index * 30) % 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPreviewText(String content) {
    try {
      if (content.isEmpty) return 'No Content'.i18n;
      // Intenta decodificar JSON Delta
      final json = jsonDecode(content);
      final doc = Document.fromJson(json);
      return doc.toPlainText().replaceAll('\n', ' ').trim();
    } catch (e) {
      // Si falla, es texto plano legacy
      return content.replaceAll('\n', ' ').trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  title: Text(
                    'Notes'.i18n,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                  ),
                  centerTitle: false,
                  pinned: true,
                  expandedHeight: 80,
                  collapsedHeight: 44,
                  actions: [
                    // Edit button usually goes here in Apple Notes, but for now we might leave it or add bulk actions later
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 2.0),
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
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08),
                              ),
                            ),
                            child: SizedBox(
                          height: 36,
                          child: TextField(
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface, fontSize: 17),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: 'Search'.i18n,
                          hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 17),
                          prefixIcon: Icon(Icons.search,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 18),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 32, minHeight: 36),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: const EdgeInsets.only(right: 16),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() => _searchQuery = '');
                                    _loadNotes();
                                  },
                                  child: Icon(Icons.close,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      size: 18),
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _loadNotes();
                        },
                      ),
                    ),
                  ),
                  ),
                ),
              ),
              ),
                if (_isLoading)
                  SliverFillRemaining(
                    child: _buildSkeletons(),
                  )
                else if (_notes.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No have notes yet'.i18n,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 16),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final note = _notes[index];
                        final isLast = index == _notes.length - 1;

                        // Formato de fecha simplificado por ahora (idealmente usar una librería de formato)
                        // Aquí asumimos que no tenemos acceso a la fecha de creación/modificación en el modelo simple
                        // Si existe, se debería mostrar. Por defecto mostramos un placeholder o nada si no hay campo.
                        // Revisando el código anterior, Note no mostraba fecha, pero el diseño de Apple lleva fecha.
                        // Lo dejaremos sin fecha por compatibilidad inmediata hasta ver el modelo completo.

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Dismissible(
                              key: Key(note.localId ?? note.id.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                color: Colors.red,
                                child:
                                    Icon(Icons.delete, color: Theme.of(context).colorScheme.onSurface),
                            ),
                            confirmDismiss: (direction) async {
                              return await _showDeleteConfirmation(note);
                            },
                            onDismissed: (direction) {
                              // Llamar a performDelete sin UI confirm (ya hecha)
                              _performDelete(note);
                            },
                            child: InkWell(
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
                                if (edited == true) {
                                  _loadNotes();
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                        vertical: 12.0, horizontal: 16.0)
                                    .copyWith(left: 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note.title.isNotEmpty
                                          ? note.title
                                          : 'No Title'.i18n,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        // Fecha iría aquí
                                        // Text('10/10/24', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14)),
                                        // SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _getPreviewText(note.content),
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                           ),
                           if (!isLast)
                             Divider(
                               height: 1,
                               indent: 16,
                               endIndent: 16,
                               color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                             ),
                         ],
                       );
                       },
                       childCount: _notes.length,
                    ),
                  ),
              ],
            ),
          ),
          // Bottom toolbar
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.light ? Colors.white : const Color(0xFF2A2A2A)).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SafeArea(
                  child: Row(
                    children: [
                      Text(
                        '${_notes.length} ${'Notes'.i18n}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.edit_square, color: Theme.of(context).colorScheme.primary),
                        onPressed: _createNote,
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

  @override
  void dispose() {
    if (_syncListener != null) {
      try {
        context.read<SyncProvider>().removeListener(_syncListener!);
      } catch (_) {}
      _syncListener = null;
    }
    super.dispose();
  }
}
