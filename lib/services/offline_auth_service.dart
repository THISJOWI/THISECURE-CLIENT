import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:thisjowi/data/local/dao/offline_auth.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';
import 'package:thisjowi/services/token_manager.dart';
import 'package:thisjowi/services/cryptoService.dart';
import 'package:thisjowi/data/models/auth_user.dart';
import 'package:thisjowi/data/local/database.dart';

class OfflineAuthService {
  static final OfflineAuthService _instance = OfflineAuthService._internal();
  factory OfflineAuthService() => _instance;
  OfflineAuthService._internal();

  final OfflineAuthDao _dao = OfflineAuthDao(AppDatabase.instance());
  final CryptoService _cryptoService = CryptoService();
  final TokenManager _tokenManager = TokenManager();

  final _algorithm = Argon2id(
    memory: 10240,
    parallelism: 2,
    iterations: 3,
    hashLength: 32,
  );

  String _generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return random.toString();
  }

  Future<String> _hashPassword(String password) async {
    final salt = _generateSalt();
    final key = await _algorithm.deriveKeyFromPassword(
      password: password,
      nonce: utf8.encode(salt),
    );
    return '$salt:${base64.encode(await key.extractBytes())}';
  }

  Future<bool> _verifyPassword(String password, String storedHash) async {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;

      final salt = parts[0];
      final storedHashBytes = parts[1];

      final key = await _algorithm.deriveKeyFromPassword(
        password: password,
        nonce: utf8.encode(salt),
      );

      return base64.encode(await key.extractBytes()) == storedHashBytes;
    } catch (e) {
      return false;
    }
  }

  Future<AuthUser?> loginOffline(String email, String password) async {
    final user = await _dao.getUserByEmail(email);
    if (user == null) return null;

    final isValid = await _verifyPassword(password, user.passwordHash);
    if (!isValid) return null;

    await _dao.setActiveUser(email);
    await _dao.updateLastLogin(email);

    await _tokenManager.setUserId(user.id);

    final secureStorage = SecureStorageService();
    await secureStorage.saveValue('cached_email', user.email);

    await _cryptoService.initKeys();

    return AuthUser(
      id: user.id,
      email: user.email,
      token: '',
    );
  }

  Future<AuthUser?> registerOffline({
    required String email,
    required String password,
    String? fullName,
    String? country,
    String? accountType,
    String? hostingMode,
  }) async {
    final existingUser = await _dao.getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('Usuario ya existe');
    }

    final passwordHash = await _hashPassword(password);
    final now = DateTime.now().toIso8601String();

    final user = OfflineUser(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      passwordHash: passwordHash,
      fullName: fullName,
      country: country,
      accountType: accountType,
      hostingMode: hostingMode,
      lastLogin: now,
      isActive: 1,
      needsSync: 1,
      createdAt: now,
    );

    await _dao.saveUser(user);
    await _dao.setActiveUser(email);

    await _tokenManager.setUserId(user.id);

    final secureStorage = SecureStorageService();
    await secureStorage.saveValue('cached_email', email);

    await _cryptoService.initKeys();

    return AuthUser(
      id: user.id,
      email: user.email,
      token: '',
    );
  }

  Future<bool> isUserLocal(String email) => _dao.isUserLocal(email);

  Future<List<OfflineUser>> getAllLocalUsers() => _dao.getAllUsers();

  Future<OfflineUser?> getActiveUser() => _dao.getActiveUser();

  Future<void> switchUser(String email, {String? password}) async {
    final user = await _dao.getUserByEmail(email);
    if (user == null) throw Exception('Usuario no encontrado');

    if (password != null) {
      final isValid = await _verifyPassword(password, user.passwordHash);
      if (!isValid) throw Exception('Contraseña incorrecta');
    }

    await _dao.setActiveUser(email);
    await _dao.updateLastLogin(email);

    await _tokenManager.setUserId(user.id);

    final secureStorage = SecureStorageService();
    await secureStorage.saveValue('cached_email', user.email);
  }

  Future<void> deleteLocalUser(String email) async {
    await _dao.deleteUser(email);
  }

  Future<List<OfflineUser>> getUsersNeedingSync() => _dao.getUsersNeedingSync();

  Future<void> clearSyncFlag(String email) => _dao.clearSyncFlag(email);

  Future<void> updateUserData({
    required String email,
    String? fullName,
    String? country,
    String? accountType,
    String? hostingMode,
    String? avatarUrl,
    String? publicKey,
  }) async {
    await _dao.updateUserData(
      email: email,
      fullName: fullName,
      country: country,
      accountType: accountType,
      hostingMode: hostingMode,
      avatarUrl: avatarUrl,
      publicKey: publicKey,
    );
  }
}
