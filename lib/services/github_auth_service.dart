import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/core/exceptions/auth_exceptions.dart';
import 'package:thisjowi/data/models/auth_user.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';
import 'package:thisjowi/services/base_service.dart';
import 'package:thisjowi/services/cryptoService.dart';
import 'package:thisjowi/services/telemetry_service.dart';
import 'package:thisjowi/services/token_manager.dart';
import 'package:thisjowi/services/oauth2_browser_service.dart';

class GithubAuthService extends BaseService {
  @override
  void validateResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return;
      case 400:
        throw AuthException(
          message: extractErrorMessage(response),
          code: 'VALIDATION_ERROR',
        );
      case 401:
        throw InvalidCredentialsException(
          message: extractErrorMessage(response),
        );
      default:
        throw AuthException(
          message: extractErrorMessage(response),
          code: 'GITHUB_AUTH_ERROR',
        );
    }
  }

  static final GithubAuthService _instance = GithubAuthService._internal();
  factory GithubAuthService() => _instance;
  GithubAuthService._internal() : super('GithubAuthService');

  final TokenManager _tokenManager = TokenManager();
  final CryptoService _cryptoService = CryptoService();
  final SecureStorageService _secureStorage = SecureStorageService();

  Future<AuthUser> login() async {
    logInfo('Iniciando login GitHub OAuth2');

    try {
      final authUrl = Uri.parse('${ApiConfig.baseUrl}/v1/auth/login/github');
      final callback = await OAuth2BrowserService.authenticate(authUrl: authUrl);

      final token = callback.queryParameters['token'];
      final userId = callback.queryParameters['userId'];
      final email = callback.queryParameters['email'];
      final name = callback.queryParameters['name'];
      final avatarUrl = callback.queryParameters['avatarUrl'] ?? callback.queryParameters['picture'];

      if (token == null || token.isEmpty) {
        final error = callback.queryParameters['error'];
        throw AuthException(
          message: error != null ? 'Error de GitHub: $error' : 'No se recibio el token de autenticacion',
          code: 'NO_TOKEN',
        );
      }

      logInfo('Callback OAuth2 recibido: userId=$userId, email=$email');

      final authUser = AuthUser.fromJson({
        'token': token,
        'userId': userId ?? '',
        'email': email ?? '',
        'name': name ?? '',
        'avatarUrl': avatarUrl ?? '',
      });

      await _tokenManager.setToken(
        authUser.token,
        expiry: authUser.tokenExpiry,
        refreshToken: authUser.refreshToken,
      );
      await _tokenManager.setUserId(authUser.id);
      await _secureStorage.saveValue('cached_email', authUser.email);

      await _cryptoService.initKeys();

      logInfo('Login GitHub exitoso: ${authUser.id}');
      TelemetryService.trackEvent('login_with_github');
      return authUser;
    } on AuthException {
      TelemetryService.trackEvent('login_with_github_failed');
      rethrow;
    } catch (e, stackTrace) {
      logError('Error en login GitHub', e, stackTrace);
      TelemetryService.trackEvent('login_with_github_failed');
      throw AuthException(
        message: 'Error al iniciar sesion con GitHub',
        code: 'GITHUB_LOGIN_ERROR',
        details: e,
      );
    }
  }

  void dispose() {}
}
