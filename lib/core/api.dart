import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thisjowi/core/env_loader.dart';

/// Configuración centralizada de API para el proyecto ThisJowi
/// Lee todas las variables desde .env
class ApiConfig {
  /// Obtiene la URL base del API
  static String get baseUrl {
    // Si hay una URL manual configurada, usarla
    if (_manualBaseUrl != null) {
      return _manualBaseUrl!;
    }

    final ip = EnvLoader.getRequired('LOCAL_NETWORK_IP');
    final port = EnvLoader.get('GATEWAY_PORT');

    // Limpiar IP si tiene protocolo
    var cleanIp = ip.replaceAll('http://', '').replaceAll('https://', '');

    if (port != null && port.isNotEmpty) {
      return 'https://$cleanIp:$port';
    }

    return 'https://$cleanIp';
  }

  /// URL completa para el servicio de autenticación
  static String get authUrl {
    final path = EnvLoader.getRequired('AUTH_SERVICE_URL');
    return '$baseUrl$path';
  }

  /// URL completa para el servicio de notas
  static String get notesUrl {
    final path = EnvLoader.getRequired('NOTES_SERVICE_URL');
    return '$baseUrl$path';
  }

  /// URL completa para el servicio de contraseñas
  static String get passwordsUrl {
    final path = EnvLoader.getRequired('PASSWORD_SERVICE_URL');
    return '$baseUrl$path';
  }

  /// URL completa para el servicio de OTP
  static String get otpUrl {
    final path = EnvLoader.getRequired('OTP_SERVICE_URL');
    return '$baseUrl$path';
  }

  /// URL completa para el servicio de mensajería
  static String get messagesUrl {
    final path = EnvLoader.getRequired('MESSAGES_SERVICE_URL');
    return '$baseUrl$path';
  }

  /// Timeout para las peticiones HTTP (en segundos)
  static int get requestTimeout => EnvLoader.getRequiredInt('REQUEST_TIMEOUT');

  /// Headers comunes para todas las peticiones
  static Map<String, String> get commonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Headers con autenticación
  static Map<String, String> authHeaders(String token) => {
        ...commonHeaders,
        'Authorization': 'Bearer $token',
      };

  /// Método para debugging - muestra la configuración actual
  static void printConfig() {
    if (kDebugMode) {
debugPrint('🔧 API: $baseUrl');
  }
}

/// Permite sobreescribir manualmente la URL base (útil para testing)
  static String? _manualBaseUrl;

  /// Returns the manually set base URL, if any
  static String? get manualBaseUrl => _manualBaseUrl;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('custom_api_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _manualBaseUrl = savedUrl;
    }
  }

  static void setManualBaseUrl(String url) {
    _manualBaseUrl = url;
    if (kDebugMode) {
      debugPrint('API Base URL manually set to: $url');
    }
  }

  static Future<void> saveManualBaseUrl(String url) async {
    setManualBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_api_url', url);
  }

  static void clearManualBaseUrl() {
    _manualBaseUrl = null;
  }

  /// Versión de la API
  static String get apiVersion => 'v1';
}
