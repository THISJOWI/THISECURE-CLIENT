import 'package:uuid/uuid.dart';
import 'package:thisjowi/data/models/password_entry.dart';
import 'package:thisjowi/services/telemetry_service.dart';
import 'package:thisjowi/utils/app_logger.dart';
import '../local/database.dart';
import '../../services/passwordService.dart';
import '../../services/connectivityService.dart';

/// Repository for managing passwords with offline-first approach
/// 
/// All operations go through local database first, then sync with backend
/// when connection is available
class PasswordsRepository {
  final AppDatabase _db = AppDatabase.instance();
  final Uuid _uuid = const Uuid();
  final PasswordService _passwordService = PasswordService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final Set<String> _syncingIds = {};
  bool _isSyncing = false;

  PasswordsRepository();

  /// Get all passwords from local database
  Future<Map<String, dynamic>> getAllPasswords({bool waitForSync = true}) async {
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

      final localPasswords = await _db.passwordsDao.getAllPasswords();
      final passwords = localPasswords
          .map((data) => PasswordEntry.fromJson(data))
          .toList();

      return {
        'success': true,
        'data': passwords,
        'message': 'Passwords loaded from local storage'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load passwords: $e',
        'data': <PasswordEntry>[]
      };
    }
  }

  /// Sync passwords from server to local database
  Future<void> _syncFromServer() async {    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final result = await _passwordService.fetchPasswords();
      
      if (result['success'] == true && result['data'] != null) {
        final serverPasswords = result['data'] as List;
        final allLocalPasswords = await _db.passwordsDao.getAllPasswords(includeDeleted: true);
        
        for (final item in serverPasswords) {
          // The server returns JSON with 'id' as the server ID.
          // We treat this as the serverId for our local storage.
          final serverId = item['id']?.toString();
          if (serverId == null || serverId.isEmpty) continue;
          
          // Check if exists locally by serverId
          final existingLocal = allLocalPasswords.firstWhere(
            (p) => p['serverId'] == serverId,
            orElse: () => <String, String?>{},
          );
          
          if (existingLocal.isNotEmpty) {
            // Check if local item is marked for deletion
            if (existingLocal['syncStatus'] == 'deleted') {
              continue;
            }

            // Update existing, but preserve local username if server returns empty
            // (handles transition period where existing server records lack username)
            final serverUsername = item['username'] as String?;
            final resolvedUsername = (serverUsername != null && serverUsername.isNotEmpty)
                ? serverUsername
                : (existingLocal['username'] as String? ?? '');

            await _db.passwordsDao.updatePassword(existingLocal['id'], {
              'title': item['title'] ?? '',
              'username': resolvedUsername,
              'password': item['password'] ?? '',
              'website': item['website'] ?? '',
              'notes': item['notes'] ?? '',
              'updatedAt': DateTime.now().toIso8601String(),
              'syncStatus': 'synced',
              'lastSyncedAt': DateTime.now().toIso8601String(),
            });
          } else {
            // Check for pending match
            // Match by title only to handle server records that may lack username
            final pendingMatch = allLocalPasswords.firstWhere(
              (p) => (p['syncStatus'] == 'pending' || p['syncStatus'] == 'error' || p['syncStatus'] == 'deleted') && 
                     p['title'] == (item['title'] ?? ''),
              orElse: () => <String, String?>{},
            );

            if (pendingMatch.isNotEmpty) {
               // Found a pending password that matches. Link it!
               final isDeleted = pendingMatch['syncStatus'] == 'deleted';
               
               await _db.passwordsDao.updatePassword(pendingMatch['id'], {
                 'serverId': serverId,
                 // Keep pending if other fields differ, but for now just link it
                 // Ideally we should check all fields, but let's assume if title/user match it's the same
                 'syncStatus': isDeleted ? 'deleted' : 'synced', 
                 'lastSyncedAt': DateTime.now().toIso8601String(),
               });
            } else {
              // Insert new from server
              final localId = _uuid.v4();
              await _db.passwordsDao.insertPassword({
                'id': localId,
                'title': item['title'] ?? '',
                'username': item['username'] ?? '',
                'password': item['password'] ?? '',
                'website': item['website'] ?? '',
                'notes': item['notes'] ?? '',
                'userId': item['userId']?.toString() ?? '',
                'createdAt': item['createdAt'] ?? DateTime.now().toIso8601String(),
                'updatedAt': item['updatedAt'] ?? DateTime.now().toIso8601String(),
                'serverId': serverId,
                'syncStatus': 'synced',
                'lastSyncedAt': DateTime.now().toIso8601String(),
              });
            }
          }
        }

        // Handle Deletions from Server
        final serverIds = serverPasswords.map((p) => p['id']?.toString()).where((id) => id != null).toSet();
        
        for (final localPassword in allLocalPasswords) {
          final localServerId = localPassword['serverId'];
          
          if (localServerId != null && 
              !serverIds.contains(localServerId)) {
            
            print('Deleting local password ${localPassword['id']} as it was deleted on server');
            await _db.passwordsDao.hardDeletePassword(localPassword['id']);
          }
        }
      }
    } catch (e) {
      print('Server sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Create a new password (FAST - saved locally, synced in background)
  Future<Map<String, dynamic>> addPassword(
    Map<String, dynamic> passwordData,
  ) async {
    try {
      final existing = await _db.passwordsDao.getAllPasswords();
      final title = passwordData['title'] ?? '';
      final dup = existing.any((p) => p['title'] == title);
      if (dup) {
        return {
          'success': false,
          'message': 'A password with this title already exists'
        };
      }

      final localId = _uuid.v4();
      final now = DateTime.now();

      final dataToSave = {
        'id': localId,
        'title': passwordData['title'] ?? '',
        'username': passwordData['username'] ?? '',
        'password': passwordData['password'] ?? '',
        'website': passwordData['website'] ?? '',
        'notes': passwordData['notes'] ?? '',
        'userId': passwordData['userId'] ?? '',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'syncStatus': 'pending',
      };

      // Save to local database first (FAST)
      await _db.passwordsDao.insertPassword(dataToSave);

      // Sync with backend in BACKGROUND (non-blocking)
      if (_connectivityService.isOnline) {
        _syncPasswordInBackground(localId, dataToSave);
      }

      TelemetryService.trackEvent('password_created');
      return {
        'success': true,
        'data': {'id': localId},
        'message': 'Password created successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create password: $e'
      };
    }
  }

  /// Sync a newly created password with backend
  Future<void> _syncPasswordInBackground(String localId, Map<String, dynamic> passwordData) async {
    if (_syncingIds.contains(localId)) return;
    _syncingIds.add(localId);

    try {
      final result = await _passwordService.addPassword(passwordData);
      
      if (result['success'] == true) {
        final serverData = result['data'];
        final serverId = serverData != null ? serverData['id']?.toString() : null;
        
        await _db.passwordsDao.updatePassword(localId, {
          'syncStatus': 'synced',
          'lastSyncedAt': DateTime.now().toIso8601String(),
          if (serverId != null) 'serverId': serverId,
        });
      } else {
        await _db.passwordsDao.updatePassword(localId, {
          'syncStatus': 'error',
        });
      }
    } catch (e) {
      print('Background password sync failed: $e');
      await _db.passwordsDao.updatePassword(localId, {
        'syncStatus': 'error',
      });
    } finally {
      _syncingIds.remove(localId);
    }
  }

  /// Update a password (FAST - saved locally, synced in background)
  Future<Map<String, dynamic>> updatePassword(
    String id,
    Map<String, dynamic> passwordData,
  ) async {
    try {
      final now = DateTime.now();

      final dataToUpdate = {
        'title': passwordData['title'],
        'username': passwordData['username'],
        'password': passwordData['password'],
        'website': passwordData['website'] ?? '',
        'notes': passwordData['notes'] ?? '',
        'updatedAt': now.toIso8601String(),
        'syncStatus': 'pending',
      };

      // Update in local database first (FAST)
      await _db.passwordsDao.updatePassword(id, dataToUpdate);

      // Sync with backend in BACKGROUND (non-blocking)
      if (_connectivityService.isOnline) {
        // We need the serverId to update on backend. 
        // We should fetch the current record to get serverId if not passed.
        // For simplicity, we assume the caller might not know serverId, so we check DB.
        final current = await _db.passwordsDao.getPasswordById(id);
        if (current != null && current['serverId'] != null) {
           _syncPasswordUpdateInBackground(id, current['serverId'], dataToUpdate);
        }
      }

      return {
        'success': true,
        'message': 'Password updated successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update password: $e'
      };
    }
  }

  /// Sync a password update with backend
  Future<void> _syncPasswordUpdateInBackground(String localId, String serverId, Map<String, dynamic> passwordData) async {
    if (_syncingIds.contains(localId)) return;
    _syncingIds.add(localId);

    try {
      final result = await _passwordService.updatePassword(serverId, passwordData);
      
      if (result['success'] == true) {
        await _db.passwordsDao.updatePassword(localId, {
          'syncStatus': 'synced',
          'lastSyncedAt': DateTime.now().toIso8601String(),
        });
      } else {
        await _db.passwordsDao.updatePassword(localId, {
          'syncStatus': 'error',
        });
      }
    } catch (e) {
      print('Background password update sync failed: $e');
      await _db.passwordsDao.updatePassword(localId, {
        'syncStatus': 'error',
      });
    } finally {
      _syncingIds.remove(localId);
    }
  }

  /// Delete a password (FAST - deleted locally, synced in background)
  Future<Map<String, dynamic>> deletePassword(String id, {String? serverId}) async {
    try {
      // Delete from local database first (FAST - Soft delete if synced)
      await _db.passwordsDao.deletePassword(id);

      // Sync with backend in BACKGROUND (non-blocking)
      if (serverId != null && _connectivityService.isOnline) {
        _syncPasswordDeletionInBackground(id, serverId);
      } else if (serverId == null) {
        // If not synced yet, hard delete immediately
        await _db.passwordsDao.hardDeletePassword(id);
      }

      TelemetryService.trackEvent('password_deleted');
      return {
        'success': true,
        'message': 'Password deleted successfully'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete password: $e'
      };
    }
  }

  /// Sync a password deletion with backend
  Future<void> _syncPasswordDeletionInBackground(String localId, String serverId) async {
    if (_syncingIds.contains(localId)) return;
    _syncingIds.add(localId);

    try {
      final result = await _passwordService.deletePassword(serverId);
      if (result['success'] == true) {
        // If successful, hard delete locally
        final count = await _db.passwordsDao.hardDeletePassword(localId);
        if (count == 0) {
           print('⚠️ Hard delete failed for $localId after server delete');
        }
      }
    } catch (e) {
      print('Background password deletion sync failed: $e');
    } finally {
      _syncingIds.remove(localId);
    }
  }

  /// Apply a remote change received via SSE.
  /// Fetches the specific password from the server by ID and inserts or updates
  /// the local record. This avoids the race condition of _syncFromServer().
  Future<void> applyRemoteChange(Map<String, dynamic> payload) async {
    final serverId = payload['id']?.toString();
    if (serverId == null || serverId.isEmpty) return;

    try {
      // Fetch the full password from the server (metadata-only event)
      final result = await _passwordService.getPasswordById(serverId);
      if (result['success'] != true || result['data'] == null) {
        appLog.w('PasswordsRepository.applyRemoteChange: failed to fetch password $serverId');
        return;
      }

      final item = result['data'] as Map<String, dynamic>;
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) return;

      final allLocal = await _db.passwordsDao.getAllPasswords(includeDeleted: true);
      final existing = allLocal.firstWhere(
        (p) => p['serverId'] == id,
        orElse: () => <String, dynamic>{},
      );

      if (existing.isNotEmpty) {
        // Update existing local record
        await _db.passwordsDao.updatePassword(existing['id'], {
          'title': item['title'] ?? existing['title'] ?? '',
          'username': item['username'] ?? existing['username'] ?? '',
          'password': item['password'] ?? existing['password'] ?? '',
          'website': item['website'] ?? existing['website'] ?? '',
          'notes': item['notes'] ?? existing['notes'] ?? '',
          'updatedAt': DateTime.now().toIso8601String(),
          'syncStatus': 'synced',
          'lastSyncedAt': DateTime.now().toIso8601String(),
        });
      } else {
        // Insert new record from server
        final localId = _uuid.v4();
        await _db.passwordsDao.insertPassword({
          'id': localId,
          'title': item['title'] ?? '',
          'username': item['username'] ?? '',
          'password': item['password'] ?? '',
          'website': item['website'] ?? '',
          'notes': item['notes'] ?? '',
          'userId': item['userId']?.toString() ?? '',
          'createdAt': item['createdAt'] ?? DateTime.now().toIso8601String(),
          'updatedAt': item['updatedAt'] ?? DateTime.now().toIso8601String(),
          'serverId': id,
          'syncStatus': 'synced',
          'lastSyncedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e, st) {
      appLog.e('PasswordsRepository.applyRemoteChange failed', error: e, stackTrace: st);
    }
  }

  /// Delete a local password by server ID (from SSE deleted event)
  Future<void> deleteLocalById(String serverId) async {
    try {
      final allLocal = await _db.passwordsDao.getAllPasswords(includeDeleted: true);
      final existing = allLocal.firstWhere(
        (p) => p['serverId'] == serverId,
        orElse: () => <String, dynamic>{},
      );

      if (existing.isNotEmpty) {
        await _db.passwordsDao.hardDeletePassword(existing['id']);
      }
    } catch (e) {
      appLog.e('PasswordsRepository.deleteLocalById failed', error: e);
    }
  }

  /// Search passwords locally
  Future<Map<String, dynamic>> searchPasswords(String query) async {
    try {
      final localPasswords = await _db.passwordsDao.searchPasswords(query);
      final passwords = localPasswords
          .map((data) => PasswordEntry.fromJson(data))
          .toList();

      return {
        'success': true,
        'data': passwords,
        'message': 'Search results'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to search passwords: $e',
        'data': <PasswordEntry>[]
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
      final pendingPasswords = await _db.passwordsDao.getUnsyncedPasswords();
      for (final pwdData in pendingPasswords) {
        final serverId = pwdData['serverId'];
        final localId = pwdData['id'];
        if (serverId != null && serverId.isNotEmpty) {
           await _syncPasswordUpdateInBackground(localId, serverId, pwdData);
        } else {
           await _syncPasswordInBackground(localId, pwdData);
        }
      }

      // Sync deletions
      final deletedPasswords = await _db.passwordsDao.getDeletedPasswords();
      for (final pwdData in deletedPasswords) {
        final serverId = pwdData['serverId'];
        final localId = pwdData['id'];
        if (serverId != null && serverId.isNotEmpty) {
          await _syncPasswordDeletionInBackground(localId, serverId);
        } else {
          await _db.passwordsDao.hardDeletePassword(localId);
        }
      }
    } catch (e) {
      print('Pending sync failed: $e');
    }
  }
}
