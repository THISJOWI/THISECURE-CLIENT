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

  OtpProvider() {
    
    _repository = OtpRepository();
  }

  List<OtpEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  // Get filtered entries based on search query
  List<OtpEntry> get filteredEntries {
    if (_searchQuery.isEmpty) {
      return _entries;
    }
    return _entries.where((e) =>
        e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        e.issuer.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  /// Load all OTP entries from the repository
  Future<void> loadEntries() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    final result = await _repository.getAllOtpEntries();

    if (result['success'] == true) {
      var entries = result['data'] as List<OtpEntry>? ?? [];

      // Deduplicate entries based on secret to prevent UI duplicates
      final seenSecrets = <String>{};
      final uniqueEntries = <OtpEntry>[];
      for (final entry in entries) {
        if (!seenSecrets.contains(entry.secret)) {
          seenSecrets.add(entry.secret);
          uniqueEntries.add(entry);
        }
      }

      _entries = uniqueEntries;
      _isLoading = false;
    } else {
      _entries = [];
      _errorMessage = result['message'] ?? 'Error loading OTP entries';
      _isLoading = false;
    }

    notifyListeners();
  }

  /// Add a new OTP entry
  Future<bool> addOtpEntry(Map<String, dynamic> entryData) async {
    final result = await _repository.addOtpEntry(entryData);

    if (result['success'] == true) {
      // Add the new entry to the list immediately for instant UI update
      final newEntry = result['data'] as OtpEntry;
      _entries.add(newEntry);
      _errorMessage = '';
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Failed to add OTP entry';
      notifyListeners();
      return false;
    }
  }

  /// Add OTP from URI (otpauth://...)
  Future<bool> addOtpFromUri(String uri) async {
    final result = await _repository.addOtpFromUri(uri, '');

    if (result['success'] == true) {
      // Reload entries to ensure consistency
      await loadEntries();
      _errorMessage = '';
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Failed to add OTP entry';
      notifyListeners();
      return false;
    }
  }

  /// Delete an OTP entry
  Future<bool> deleteOtpEntry(String id, {String? serverId}) async {
    final result = await _repository.deleteOtpEntry(id, serverId: serverId);

    if (result['success'] == true) {
      _entries.removeWhere((e) => e.id == id);
      _errorMessage = '';
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Failed to delete OTP entry';
      notifyListeners();
      return false;
    }
  }

  /// Update search query and filter entries with debounce
  void setSearchQuery(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      notifyListeners();
    });
  }

  /// Clear search query
  void clearSearch() {
    _searchDebounceTimer?.cancel();
    _searchQuery = '';
    notifyListeners();
  }

  /// Silent refresh triggered by SSE sync events.
  /// Unlike [loadEntries], this does not show a loading spinner.
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
        notifyListeners();
      }
    }
  }

  /// Start auto-refresh of OTP entries (fallback when SSE is not connected).
  /// The 3s polling is kept for backward compatibility when real-time sync
  /// is unavailable, but the interval is increased to 30s to reduce overhead.
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

  /// Stop auto-refresh of OTP entries
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  /// Check if entries have changed
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
