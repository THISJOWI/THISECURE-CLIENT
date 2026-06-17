import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:thisjowi/core/exceptions/auth_exceptions.dart';
import 'package:thisjowi/data/models/auth_user.dart';
import 'package:thisjowi/data/models/user.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';
import 'package:thisjowi/services/base_service.dart';
import 'package:thisjowi/services/cryptoService.dart';
import 'package:thisjowi/services/token_manager.dart';

/// Servicio de autenticacion
/// Responsabilidad: SOLO operaciones de autenticacion (login, registro, OAuth, LDAP)
class AuthService extends BaseService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() : super('AuthService');

  final CryptoService _cryptoService = CryptoService();
  final TokenManager _tokenManager = TokenManager();

  @override
  void validateResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return;
      case 400:
        throw AuthValidationException(
          message: extractErrorMessage(response),
        );
      case 401:
        throw InvalidCredentialsException(
          message: extractErrorMessage(response),
        );
      case 403:
        final message = extractErrorMessage(response);
        if (message.toLowerCase().contains('locked') ||
            message.toLowerCase().contains('bloqueada')) {
          throw AccountLockedException(message: message);
        }
        throw AuthException(
          message: message,
          code: 'FORBIDDEN',
        );
      case 404:
        throw const AuthException(
          message: 'Recurso no encontrado',
          code: 'NOT_FOUND',
        );
      case 409:
        throw AccountAlreadyExistsException(
          message: extractErrorMessage(response),
        );
      case 429:
        throw RateLimitExceededException(
          message: extractErrorMessage(response),
        );
      case 500:
      case 502:
      case 503:
      case 530:
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Error del servidor. Intenta mas tarde.',
        );
      default:
        throw AuthException(
          message: 'Error inesperado: ${response.statusCode}',
          code: 'UNKNOWN_ERROR',
        );
    }
  }

  /// Login tradicional con email y password
  Future<AuthUser> login(String email, String password) async {
    logInfo('Attempting login for email: $email');

    try {
      final response = await apiClient.post(
        '/v1/auth/login',
        body: {'email': email, 'password': password},
        requiresAuth: false,
      );

      validateResponse(response);

      final body = parseJsonBody(response);
      final authUser = AuthUser.fromJson(body);

      // Guardar token
      await _tokenManager.setToken(
        authUser.token,
        expiry: authUser.tokenExpiry,
        refreshToken: authUser.refreshToken,
      );
      await _tokenManager.setUserId(authUser.id);

      // Guardar email para DAOs
      final secureStorage = SecureStorageService();
      await secureStorage.saveValue('cached_email', authUser.email);

      // Inicializar claves E2EE
      await _cryptoService.initKeys();

      logInfo('Login successful for user: ${authUser.id}');
      return authUser;
    } on AuthException {
      rethrow;
    } on SocketException catch (e) {
      logWarning('Network error during login: $e');
      throw NetworkException(
        message: 'Error de conexion. Verifica tu internet.',
        details: e,
      );
    } catch (e, stackTrace) {
      logError('Unexpected error during login', e, stackTrace);
      throw AuthException(
        message: 'Error inesperado: $e',
        code: 'UNEXPECTED_ERROR',
        details: e,
      );
    }
  }

  /// Login con LDAP
  Future<AuthUser> loginWithLdap(
    String username,
    String password,
    String domain,
  ) async {
    logInfo('Attempting LDAP login for user: $username@$domain');

    try {
      final response = await apiClient.post(
        '/v1/auth/ldap/login',
        body: {
          'username': username,
          'password': password,
          'domain': domain,
        },
        requiresAuth: false,
      );

      validateResponse(response);

      final body = parseJsonBody(response);
      final authUser = AuthUser.fromJson(body);

      await _tokenManager.setToken(
        authUser.token,
        expiry: authUser.tokenExpiry,
        refreshToken: authUser.refreshToken,
      );
      await _tokenManager.setUserId(authUser.id);

      // Guardar email para DAOs
      final secureStorage = SecureStorageService();
      await secureStorage.saveValue('cached_email', authUser.email);

      await _cryptoService.initKeys();

      logInfo('LDAP login successful for user: ${authUser.id}');
      return authUser;
    } on AuthException {
      rethrow;
    } on SocketException catch (e) {
      logWarning('Network error during LDAP login: $e');
      throw NetworkException(
        message: 'Error de conexion LDAP.',
        details: e,
      );
    } catch (e, stackTrace) {
      logError('LDAP login error', e, stackTrace);
      throw LdapException(
        message: 'Error en autenticacion LDAP: $e',
        domain: domain,
        details: e,
      );
    }
  }

  /// Login con SAML
  Future<AuthUser> loginWithSaml({
    required String domain,
    required String samlResponse,
    String? relayState,
  }) async {
    logInfo('Attempting SAML login for domain: $domain');

    try {
      final response = await apiClient.post(
        '/v1/auth/saml/login',
        body: {
          'domain': domain,
          'samlResponse': samlResponse,
          if (relayState != null) 'relayState': relayState,
        },
        requiresAuth: false,
      );

      validateResponse(response);

      final body = parseJsonBody(response);
      final authUser = AuthUser.fromJson(body);

      await _tokenManager.setToken(
        authUser.token,
        expiry: authUser.tokenExpiry,
        refreshToken: authUser.refreshToken,
      );
      await _tokenManager.setUserId(authUser.id);

      final secureStorage = SecureStorageService();
      await secureStorage.saveValue('cached_email', authUser.email);
      await secureStorage.saveValue('is_saml_user', 'true');

      await _cryptoService.initKeys();

      logInfo('SAML login successful for user: ${authUser.id}');
      return authUser;
    } on AuthException {
      rethrow;
    } on SocketException catch (e) {
      logWarning('Network error during SAML login: $e');
      throw NetworkException(
        message: 'Error de conexion SAML.',
        details: e,
      );
    } catch (e, stackTrace) {
      logError('SAML login error', e, stackTrace);
      throw SamlException(
        message: 'Error en autenticacion SAML: $e',
        domain: domain,
        details: e,
      );
    }
  }

  /// Iniciar registro - envia OTP
  Future<void> initiateRegister(String email) async {
    logInfo('Initiating registration for email: $email');

    try {
      final response = await apiClient.post(
        '/v1/auth/initiate-register',
        body: {'email': email},
        requiresAuth: false,
      );

      validateResponse(response);

      logInfo('OTP sent successfully to: $email');
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error initiating registration', e, stackTrace);
      throw RegistrationException(
        message: 'Error al iniciar registro: $e',
        details: e,
      );
    }
  }

  /// Completar registro con OTP
  Future<AuthUser> register({
    required String email,
    required String password,
    required String otp,
    String? fullName,
    String? country,
    String? accountType,
    String? hostingMode,
    String? birthdate,
    String? serverUrl,
    String? ldapUrl,
  }) async {
    logInfo('Completing registration for email: $email');

    try {
      final bodyData = {
        'email': email,
        'password': password,
        'otp': otp,
      };

      if (fullName != null) bodyData['fullName'] = fullName;
      if (country != null) bodyData['country'] = country;
      if (accountType != null) bodyData['accountType'] = accountType;
      if (hostingMode != null) bodyData['hostingMode'] = hostingMode;
      if (birthdate != null) bodyData['birthdate'] = birthdate;
      if (serverUrl != null) bodyData['serverUrl'] = serverUrl;
      if (ldapUrl != null) bodyData['ldapUrl'] = ldapUrl;

      final response = await apiClient.post(
        '/v1/auth/register',
        body: bodyData,
        requiresAuth: false,
      );

      validateResponse(response);

      final body = parseJsonBody(response);
      final authUser = AuthUser.fromJson(body);

      await _tokenManager.setToken(
        authUser.token,
        expiry: authUser.tokenExpiry,
        refreshToken: authUser.refreshToken,
      );
      await _tokenManager.setUserId(authUser.id);

      // Guardar email para DAOs
      final secureStorage = SecureStorageService();
      await secureStorage.saveValue('cached_email', authUser.email);

      await _cryptoService.initKeys();

      logInfo('Registration successful for user: ${authUser.id}');
      return authUser;
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Registration error', e, stackTrace);
      throw RegistrationException(
        message: 'Error en el registro: $e',
        details: e,
      );
    }
  }

  /// Logout - limpia tokens
  Future<void> logout() async {
    logInfo('Logging out user');

    try {
      // Opcional: notificar al backend
      final token = await _tokenManager.getToken();
      if (token != null) {
        try {
          await apiClient.post(
            '/v1/auth/logout',
            requiresAuth: true,
          );
        } catch (e) {
          // Ignorar errores al notificar logout
          logDebug('Backend logout notification failed: $e');
        }
      }
    } finally {
      // Siempre limpiar tokens locales
      await _tokenManager.clearToken();
      logInfo('Logout complete');
    }
  }

  /// Validar token actual
  Future<bool> validateToken() async {
    logDebug('Validating token...');

    try {
      final isValid = await _tokenManager.isTokenValid();
      if (!isValid) {
        logDebug('Token is invalid or expired');
        return false;
      }

      // Validar contra backend
      final response = await apiClient.get(
        '/v1/auth/validate',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        await _tokenManager.updateLastValidated();
        logDebug('Token validated successfully');
        return true;
      }

      return false;
    } catch (e) {
      logDebug('Token validation error: $e');
      return false;
    }
  }

  /// Refrescar token
  Future<AuthUser?> refreshToken() async {
    logInfo('Refreshing token...');

    try {
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null) {
        logWarning('No refresh token available');
        return null;
      }

      final response = await apiClient.post(
        '/v1/auth/refresh',
        body: {'refreshToken': refreshToken},
        requiresAuth: false,
      );

      validateResponse(response);

      final body = parseJsonBody(response);
      final authUser = AuthUser.fromJson(body);

      await _tokenManager.setToken(
        authUser.token,
        expiry: authUser.tokenExpiry,
        refreshToken: authUser.refreshToken,
      );

      logInfo('Token refreshed successfully');
      return authUser;
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Token refresh error', e, stackTrace);
      return null;
    }
  }

  /// Verificar si hay sesion activa
  Future<bool> isAuthenticated() async {
    final token = await _tokenManager.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Obtener usuario autenticado actual
  Future<AuthUser?> getCurrentAuthUser() async {
    try {
      final token = await _tokenManager.getToken();
      if (token == null) return null;

      final userId = await _tokenManager.getUserId();
      if (userId == null) return null;

      // Decodificar token para obtener info basica
      final payload = _tokenManager.decodeTokenPayload();
      if (payload != null) {
        return AuthUser.fromJson({
          ...payload,
          'token': token,
        });
      }

      return null;
    } catch (e) {
      logDebug('Error getting current auth user: $e');
      return null;
    }
  }

  /// Obtener token actual
  Future<String?> getToken() => _tokenManager.getToken();

  /// Obtener token sincronicamente (desde cache)
  String? getTokenSync() => _tokenManager.getTokenSync();

  /// Obtener userId actual
  Future<String?> getUserId() => _tokenManager.getUserId();

  /// Obtener email del token
  Future<String?> getEmail() async {
    final payload = _tokenManager.decodeTokenPayload();
    return payload?['email']?.toString();
  }

  /// Obtener tipo de cuenta cacheado (para navegacion rapida)
  Future<String?> getCachedAccountType() async {
    final payload = _tokenManager.decodeTokenPayload();
    return payload?['accountType']?.toString() ??
        payload?['account_type']?.toString();
  }

  /// Obtener usuario actual (compatibilidad con codigo antiguo)
  /// Retorna User model en lugar de AuthUser para compatibilidad
  Future<User?> getCurrentUser() async {
    try {
      final authUser = await getCurrentAuthUser();
      if (authUser == null) return null;

      // Decodificar payload para obtener datos adicionales
      final payload = _tokenManager.decodeTokenPayload();

      return User(
        id: authUser.id,
        email: authUser.email,
        fullName: payload?['fullName'] ?? payload?['full_name'],
        country: payload?['country'],
        accountType: payload?['accountType'] ?? payload?['account_type'],
        hostingMode: payload?['hostingMode'] ?? payload?['hosting_mode'],
        avatarUrl: payload?['avatarUrl'] ?? payload?['avatar_url'],
        orgId: authUser.orgId,
        ldapUsername: authUser.ldapUsername,
        ldapDomain: authUser.ldapDomain,
        isLdapUser: authUser.isLdapUser,
        isSamlUser: authUser.isSamlUser,
        samlNameId: authUser.samlNameId,
        publicKey: payload?['publicKey'] ?? payload?['public_key'],
      );
    } catch (e) {
      logDebug('Error getting current user: $e');
      return null;
    }
  }
}

/// Excepcion para errores de validacion
class AuthValidationException extends AuthException {
  final Map<String, String>? fieldErrors;

  const AuthValidationException({
    super.message = 'Datos de autenticacion invalidos',
    this.fieldErrors,
    super.details,
  }) : super(
          code: 'VALIDATION_ERROR',
        );
}
