import 'package:uuid/uuid.dart';
import 'package:thisjowi/data/models/note_entry.dart' as models;
import 'package:thisjowi/services/telemetry_service.dart';
import 'package:thisjowi/utils/app_logger.dart';
import '../local/database.dart';
import '../../services/notesService.dart';
import '../../services/connectivityService.dart';

/// Repository for managing notes with offline-first approach
///
/// All operations go through local database first, then sync with backend
/// when connection is available
class NotesRepository {
  final AppDatabase _db = AppDatabase.instance();
  final Uuid _uuid = const Uuid();
  final NotesService _notesService = NotesService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final Set<String> _syncingIds = {};
  bool _isSyncing = false;

  NotesRepository();

  /// Get all notes from local database
  Future<Map<String, dynamic>> getAllNotes({bool waitForSync = true}) async {
    try {
      // Trigger sync if online - WAIT for completion to avoid duplicate creates
      if (_connectivityService.isOnline) {
        if (waitForSync) {
          await _syncFromServer();
          await _syncPendingToServer();
        } else {
          // Fire-and-forget for background refresh
          _syncFromServer();
          _syncPendingToServer();
        }
      }

      final localNotes = await _db.notesDao.getAllNotes();
      final notes = localNotes.map((data) => models.Note.fromJson(data)).toList();

      return {
        'success': true,
        'data': notes,
        'message': 'Notes loaded from local storage'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load notes: $e',
        'data': <models.Note>[]
      };
    }
  }

  /// Sync notes from server to local database
  Future<void> _syncFromServer() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final result = await _notesService.getAllNotes();
      
      if (result['success'] == true && result['data'] != null) {
        final serverNotes = result['data'] as List<models.Note>;
        final allLocalNotes = await _db.notesDao.getAllNotes(includeDeleted: true);
        
        for (final serverNote in serverNotes) {
          if (serverNote.id == null) continue;
          
          // Check if exists locally by serverId
          final existingLocal = allLocalNotes.firstWhere(
            (n) => n['serverId'] == serverNote.id,
            orElse: () => <String, dynamic>{},
          );
          
          if (existingLocal.isNotEmpty) {
            // Check if local item is marked for deletion
            if (existingLocal['syncStatus'] == 'deleted') {
              continue;
            }

            // Update existing
            await _db.notesDao.updateNote(existingLocal['localId'], {
              'title': serverNote.title,
              'content': serverNote.content,
              'updatedAt': DateTime.now().toIso8601String(),
              'syncStatus': 'synced',
              'lastSyncedAt': DateTime.now().toIso8601String(),
            });
          } else {
            // Check for pending match to avoid duplicates
            // We match by title only because title is unique on server
            final pendingMatch = allLocalNotes.firstWhere(
              (n) => (n['syncStatus'] == 'pending' || n['syncStatus'] == 'error' || n['syncStatus'] == 'deleted') && 
                     n['title'] == serverNote.title,
              orElse: () => <String, dynamic>{},
            );

            if (pendingMatch.isNotEmpty) {
               // Found a pending note that matches title. Link it!
               // We keep syncStatus as 'pending' if content differs so we push our local changes
               // But if content is same, we mark as synced.
               final isContentSame = pendingMatch['content'] == serverNote.content;
               final isDeleted = pendingMatch['syncStatus'] == 'deleted';
               
               await _db.notesDao.updateNote(pendingMatch['localId'], {
                 'serverId': serverNote.id,
                 'syncStatus': isDeleted ? 'deleted' : (isContentSame ? 'synced' : 'pending'),
                 'lastSyncedAt': DateTime.now().toIso8601String(),
               });
            } else {
              // Insert new from server
              final localId = _uuid.v4();
              await _db.notesDao.insertNote({
                'localId': localId,
                'title': serverNote.title,
                'content': serverNote.content,
                'createdAt': serverNote.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
                'updatedAt': serverNote.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
                'serverId': serverNote.id,
                'syncStatus': 'synced',
                'lastSyncedAt': DateTime.now().toIso8601String(),
              });
            }
          }
        }

        // Handle Deletions from Server
        // If a note exists locally with a serverId but is missing from server response,
        // it means it was deleted on another device.
        final serverIds = serverNotes.map((n) => n.id).toSet();
        
        for (final localNote in allLocalNotes) {
          final localServerId = localNote['serverId'];
          
          if (localServerId != null && 
              !serverIds.contains(localServerId)) {
            // Delete locally (Hard delete because it's gone from server)
            await _db.notesDao.hardDeleteNote(localNote['localId']);
          }
        }
      }
    } catch (e) {
      print('Server sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Create a new note (FAST - saved locally, synced in background)
  Future<Map<String, dynamic>> createNote(models.Note note) async {
    try {
      final existing = await _db.notesDao.getAllNotes();
      final dup = existing.any((n) =>
          n['title'] == note.title && n['localId'] != note.localId);
      if (dup) {
        return {
          'success': false,
          'message': 'A note with this title already exists'
        };
      }

      final localId = _uuid.v4();
      final now = DateTime.now();

      final noteData = {
        'title': note.title,
        'content': note.content,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'syncStatus': 'pending',
        'localId': localId,
      };

      // Save to local database first (FAST)
      await _db.notesDao.insertNote(noteData);

      final createdNote = note.copyWith(
        localId: localId,
        createdAt: now,
        updatedAt: now,
        syncStatus: 'pending',
      );

      // Sync with backend in BACKGROUND (non-blocking)
      if (_connectivityService.isOnline) {
        _syncNoteInBackground(localId, createdNote);
      }

      TelemetryService.trackEvent('note_created');
      return {
        'success': true,
        'data': createdNote,
        'message': 'Note created successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create note: $e'
      };
    }
  }

  /// Sync a newly created note with backend
  Future<void> _syncNoteInBackground(String localId, models.Note note) async {
    if (_syncingIds.contains(localId)) return;
    _syncingIds.add(localId);

    try {
      final result = await _notesService.createNote(note);
      
      if (result['success'] == true && result['data'] != null) {
        final serverNote = result['data'] as models.Note;
        
        // Update local record with server ID and synced status
        await _db.notesDao.updateNote(localId, {
          'serverId': serverNote.id,
          'syncStatus': 'synced',
          'lastSyncedAt': DateTime.now().toIso8601String(),
        });
      } else {
        // Mark as error if sync failed
        await _db.notesDao.updateNote(localId, {
          'syncStatus': 'error',
        });
      }
    } catch (e) {
      print('Background sync failed: $e');
      // Mark as error
      await _db.notesDao.updateNote(localId, {
        'syncStatus': 'error',
      });
    } finally {
      _syncingIds.remove(localId);
    }
  }

  /// Update a note (FAST - saved locally, synced in background)
  Future<Map<String, dynamic>> updateNote(String localId, models.Note note) async {
    try {
      final existing = await _db.notesDao.getAllNotes();
      final dup = existing.any((n) =>
          n['title'] == note.title && n['localId'] != localId);
      if (dup) {
        return {
          'success': false,
          'message': 'A note with this title already exists'
        };
      }

      final now = DateTime.now();

      final noteData = {
        'title': note.title,
        'content': note.content,
        'updatedAt': now.toIso8601String(),
        'syncStatus': 'pending',
      };

      // Update in local database first (FAST)
      await _db.notesDao.updateNote(localId, noteData);

      final updatedNote = note.copyWith(
        updatedAt: now,
        syncStatus: 'pending',
      );

      // Sync with backend in BACKGROUND (non-blocking)
      if (_connectivityService.isOnline) {
        _syncNoteUpdateInBackground(localId, updatedNote);
      }

      return {
        'success': true,
        'data': updatedNote,
        'message': 'Note updated successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update note: $e'
      };
    }
  }

  /// Sync a note update with backend
  Future<void> _syncNoteUpdateInBackground(String localId, models.Note note) async {
    // If note doesn't have server ID, we can't update it on server yet
    // It will be handled by the create sync or a full sync
    if (note.serverId == null) return;
    
    if (_syncingIds.contains(localId)) return;
    _syncingIds.add(localId);

    try {
      final result = await _notesService.updateNote(note.serverId!, note);
      
      if (result['success'] == true) {
        // Update local record as synced
        await _db.notesDao.updateNote(localId, {
          'syncStatus': 'synced',
          'lastSyncedAt': DateTime.now().toIso8601String(),
        });
      } else {
        await _db.notesDao.updateNote(localId, {
          'syncStatus': 'error',
        });
      }
    } catch (e) {
      print('Background update sync failed: $e');
      await _db.notesDao.updateNote(localId, {
        'syncStatus': 'error',
      });
    } finally {
      _syncingIds.remove(localId);
    }
  }

  /// Delete a note (FAST - deleted locally, synced in background)
  Future<Map<String, dynamic>> deleteNote(String localId, {String? serverId}) async {
    try {
      // Delete from local database first (FAST - Soft delete if synced)
      await _db.notesDao.deleteNote(localId);

      // Sync with backend in BACKGROUND (non-blocking)
      if (serverId != null && _connectivityService.isOnline) {
        _syncNoteDeletionInBackground(localId, serverId);
      } else if (serverId == null) {
        // If not synced yet, hard delete immediately
        await _db.notesDao.hardDeleteNote(localId);
      }

      TelemetryService.trackEvent('note_deleted');
      return {
        'success': true,
        'message': 'Note deleted successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete note: $e'
      };
    }
  }

  /// Sync a note deletion with backend
  Future<void> _syncNoteDeletionInBackground(String localId, String serverId) async {
    if (_syncingIds.contains(localId)) return;
    _syncingIds.add(localId);

    try {
      final result = await _notesService.deleteNote(int.parse(serverId));
      if (result['success'] == true) {
        // If successful, hard delete locally
        final count = await _db.notesDao.hardDeleteNote(localId);
        if (count == 0) {
           print('⚠️ Hard delete failed for $localId after server delete');
        }
      }
    } catch (e) {
      print('Background deletion sync failed: $e');
    } finally {
      _syncingIds.remove(localId);
    }
  }

  /// Apply a remote change received via SSE.
  /// Fetches the specific note from the server by ID and inserts or updates
  /// the local record. This avoids the race condition of _syncFromServer().
  Future<void> applyRemoteChange(Map<String, dynamic> payload) async {
    final serverId = payload['id']?.toString();
    if (serverId == null || serverId.isEmpty) return;

    try {
      final serverIdInt = int.tryParse(serverId);
      if (serverIdInt == null) return;

      // Fetch the full note from the server (metadata-only event)
      final result = await _notesService.getNoteById(serverIdInt);
      if (result['success'] != true || result['data'] == null) {
        appLog.w('NotesRepository.applyRemoteChange: failed to fetch note $serverId');
        return;
      }

      final note = result['data'] as models.Note;
      if (note.id == null) return;

      final allLocal = await _db.notesDao.getAllNotes(includeDeleted: true);
      final existing = allLocal.firstWhere(
        (n) => n['serverId'] == note.id,
        orElse: () => <String, dynamic>{},
      );

      if (existing.isNotEmpty) {
        // Update existing local record
        await _db.notesDao.updateNote(existing['localId'], {
          'title': note.title,
          'content': note.content,
          'updatedAt': DateTime.now().toIso8601String(),
          'syncStatus': 'synced',
          'lastSyncedAt': DateTime.now().toIso8601String(),
        });
      } else {
        // Insert new record from server
        final localId = _uuid.v4();
        await _db.notesDao.insertNote({
          'localId': localId,
          'title': note.title,
          'content': note.content,
          'createdAt': note.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'updatedAt': note.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'serverId': note.id,
          'syncStatus': 'synced',
          'lastSyncedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e, st) {
      appLog.e('NotesRepository.applyRemoteChange failed', error: e, stackTrace: st);
    }
  }

  /// Delete a local note by server ID (from SSE deleted event)
  Future<void> deleteLocalById(String serverId) async {
    try {
      final serverIdInt = int.tryParse(serverId);
      if (serverIdInt == null) return;

      final existing = await _db.notesDao.getNoteByServerId(serverIdInt);
      if (existing != null) {
        await _db.notesDao.hardDeleteNote(existing['localId']);
      }
    } catch (e) {
      appLog.e('NotesRepository.deleteLocalById failed', error: e);
    }
  }

  /// Search notes locally
  Future<Map<String, dynamic>> searchNotes(String query) async {
    try {
      final localNotes = await _db.notesDao.searchNotes(query);
      final notes = localNotes.map((data) => models.Note.fromJson(data)).toList();

      return {
        'success': true,
        'data': notes,
        'message': 'Search results'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to search notes: $e',
        'data': <models.Note>[]
      };
    }
  }

  /// Force sync all pending changes
  Future<Map<String, dynamic>> syncAll() async {
    if (!_connectivityService.isOnline) {
      return {'success': false, 'message': 'No internet connection'};
    }
    
    await _syncFromServer();
    await _syncPendingToServer();
    
    return {'success': true, 'message': 'Sync completed'};
  }

  /// Sync pending local changes to server
  Future<void> _syncPendingToServer() async {
    try {
      // Sync updates/creates
      final pendingNotes = await _db.notesDao.getUnsyncedNotes();
      for (final noteData in pendingNotes) {
        final note = models.Note.fromJson(noteData);
        if (note.serverId != null) {
           await _syncNoteUpdateInBackground(note.localId!, note);
        } else {
           await _syncNoteInBackground(note.localId!, note);
        }
      }

      // Sync deletions
      final deletedNotes = await _db.notesDao.getDeletedNotes();
      for (final noteData in deletedNotes) {
        final note = models.Note.fromJson(noteData);
        if (note.serverId != null) {
          await _syncNoteDeletionInBackground(note.localId!, note.serverId.toString());
        } else {
          await _db.notesDao.hardDeleteNote(note.localId!);
        }
      }
    } catch (e) {
      print('Pending sync failed: $e');
    }
  }
}
