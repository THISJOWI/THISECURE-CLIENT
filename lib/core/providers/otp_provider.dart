import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:thisjowi/data/models/otp_entry.dart';
import 'package:thisjowi/data/repository/otp_repository.dart';

class OtpProvider extends ChangeNotifier {
  late final OtpRepository _repository;

  List<OtpEntry> _entries = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  Timer? _autoRefreshTimer;
  Timer? _searchDebounceTimer;

  List<OtpEntry>? _filteredCache;
  bool _filterDirty = true;

  OtpProvider() {
    _repository = OtpRepository();
  }

  List<OtpEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<OtpEntry> get filteredEntries {
    if (_filterDirty) {
      if (_searchQuery.isEmpty) {
        _filteredCache = _entries;
      } else {
        final query = _searchQuery.toLowerCase();
        _filteredCache = _entries.where((e) =>
            e.name.toLowerCase().contains(query) ||
            e.issuer.toLowerCase().contains(query)).toList();
      }
      _filterDirty = false;
    }
    return _filteredCache!;
  }

  void _markDirty() {
    _filterDirty = true;
    _filteredCache = null;
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    _errorMessage = '';
    _markDirty();

    final result = await _repository.getAllOtpEntries();

    if (result['success'] == true) {
      var entries = result['data'] as List<OtpEntry>? ?? [];
      final seenSecrets = <String>{};
      final uniqueEntries = <OtpEntry>[];
      for (final entry in entries) {
        if (!seenSecrets.contains(entry.secret)) {
          seenSecrets.add(entry.secret);
          uniqueEntries.add(entry);
        }
      }
      _entries = uniqueEntries;
    } else {
      _entries = [];
      _errorMessage = result['message'] ?? 'Error loading OTP entries';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addOtpEntry(Map<String, dynamic> entryData) async {
    final result = await _repository.addOtpEntry(entryData);

    if (result['success'] == true) {
      final newEntry = result['data'] as OtpEntry;
      _entries.add(newEntry);
      _errorMessage = '';
      _markDirty();
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Failed to add OTP entry';
      _markDirty();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addOtpFromUri(String uri) async {
    final result = await _repository.addOtpFromUri(uri, '');

    if (result['success'] == true) {
      await loadEntries();
      _errorMessage = '';
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Failed to add OTP entry';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOtpEntry(String id, {String? serverId}) async {
    final result = await _repository.deleteOtpEntry(id, serverId: serverId);

    if (result['success'] == true) {
      _entries.removeWhere((e) => e.id == id);
      _errorMessage = '';
      _markDirty();
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Failed to delete OTP entry';
      notifyListeners();
      return false;
    }
  }

  void setSearchQuery(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      _markDirty();
      notifyListeners();
    });
  }

  void clearSearch() {
    _searchDebounceTimer?.cancel();
    _searchQuery = '';
    _markDirty();
    notifyListeners();
  }

  Future<void> silentRefresh() async {
    if (_isLoading) return;
    final result = await _repository.getAllOtpEntries();
    if (result['success'] == true) {
      var entries = result['data'] as List<OtpEntry>? ?? [];
      final seenSecrets = <String>{};
      final uniqueEntries = <OtpEntry>[];
      for (final entry in entries) {
        if (!seenSecrets.contains(entry.secret)) {
          seenSecrets.add(entry.secret);
          uniqueEntries.add(entry);
        }
      }
      if (_entriesChanged(uniqueEntries)) {
        _entries = uniqueEntries;
        _markDirty();
        notifyListeners();
      }
    }
  }

  void startAutoRefresh({Duration refreshInterval = const Duration(seconds: 30)}) {
    if (_autoRefreshTimer != null && _autoRefreshTimer!.isActive) {
      return;
    }
    _autoRefreshTimer = Timer.periodic(refreshInterval, (_) async {
      if (!_isLoading) {
        await silentRefresh();
      }
    });
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  bool _entriesChanged(List<OtpEntry> newEntries) {
    if (_entries.length != newEntries.length) return true;
    for (int i = 0; i < _entries.length; i++) {
      if (_entries[i].id != newEntries[i].id || 
          _entries[i].secret != newEntries[i].secret) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
