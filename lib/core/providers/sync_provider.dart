import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:thisjowi/data/models/sync_event.dart';
import 'package:thisjowi/data/repository/notes_repository.dart';
import 'package:thisjowi/data/repository/otp_repository.dart';
import 'package:thisjowi/data/repository/passwordsRepository.dart';
import 'package:thisjowi/data/repository/profile_repository.dart';
import 'package:thisjowi/services/sync_service.dart';
import 'package:thisjowi/utils/app_logger.dart';

class SyncProvider extends ChangeNotifier {
  static SyncProvider? _instance;
  static SyncProvider get instance => _instance ?? SyncProvider();

  final SyncService _syncService = SyncService();

  StreamSubscription<SyncEvent>? _eventSub;
  StreamSubscription<bool>? _connectionSub;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String _lastEventInfo = '';
  String get lastEventInfo => _lastEventInfo;

  DateTime? _profileLastUpdated;
  DateTime? get profileLastUpdated => _profileLastUpdated;

  DateTime? _accountLastUpdated;
  DateTime? get accountLastUpdated => _accountLastUpdated;

  late final PasswordsRepository _passwordsRepository;
  late final NotesRepository _notesRepository;
  late final OtpRepository _otpRepository;
  late final ProfileRepository _profileRepository;

  SyncProvider() {
    _instance = this;
    
    _passwordsRepository = PasswordsRepository();
    _notesRepository = NotesRepository();
    _otpRepository = OtpRepository();
    _profileRepository = ProfileRepository();
  }

  Future<void> start() async {
    if (_isConnected) return;

    _connectionSub?.cancel();
    _connectionSub = _syncService.connectionStatus.listen((connected) {
      _isConnected = connected;
      notifyListeners();
    });

    _eventSub?.cancel();
    _eventSub = _syncService.events.listen(
      _onSyncEvent,
      onError: (e) => appLog.e('SyncProvider: stream error', error: e),
      onDone: () => appLog.i('SyncProvider: stream closed'),
    );

    await _syncService.connect();
  }

  Future<void> stop() async {
    await _syncService.disconnect();
    _isConnected = false;
    notifyListeners();
  }

  Future<void> reconnect() async {
    await stop();
    await start();
  }

  Future<void> _onSyncEvent(SyncEvent event) async {
    _lastEventInfo = '${event.serviceName}/${event.action}';

    switch (event.serviceName) {
      case 'password':
        await _handlePasswordEvent(event);
        break;
      case 'note':
        await _handleNoteEvent(event);
        break;
      case 'otp':
        await _handleOtpEvent(event);
        break;
      case 'message':
        _handleMessageEvent(event);
        break;
      case 'profile':
        await _handleProfileEvent(event);
        break;
      case 'account':
        await _handleAccountEvent(event);
        break;
      default:
        appLog.w('SyncProvider: unknown serviceName "${event.serviceName}"');
    }

    notifyListeners();
  }

  Future<void> _handlePasswordEvent(SyncEvent event) async {
    switch (event.action) {
      case 'created':
      case 'updated':
        await _passwordsRepository.applyRemoteChange(event.payload);
        break;
      case 'deleted':
        final id = event.payload['id']?.toString();
        if (id != null) {
          await _passwordsRepository.deleteLocalById(id);
        }
        break;
    }
  }

  Future<void> _handleNoteEvent(SyncEvent event) async {
    switch (event.action) {
      case 'created':
      case 'updated':
        await _notesRepository.applyRemoteChange(event.payload);
        break;
      case 'deleted':
        final id = event.payload['id']?.toString();
        if (id != null) {
          await _notesRepository.deleteLocalById(id);
        }
        break;
    }
  }

  Future<void> _handleOtpEvent(SyncEvent event) async {
    switch (event.action) {
      case 'created':
      case 'updated':
        await _otpRepository.applyRemoteChange(event.payload);
        break;
      case 'deleted':
        final id = event.payload['id']?.toString();
        if (id != null) {
          await _otpRepository.deleteLocalById(id);
        }
        break;
    }
  }

  void _handleMessageEvent(SyncEvent event) {
    appLog.d('SyncProvider: message event received (id=${event.payload['messageId']})');
  }

  Future<void> _handleProfileEvent(SyncEvent event) async {
    appLog.i('SyncProvider: profile ${event.action} — applying to local DB');
    switch (event.action) {
      case 'created':
      case 'updated':
        await _profileRepository.applyRemoteChange(event.payload);
        break;
      case 'deleted':
        final userId = event.payload['userId']?.toString();
        if (userId != null) {
          await _profileRepository.deleteLocalById(userId);
        }
        break;
    }
    _profileLastUpdated = DateTime.now();
  }

  Future<void> _handleAccountEvent(SyncEvent event) async {
    appLog.i('SyncProvider: account ${event.action} — applying to local DB');
    switch (event.action) {
      case 'created':
      case 'updated':
        await _profileRepository.applyRemoteChange(event.payload);
        break;
      case 'deleted':
        final userId = event.payload['userId']?.toString();
        if (userId != null) {
          await _profileRepository.deleteLocalById(userId);
        }
        break;
    }
    _accountLastUpdated = DateTime.now();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _connectionSub?.cancel();
    _syncService.dispose();
    super.dispose();
  }
}
