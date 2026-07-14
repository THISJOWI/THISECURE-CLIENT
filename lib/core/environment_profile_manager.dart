import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/core/environment_profile.dart';
import 'package:thisjowi/services/telemetry_service.dart';
import 'package:thisjowi/services/token_manager.dart';

class EnvironmentProfileManager extends ChangeNotifier {
  static const _profilesKey = 'environment_profiles';
  static const _activeIdKey = 'active_profile_id';

  static final EnvironmentProfileManager _instance = EnvironmentProfileManager._();
  factory EnvironmentProfileManager() => _instance;
  EnvironmentProfileManager._();

  List<EnvironmentProfile> _profiles = [];
  String? _activeProfileId;

  List<EnvironmentProfile> get profiles => List.unmodifiable(_profiles);
  EnvironmentProfile? get activeProfile =>
    _profiles.cast<EnvironmentProfile?>().firstWhere(
      (p) => p?.id == _activeProfileId,
      orElse: () => null,
    );
  bool get isCloud => activeProfile?.isCloud ?? true;
  bool get isSelfHosted => activeProfile?.isSelfHosted ?? false;

  String get activeStoragePrefix => 'profile_${_activeProfileId ?? 'cloud'}_';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _activeProfileId = prefs.getString(_activeIdKey);

    final raw = prefs.getString(_profilesKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _profiles = list.map((e) => EnvironmentProfile.fromJson(e as Map<String, dynamic>)).toList();
    }

    if (!_profiles.any((p) => p.id == 'cloud')) {
      _profiles.insert(0, EnvironmentProfile.cloud());
    }

    if (_activeProfileId == null || !_profiles.any((p) => p.id == _activeProfileId)) {
      _activeProfileId = 'cloud';
      await prefs.setString(_activeIdKey, _activeProfileId!);
    }

    TokenManager().setStoragePrefix(activeStoragePrefix);
    notifyListeners();
  }

  Future<void> _persistProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_profilesKey, raw);
  }

  Future<void> addProfile(EnvironmentProfile profile) async {
    _profiles.add(profile);
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> updateProfile(EnvironmentProfile profile) async {
    final index = _profiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      _profiles[index] = profile;
      await _persistProfiles();
      notifyListeners();
    }
  }

  Future<void> deleteProfile(String id) async {
    if (id == 'cloud') return;
    _profiles.removeWhere((p) => p.id == id);
    if (_activeProfileId == id) {
      _activeProfileId = 'cloud';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeIdKey, _activeProfileId!);
    }
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> switchTo(String profileId) async {
    final profile = _profiles.firstWhere((p) => p.id == profileId);
    profile.lastUsedAt = DateTime.now();

    _activeProfileId = profileId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeIdKey, profileId);
    await _persistProfiles();

    if (profile.isCloud) {
      ApiConfig.clearManualBaseUrl();
    } else if (profile.serverUrl != null) {
      await ApiConfig.saveManualBaseUrl(profile.serverUrl!);
    }

    TokenManager().setStoragePrefix(activeStoragePrefix);
    notifyListeners();
    TelemetryService.trackEvent('environment_switched', data: {
      'profile': profileId,
      'mode': profile.isCloud ? 'cloud' : 'self_hosted',
    });
  }
}
