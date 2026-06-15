import 'package:uuid/uuid.dart';
import 'package:thisjowi/data/models/otp_entry.dart' as model;
import 'package:thisjowi/utils/app_logger.dart';
import '../local/database.dart';
import '../../services/otpApiService.dart';
import '../../services/connectivityService.dart';
import '../local/secure_storage_service.dart';

/// Repository para gestionar las entradas OTP con enfoque offline-first
///
/// All operations go through local database first
class OtpRepository {
  final AppDatabase _db = AppDatabase.instance();
  final Uuid _uuid = const Uuid();
  final OtpApiService _otpApiService = OtpApiService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final SecureStorageService _secureStorageService = SecureStorageService();
  final Set<String> _syncingIds = {};
  bool _isSyncing = false;

  OtpRepository();

  /// Obtener todas las entradas OTP
  Future<Map<String, dynamic>> getAllOtpEntries() async {
    try {
      // Trigger background sync if online
      if (_connectivityService.isOnline) {
        _syncFromServer();
        _syncPendingToServer();
      }

      final localEntries = await _db.otpDao.getAllOtpEntries();
      final entries = localEntries
          .map((e) => model.OtpEntry.fromJson(e))
          .where((e) => e.secret.isNotEmpty && (e.name.isNotEmpty || e.issuer.isNotEmpty))
          .toList();
      return {
        'success': true,
        'data': entries,
        'message': 'OTP entries loaded'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load OTP entries: $e',
        'data': <model.OtpEntry>[]
      };
    }
  }

  /// Sync OTP entries from server to local database
  Future<void> _syncFromServer() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final result = await _otpApiService.getAllOtpEntries();
      
      if (result['success'] == true && result['data'] != null) {
        final serverEntries = result['data'] as List<model.OtpEntry>;
        
        // Get current user email to associate with synced entries
        final userEmail = await _secureStorageService.getValue('cached_email');
        if (userEmail == null) return;

        final allLocalEntries = await _db.otpDao.getAllOtpEntries(includeDeleted: true);

        for (final serverEntry in serverEntries) {
          if (serverEntry.id.isEmpty) continue;
          
          // Check if exists locally by serverId
          final existingLocal = allLocalEntries.firstWhere(
            (e) => e['serverId'] == serverEntry.id,
            orElse: () => <String, dynamic>{},
          );
          
          if (existingLocal.isNotEmpty) {
            // Check if local item is marked for deletion
            if (existingLocal['syncStatus'] == 'deleted') {
              continue;
            }

            // Update existing
            final updateData = {
              'name': serverEntry.name,
              'issuer': serverEntry.issuer,
              'digits': serverEntry.digits,
              'period': serverEntry.period,
              'algorithm': serverEntry.algorithm,
              'type': serverEntry.type,
              'updatedAt': DateTime.now().toIso8601String(),
              'syncStatus': 'synced',
              'lastSyncedAt': DateTime.now().toIso8601String(),
            };

            // Only update secret if server provides it and it's not empty
            if (serverEntry.secret.isNotEmpty) {
              updateData['secret'] = serverEntry.secret;
            }

            await _db.otpDao.updateOtpEntry(existingLocal['id'], updateData);
          } else {
            // Check for pending match
            final pendingMatch = allLocalEntries.firstWhere(
              (e) => (e['syncStatus'] == 'pending' || e['syncStatus'] == 'error' || e['syncStatus'] == 'deleted') && 
                     e['secret'] == serverEntry.secret,
              orElse: () => <String, dynamic>{},
            );

            if (pendingMatch.isNotEmpty) {
               // Found a pending entry that matches secret. Link it!
               final isDeleted = pendingMatch['syncStatus'] == 'deleted';
               
               await _db.otpDao.updateOtpEntry(pendingMatch['id'], {
                 'serverId': serverEntry.id,
                 'syncStatus': isDeleted ? 'deleted' : 'synced',
                 'lastSyncedAt': DateTime.now().toIso8601String(),
               });
            } else {
              // Insert new from server
              final localId = _uuid.v4();
              await _db.otpDao.insertOtpEntry({
                'id': localId,
                'name': serverEntry.name,
                'issuer': serverEntry.issuer,
                'secret': serverEntry.secret,
                'digits': serverEntry.digits,
                'period': serverEntry.period,
                'algorithm': serverEntry.algorithm,
                'type': serverEntry.type,
                'userId': userEmail, // Use local email instead of server ID
                'createdAt': serverEntry.createdAt.toIso8601String(),
                'updatedAt': serverEntry.updatedAt.toIso8601String(),
                'serverId': serverEntry.id,
                'syncStatus': 'synced',
                'lastSyncedAt': DateTime.now().toIso8601String(),
              });
            }
          }
        }

        // Handle Deletions from Server
        final serverIds = serverEntries.map((e) => e.id).where((id) => id.isNotEmpty).toSet();
        
        for (final localEntry in allLocalEntries) {
          final localServerId = localEntry['serverId'];
          
          if (localServerId != null && 
              !serverIds.contains(localServerId)) {
            
            appLog.i('Deleting local OTP ${localEntry['id']} as it was deleted on server');
            await _db.otpDao.hardDeleteOtpEntry(localEntry['id']);
          }
        }
      }
    } catch (e, st) {
      appLog.e('Server sync failed', error: e, stackTrace: st);
    } finally {
      _isSyncing = false;
    }
  }

  /// Crear una nueva entrada OTP (FAST - saved locally)
  Future<Map<String, dynamic>> addOtpEntry(Map<String, dynamic> entryData) async {
    try {
      final existing = await _db.otpDao.getAllOtpEntries();
      final name = entryData['name'] ?? '';
      final dup = existing.any((o) => o['name'] == name);
      if (dup) {
        return {
          'success': false,
          'message': 'An OTP entry with this name already exists'
        };
      }

      final id = _uuid.v4();
      final now = DateTime.now().toIso8601String();
      
      final entry = {
        ...entryData,
        'id': id,
        'createdAt': now,
        'updatedAt': now,
        'syncStatus': 'pending',
      };
      
      final createdEntry = model.OtpEntry.fromJson(entry);

      await _db.otpDao.insertOtpEntry(entry);

      // Sync with backend in BACKGROUND (non-blocking)
      if (_connectivityService.isOnline) {
        _syncOtpInBackground(id, createdEntry);
      }
      
      return {
        'success': true,
        'data': createdEntry,
        'message': 'OTP entry created'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create OTP entry: $e'
      };
    }
  }

  final Map<String, int> _syncRetries = {};

  /// Sync a newly created OTP entry with backend (max 5 retries)
  Future<void> _syncOtpInBackground(String localId, model.OtpEntry entry) async {
    if (_syncingIds.contains(localId)) return;
    _syncingIds.add(localId);

    int attempts = _syncRetries[localId] ?? 0;
    if (attempts >= 5) {
      _syncingIds.remove(localId);
      await _db.otpDao.updateOtpEntry(localId, {
        'syncStatus': 'failed',
      });
      return;
    }

    try {
      final result = await _otpApiService.createOtpEntry(entry);
      
      if (result['success'] == true && result['data'] != null) {
        final serverEntry = result['data'] as model.OtpEntry;

        await _db.otpDao.updateOtpEntry(localId, {
          'serverId': serverEntry.id,
          'syncStatus': 'synced',
          'lastSyncedAt': DateTime.now().toIso8601String(),
        });
        _syncRetries.remove(localId);
      } else {
        _syncRetries[localId] = attempts + 1;
        appLog.e('OTP sync failed (${attempts + 1}/5): ${result['message']}');
        await _db.otpDao.updateOtpEntry(localId, {
          'syncStatus': 'error',
        });
      }
    } catch (e, st) {
      _syncRetries[localId] = attempts + 1;
      appLog.e('Background sync failed (${attempts + 1}/5)', error: e, stackTrace: st);
      await _db.otpDao.updateOtpEntry(localId, {
        'syncStatus': 'error',
      });
    } finally {
      _syncingIds.remove(localId);
    }
  }

  /// Agregar OTP desde URI (otpauth://...) - FAST
  Future<Map<String, dynamic>> addOtpFromUri(String uriString, String userId) async {
    try {
      final uri = Uri.parse(uriString);
      if (uri.scheme != 'otpauth') {
        return {'success': false, 'message': 'Invalid URI scheme'};
      }

      final type = uri.host; // totp or hotp
      final path = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      // path usually is "Issuer:Account" or just "Account"
      
      String issuer = '';
      String account = path;
      
      if (path.contains(':')) {
        final parts = path.split(':');
        issuer = parts[0];
        account = parts.sublist(1).join(':');
      }

      final queryParams = uri.queryParameters;
      final secret = queryParams['secret'];
      final issuerParam = queryParams['issuer'];
      if (issuerParam != null && issuerParam.isNotEmpty) {
        issuer = issuerParam;
      }
      
      final algorithm = queryParams['algorithm'] ?? 'SHA1';
      final digits = int.tryParse(queryParams['digits'] ?? '6') ?? 6;
      final period = int.tryParse(queryParams['period'] ?? '30') ?? 30;

      if (secret == null) {
        return {'success': false, 'message': 'Missing secret in URI'};
      }

      final entryData = {
        'name': account,
        'issuer': issuer,
        'secret': secret,
        'type': type,
        'algorithm': algorithm,
        'digits': digits,
        'period': period,
        'userId': userId,
      };

      return await addOtpEntry(entryData);
    } catch (e) {
      return {'success': false, 'message': 'Failed to import URI: $e'};
    }
  }

  /// Actualizar una entrada OTP
  Future<Map<String, dynamic>> updateOtpEntry(
    String id,
    Map<String, dynamic> entryData,
  ) async {
    try {
      final now = DateTime.now().toIso8601String();
      final updateData = {
        ...entryData,
        'updatedAt': now,
        'syncStatus': 'pending',
      };
      
      await _db.otpDao.updateOtpEntry(id, updateData);
      
      // Fetch updated
      final updated = await _db.otpDao.getOtpEntryById(id);
      
      if (updated != null) {
        final updatedEntry = model.OtpEntry.fromJson(updated);
        
        // Sync with backend in BACKGROUND (non-blocking)
        if (_connectivityService.isOnline) {
          _syncOtpUpdateInBackground(id, updatedEntry);
        }
        
        return {
          'success': true,
          'data': updatedEntry,
          'message': 'OTP entry updated'
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to fetch updated entry'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update OTP entry: $e'
      };
    }
  }

  /// Sync an OTP update with backend
  Future<void> _syncOtpUpdateInBackground(String localId, model.OtpEntry entry) async {
    // If entry doesn't have server ID, we can't update it on server yet
    if (entry.serverId == null) return;
    if (_syncingIds.contains(localId)) return;
    _syncingIds.add(localId);

    try {
      final result = await _otpApiService.updateOtpEntry(entry.serverId!, entry);
      
      if (result['success'] == true) {
        await _db.otpDao.updateOtpEntry(localId, {
          'syncStatus': 'synced',
          'lastSyncedAt': DateTime.now().toIso8601String(),
        });
      } else {
        appLog.e('OTP update sync failed: ${result['message']}');
        await _db.otpDao.updateOtpEntry(localId, {
          'syncStatus': 'error',
        });
      }
    } catch (e, st) {
      appLog.e('Background update sync failed', error: e, stackTrace: st);
      await _db.otpDao.updateOtpEntry(localId, {
        'syncStatus': 'error',
      });
    } finally {
      _syncingIds.remove(localId);
    }
  }

  /// Eliminar una entrada OTP (FAST - deleted locally)
  Future<Map<String, dynamic>> deleteOtpEntry(String id, {String? serverId}) async {
    try {
      // Delete from local database first (FAST - Soft delete if synced)
      await _db.otpDao.deleteOtpEntry(id);

      // Sync with backend in BACKGROUND (non-blocking)
      if (serverId != null && _connectivityService.isOnline) {
        _syncOtpDeletionInBackground(id, serverId);
      }

      return {
        'success': true,
        'message': 'OTP entry deleted'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete OTP entry: $e'
      };
    }
  }

  /// Sync an OTP deletion with backend
  Future<void> _syncOtpDeletionInBackground(String localId, String serverId) async {
    if (_syncingIds.contains(localId)) return;
    _syncingIds.add(localId);

    try {
      final result = await _otpApiService.deleteOtpEntry(serverId);
      if (result['success'] == true) {
        await _db.otpDao.hardDeleteOtpEntry(localId);
      } else {
        appLog.e('OTP deletion sync failed: ${result['message']}');
      }
    } catch (e, st) {
      appLog.e('Background deletion sync failed', error: e, stackTrace: st);
    } finally {
      _syncingIds.remove(localId);
    }
  }

  /// Buscar entradas OTP
  Future<Map<String, dynamic>> searchOtpEntries(String query) async {
    try {
      final localEntries = await _db.otpDao.searchOtpEntries(query);
      final entries = localEntries.map((e) => model.OtpEntry.fromJson(e)).toList();

      return {
        'success': true,
        'data': entries,
        'message': 'Search completed'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Search failed: $e',
        'data': <model.OtpEntry>[]
      };
    }
  }

  /// Get a single OTP entry by ID
  Future<Map<String, dynamic>> getOtpEntry(String id) async {
    try {
      final entry = await _db.otpDao.getOtpEntryById(id);
      if (entry == null) {
        return {'success': false, 'message': 'Entry not found'};
      }
      return {
        'success': true,
        'data': model.OtpEntry.fromJson(entry)
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Force a manual sync with the backend
  Future<Map<String, dynamic>> forceSync() async {
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
      final pendingEntries = await _db.otpDao.getUnsyncedOtpEntries();
      for (final entryData in pendingEntries) {
        final entry = model.OtpEntry.fromJson(entryData);
        if (entry.serverId != null && entry.serverId!.isNotEmpty) {
           await _syncOtpUpdateInBackground(entry.id, entry);
        } else {
           await _syncOtpInBackground(entry.id, entry);
        }
      }

      // Sync deletions
      final deletedEntries = await _db.otpDao.getDeletedOtpEntries();
      for (final entryData in deletedEntries) {
        final entry = model.OtpEntry.fromJson(entryData);
        if (entry.serverId != null && entry.serverId!.isNotEmpty) {
          await _syncOtpDeletionInBackground(entry.id, entry.serverId!);
        } else {
          // If no serverId, just hard delete
          await _db.otpDao.hardDeleteOtpEntry(entry.id);
        }
      }
    } catch (e, st) {
      appLog.e('Pending sync failed', error: e, stackTrace: st);
    }
  }

  /// Apply a remote change received via SSE.
  /// Fetches the specific OTP entry from the server by ID and inserts or updates
  /// the local record. This avoids the race condition of _syncFromServer().
  Future<void> applyRemoteChange(Map<String, dynamic> payload) async {
    final serverId = payload['id']?.toString();
    if (serverId == null || serverId.isEmpty) return;

    try {
      // Fetch the full OTP entry from the server (metadata-only event)
      final result = await _otpApiService.getOtpById(serverId);
      if (result['success'] != true || result['data'] == null) {
        appLog.w('OtpRepository.applyRemoteChange: failed to fetch OTP $serverId');
        return;
      }

      final entry = result['data'] as model.OtpEntry;
      if (entry.id.isEmpty) return;

      final allLocal = await _db.otpDao.getAllOtpEntries(includeDeleted: true);
      final existing = allLocal.firstWhere(
        (e) => e['serverId'] == entry.id,
        orElse: () => <String, dynamic>{},
      );

      if (existing.isNotEmpty) {
        // Update existing local record
        final updateData = <String, dynamic>{
          'name': entry.name,
          'issuer': entry.issuer,
          'digits': entry.digits,
          'period': entry.period,
          'algorithm': entry.algorithm,
          'type': entry.type,
          'updatedAt': DateTime.now().toIso8601String(),
          'syncStatus': 'synced',
          'lastSyncedAt': DateTime.now().toIso8601String(),
        };
        if (entry.secret.isNotEmpty) {
          updateData['secret'] = entry.secret;
        }
        await _db.otpDao.updateOtpEntry(existing['id'], updateData);
      } else {
        // Insert new record from server
        final localId = _uuid.v4();
        await _db.otpDao.insertOtpEntry({
          'id': localId,
          'name': entry.name,
          'issuer': entry.issuer,
          'secret': entry.secret,
          'digits': entry.digits,
          'period': entry.period,
          'algorithm': entry.algorithm,
          'type': entry.type,
          'userId': await _secureStorageService.getValue('cached_email') ?? '',
          'createdAt': entry.createdAt.toIso8601String(),
          'updatedAt': entry.updatedAt.toIso8601String(),
          'serverId': entry.id,
          'syncStatus': 'synced',
          'lastSyncedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e, st) {
      appLog.e('OtpRepository.applyRemoteChange failed', error: e, stackTrace: st);
    }
  }

  /// Delete a local entry by server ID (from SSE deleted event)
  Future<void> deleteLocalById(String serverId) async {
    try {
      final existing = await _db.otpDao.getOtpEntryByServerId(serverId);
      if (existing != null) {
        await _db.otpDao.hardDeleteOtpEntry(existing['id']);
      }
    } catch (e, st) {
      appLog.e('OtpRepository.applyRemoteChange failed', error: e, stackTrace: st);
    }
  }

  /// Get sync status for an OTP entry
  Future<String> getSyncStatus(String id) async {
    final entry = await _db.otpDao.getOtpEntryById(id);
    return entry?['syncStatus'] ?? 'unknown';
  }

  /// Get all pending sync entries count
  Future<int> getPendingSyncCount() async {
    final unsynced = await _db.otpDao.getUnsyncedOtpEntries();
    final deleted = await _db.otpDao.getDeletedOtpEntries();
    return unsynced.length + deleted.length;
  }

  /// Check if there are pending changes to sync
  Future<bool> hasPendingChanges() async {
    return (await getPendingSyncCount()) > 0;
  }

  /// Export OTP entry as URI
  String exportToUri(model.OtpEntry entry) {
    final label = entry.issuer.isNotEmpty 
        ? '${Uri.encodeComponent(entry.issuer)}:${Uri.encodeComponent(entry.name)}'
        : Uri.encodeComponent(entry.name);
        
    var uri = 'otpauth://${entry.type}/$label?secret=${entry.secret}';
    
    if (entry.issuer.isNotEmpty) {
      uri += '&issuer=${Uri.encodeComponent(entry.issuer)}';
    }
    
    if (entry.algorithm != 'SHA1') {
      uri += '&algorithm=${entry.algorithm}';
    }
    
    if (entry.digits != 6) {
      uri += '&digits=${entry.digits}';
    }
    
    if (entry.period != 30) {
      uri += '&period=${entry.period}';
    }
    
    return uri;
  }
}
