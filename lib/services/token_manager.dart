import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestor centralizado de tokens JWT
/// Maneja almacenamiento seguro, validacion y refresco de tokens
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  // Almacenamiento seguro para tokens
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accountName: 'flutter_token',
    ),
    mOptions: MacOsOptions(
      accountName: 'flutter_token',
    ),
  );

  // Fallback a SharedPreferences
  SharedPreferences? _prefs;

  // Keys para almacenamiento
  static const String _tokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _lastValidatedKey = 'token_last_validated';
  static const String _userIdKey = 'user_id';

  // Cache en memoria
  String? _cachedToken;
  DateTime? _cachedExpiry;
  String? _cachedUserId;

  /// Inicializa el TokenManager
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadFromStorage();
  }

  /// Carga los datos desde el almacenamiento
  Future<void> _loadFromStorage() async {
    try {
      _cachedToken = await _secureStorage.read(key: _tokenKey);
      _cachedUserId = await _secureStorage.read(key: _userIdKey);
      
      final expiryStr = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryStr != null) {
        _cachedExpiry = DateTime.tryParse(expiryStr);
      }
    } catch (e) {
      // Fallback a SharedPreferences
      if (kDebugMode) {
        debugPrint('SecureStorage failed, using SharedPreferences fallback: $e');
      }
      _cachedToken = _prefs?.getString(_tokenKey);
      _cachedUserId = _prefs?.getString(_userIdKey);
      
      final expiryStr = _prefs?.getString(_tokenExpiryKey);
      if (expiryStr != null) {
        _cachedExpiry = DateTime.tryParse(expiryStr);
      }
    }
  }

  /// Obtiene el token actual
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    await _loadFromStorage();
    return _cachedToken;
  }

  /// Obtiene el token sincronicamente (desde cache)
  String? getTokenSync() => _cachedToken;

  /// Establece un nuevo token
  Future<void> setToken(String token, {DateTime? expiry, String? refreshToken}) async {
    _cachedToken = token;
    _cachedExpiry = expiry;

    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      
      if (expiry != null) {
        await _secureStorage.write(key: _tokenExpiryKey, value: expiry.toIso8601String());
      }
      
      if (refreshToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }
      
      // Actualizar timestamp de validacion
      await _secureStorage.write(
        key: _lastValidatedKey, 
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Fallback a SharedPreferences
      if (kDebugMode) {
        debugPrint('SecureStorage write failed, using SharedPreferences fallback: $e');
      }
      await _prefs?.setString(_tokenKey, token);
      
      if (expiry != null) {
        await _prefs?.setString(_tokenExpiryKey, expiry.toIso8601String());
      }
      
      if (refreshToken != null) {
        await _prefs?.setString(_refreshTokenKey, refreshToken);
      }
      
      await _prefs?.setString(_lastValidatedKey, DateTime.now().toIso8601String());
    }
  }

  /// Establece el userId asociado al token
  Future<void> setUserId(String userId) async {
    _cachedUserId = userId;
    try {
      await _secureStorage.write(key: _userIdKey, value: userId);
    } catch (e) {
      await _prefs?.setString(_userIdKey, userId);
    }
  }

  /// Obtiene el userId
  Future<String?> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    await _loadFromStorage();
    return _cachedUserId;
  }

  /// Obtiene el userId sincronicamente
  String? getUserIdSync() => _cachedUserId;

  /// Obtiene el refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      return _prefs?.getString(_refreshTokenKey);
    }
  }

  /// Verifica si el token es valido (no expirado)
  Future<bool> isTokenValid() async {
    if (_cachedToken == null || _cachedToken!.isEmpty) {
      return false;
    }

    if (_cachedExpiry == null) {
      // Si no hay fecha de expiracion, asumimos que es valido
      // pero deberiamos validar contra el backend
      return true;
    }

    // Considerar valido si falta mas de 5 minutos para expirar
    final now = DateTime.now();
    const buffer = Duration(minutes: 5);
    return _cachedExpiry!.isAfter(now.add(buffer));
  }

  /// Verifica si el token es valido para uso offline
  /// (token existe y fue validado recientemente contra el backend)
  Future<bool> isTokenValidForOffline() async {
    if (_cachedToken == null || _cachedToken!.isEmpty) {
      return false;
    }

    // Verificar ultima validacion contra backend
    String? lastValidatedStr;
    try {
      lastValidatedStr = await _secureStorage.read(key: _lastValidatedKey);
    } catch (e) {
      lastValidatedStr = _prefs?.getString(_lastValidatedKey);
    }

    if (lastValidatedStr == null) {
      return false;
    }

    final lastValidated = DateTime.tryParse(lastValidatedStr);
    if (lastValidated == null) {
      return false;
    }

    // Token valido para offline si fue validado en los ultimos 7 dias
    const offlineValidityWindow = Duration(days: 7);
    final now = DateTime.now();
    return now.difference(lastValidated) < offlineValidityWindow;
  }

  /// Actualiza el timestamp de ultima validacion
  Future<void> updateLastValidated() async {
    final now = DateTime.now().toIso8601String();
    try {
      await _secureStorage.write(key: _lastValidatedKey, value: now);
    } catch (e) {
      await _prefs?.setString(_lastValidatedKey, now);
    }
  }

  /// Limpia todos los tokens (logout)
  Future<void> clearToken() async {
    _cachedToken = null;
    _cachedExpiry = null;
    _cachedUserId = null;

    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _tokenExpiryKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _lastValidatedKey);
      await _secureStorage.delete(key: _userIdKey);
    } catch (e) {
      await _prefs?.remove(_tokenKey);
      await _prefs?.remove(_tokenExpiryKey);
      await _prefs?.remove(_refreshTokenKey);
      await _prefs?.remove(_lastValidatedKey);
      await _prefs?.remove(_userIdKey);
    }
  }

  /// Decodifica el payload del JWT
  Map<String, dynamic>? decodeTokenPayload() {
    if (_cachedToken == null) return null;
    
    try {
      final parts = _cachedToken!.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error decoding token: $e');
      }
      return null;
    }
  }

  /// Obtiene la fecha de expiracion del token
  DateTime? getTokenExpiry() {
    if (_cachedExpiry != null) return _cachedExpiry;
    
    final payload = decodeTokenPayload();
    if (payload == null) return null;
    
    final exp = payload['exp'];
    if (exp == null) return null;
    
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  }

  /// Verifica si el token necesita refresco
  Future<bool> needsRefresh() async {
    final expiry = getTokenExpiry();
    if (expiry == null) return false;
    
    // Refrescar si falta menos de 10 minutos
    final now = DateTime.now();
    const refreshThreshold = Duration(minutes: 10);
    return expiry.difference(now) < refreshThreshold;
  }
}
