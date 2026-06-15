import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Check if biometrics are available (enrolled)
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  /// Check if biometric is enabled for a specific user.
  /// Falls back to the legacy global key for migration.
  Future<bool> isBiometricEnabled({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      final userKey = '${_biometricEnabledKey}_$userId';
      final userValue = prefs.getBool(userKey);
      if (userValue != null) return userValue;
      final globalValue = prefs.getBool(_biometricEnabledKey);
      if (globalValue == true) {
        await prefs.setBool(userKey, true);
        await prefs.remove(_biometricEnabledKey);
        return true;
      }
      return false;
    }
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Enable or disable biometric authentication for a specific user.
  /// When [userId] is provided, the old global key is cleared.
  Future<void> setBiometricEnabled(bool enabled, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.setBool('${_biometricEnabledKey}_$userId', enabled);
      await prefs.remove(_biometricEnabledKey);
    } else {
      await prefs.setBool(_biometricEnabledKey, enabled);
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
    required String localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool sensitiveTransaction = true,
  }) async {
    try {
      final isAvailable = await canCheckBiometrics();
      final isDeviceSupported = await this.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false, // Allow PIN/pattern as fallback
        sensitiveTransaction: sensitiveTransaction,
        persistAcrossBackgrounding: stickyAuth,
      );
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Get a friendly name for the available biometric type
  Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();
    
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Touch ID';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'Biometric';
    } else if (biometrics.contains(BiometricType.weak)) {
      return 'Biometric';
    }
    
    return 'Biometric';
  }

  // Keys for app lock settings
  static const String _biometricLockEnabledKey = 'biometric_lock_enabled';

  /// Check if biometric app lock is enabled
  Future<bool> isBiometricLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to false - user must explicitly enable it
    return prefs.getBool(_biometricLockEnabledKey) ?? false;
  }

  /// Enable or disable biometric app lock
  Future<void> setBiometricLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricLockEnabledKey, enabled);
  }

  /// Check if biometric lock is available and can be used
  Future<bool> canUseBiometricLock() async {
    final canCheck = await canCheckBiometrics();
    final deviceSupported = await isDeviceSupported();
    return canCheck && deviceSupported;
  }
}
