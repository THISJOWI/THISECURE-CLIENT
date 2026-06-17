import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:thisjowi/core/exceptions/profile_exceptions.dart';
import 'package:thisjowi/data/models/profile_user.dart';
import 'package:thisjowi/services/base_service.dart';
import 'package:thisjowi/services/token_manager.dart';

/// Servicio de perfil de usuario
/// Responsabilidad: Gestión de datos personales, avatar, preferencias
class ProfileService extends BaseService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal() : super('ProfileService');

final TokenManager _tokenManager = TokenManager();

@override
  void validateResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return;
      case 400:
      throw ProfileValidationException(
        message: extractErrorMessage(response),
      );
      case 401:
        throw const ProfileException(
          message: 'Sesion expirada. Inicia sesion nuevamente.',
          code: 'UNAUTHORIZED',
        );
      case 403:
        throw const ProfileException(
          message: 'No tienes permisos para esta accion.',
          code: 'FORBIDDEN',
        );
      case 404:
        throw const ProfileNotFoundException();
      case 413:
        throw const InvalidAvatarException(
          message: 'El archivo es demasiado grande.',
        );
      case 415:
        throw const InvalidAvatarException(
          message: 'Formato de imagen no soportado.',
        );
      case 500:
      case 502:
      case 503:
        throw ProfileServerException(
          statusCode: response.statusCode,
          message: 'Error del servidor. Intenta mas tarde.',
        );
      default:
        throw ProfileException(
          message: 'Error inesperado: ${response.statusCode}',
          code: 'UNKNOWN_ERROR',
        );
    }
  }

  /// Obtener perfil de usuario con reintentos en caso de 404
  Future<ProfileUser> getProfile(String userId) async {
    logInfo('Fetching profile for user: $userId');

    try {
      final profile = await _getProfileWithRetry(userId);
      logInfo('Profile fetched successfully for user: $userId');
      return profile;
    } on ProfileException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error fetching profile', e, stackTrace);
      throw ProfileException(
        message: 'Error al obtener perfil: $e',
        code: 'FETCH_ERROR',
        details: e,
      );
    }
  }

  Future<ProfileUser> _getProfileWithRetry(String userId) async {
    const maxRetries = 3;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await apiClient.get(
          '/v1/profiles/$userId',
          requiresAuth: true,
        );

        validateResponse(response);

        final body = parseJsonBody(response);
        return ProfileUser.fromJson(body);
      } on ProfileNotFoundException {
        if (attempt >= maxRetries - 1) rethrow;
        logWarning('Profile not found (attempt ${attempt + 1}), retrying...');
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }
    throw const ProfileNotFoundException();
  }

  /// Obtener perfil del usuario actual
  Future<ProfileUser?> getCurrentProfile() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      logWarning('No user ID found for current profile');
      return null;
    }
    return getProfile(userId);
  }

  /// Actualizar perfil
  Future<ProfileUser> updateProfile(ProfileUser profile) async {
    logInfo('Updating profile for user: ${profile.userId}');

    try {
      final response = await apiClient.put(
        '/v1/profiles/${profile.userId}',
        body: profile.toJson(),
        requiresAuth: true,
      );

      validateResponse(response);

      final body = parseJsonBody(response);
      final updatedProfile = ProfileUser.fromJson(body);

      logInfo('Profile updated successfully for user: ${profile.userId}');
      return updatedProfile;
    } on ProfileException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error updating profile', e, stackTrace);
      throw ProfileUpdateException(
        message: 'Error al actualizar perfil: $e',
        details: e,
      );
    }
  }

  /// Actualizar campos especificos del perfil
  Future<ProfileUser> updateProfileFields({
    String? fullName,
    String? country,
    String? birthDate,
    String? accountType,
    String? hostingMode,
    Map<String, dynamic>? preferences,
  }) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw const ProfileException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    logInfo('Updating profile fields for user: $userId');

    try {
      final bodyData = <String, dynamic>{};
      if (fullName != null) bodyData['fullName'] = fullName;
      if (country != null) bodyData['country'] = country;
      if (birthDate != null) bodyData['birthDate'] = birthDate;
      if (accountType != null) bodyData['accountType'] = accountType;
      if (hostingMode != null) bodyData['hostingMode'] = hostingMode;
      if (preferences != null) bodyData['preferences'] = preferences;

      final response = await apiClient.patch(
        '/v1/profiles/$userId',
        body: bodyData,
        requiresAuth: true,
      );

      validateResponse(response);

      final body = parseJsonBody(response);
      final updatedProfile = ProfileUser.fromJson(body);

      logInfo('Profile fields updated successfully');
      return updatedProfile;
    } on ProfileException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error updating profile fields', e, stackTrace);
      throw ProfileUpdateException(
        message: 'Error al actualizar campos: $e',
        details: e,
      );
    }
  }

  /// Subir avatar
  Future<String> uploadAvatar(File imageFile) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw const ProfileException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    logInfo('Uploading avatar for user: $userId');

    try {
      final response = await apiClient.uploadFile(
        '/v1/profiles/$userId/avatar',
        file: imageFile,
        fieldName: 'avatar',
        contentType: MediaType('image', 'jpeg'),
        requiresAuth: true,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorBody = await response.stream.bytesToString();
        String serverMessage;
        try {
          final json = jsonDecode(errorBody);
          serverMessage = json['message'] ?? json['error'] ?? errorBody;
        } catch (_) {
          serverMessage = errorBody.isNotEmpty ? errorBody : 'Error ${response.statusCode}';
        }
        throw AvatarUploadException(
          message: 'Error al subir avatar: $serverMessage',
        );
      }

      final responseBody = await response.stream.bytesToString();
      final body = parseJsonBody(
        http.Response(responseBody, response.statusCode),
      );

      final avatarUrl = body['avatarUrl'] ?? body['avatar_url'];
      if (avatarUrl == null) {
        throw const AvatarUploadException(
          message: 'No se recibio URL del avatar',
        );
      }

      logInfo('Avatar uploaded successfully: $avatarUrl');
      return avatarUrl.toString();
    } on ProfileException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error uploading avatar', e, stackTrace);
      throw AvatarUploadException(
        message: 'Error al subir avatar: $e',
        details: e,
      );
    }
  }

  /// Eliminar avatar
  Future<void> deleteAvatar() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw const ProfileException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    logInfo('Deleting avatar for user: $userId');

    try {
      final response = await apiClient.delete(
        '/v1/profiles/$userId/avatar',
        requiresAuth: true,
      );

      validateResponse(response);

      logInfo('Avatar deleted successfully');
    } on ProfileException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error deleting avatar', e, stackTrace);
      throw ProfileException(
        message: 'Error al eliminar avatar: $e',
        code: 'DELETE_AVATAR_ERROR',
        details: e,
      );
    }
  }

  /// Actualizar clave publica (E2EE)
  Future<void> updatePublicKey(String publicKey) async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw const ProfileException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    logInfo('Updating public key for user: $userId');

    try {
      final response = await apiClient.put(
        '/v1/profiles/$userId/public-key',
        body: {'publicKey': publicKey},
        requiresAuth: true,
      );

      validateResponse(response);

      logInfo('Public key updated successfully');
    } on ProfileException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error updating public key', e, stackTrace);
      throw PublicKeyException(
        message: 'Error al actualizar clave publica: $e',
        details: e,
      );
    }
  }

  /// Obtener clave publica de un usuario
  Future<String?> getPublicKey(String userId) async {
    logInfo('Fetching public key for user: $userId');

    try {
      final response = await apiClient.get(
        '/v1/profiles/$userId/public-key',
        requiresAuth: true,
      );

      validateResponse(response);

      final body = parseJsonBody(response);
      final publicKey = body['publicKey'] ?? body['public_key'];

      logInfo('Public key fetched successfully');
      return publicKey?.toString();
    } on ProfileException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error fetching public key', e, stackTrace);
      throw PublicKeyException(
        message: 'Error al obtener clave publica: $e',
        details: e,
      );
    }
  }

  /// Sincronizar perfil (para modo offline)
  Future<ProfileUser> syncProfile() async {
    final userId = await _tokenManager.getUserId();
    if (userId == null) {
      throw const ProfileException(
        message: 'No hay usuario autenticado',
        code: 'NO_USER',
      );
    }

    logInfo('Syncing profile for user: $userId');

    try {
      // Obtener perfil actual del servidor
      final profile = await getProfile(userId);

      // TODO: Sincronizar cambios locales pendientes
      // Esto requeriria una cola de sincronizacion

      logInfo('Profile synced successfully');
      return profile;
    } on ProfileException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error syncing profile', e, stackTrace);
      throw ProfileSyncException(
        message: 'Error al sincronizar perfil: $e',
        details: e,
      );
    }
  }

  /// Buscar usuarios por nombre o email
  Future<List<ProfileUser>> searchUsers(String query, {int limit = 20}) async {
    logInfo('Searching users with query: $query');

    try {
      final response = await apiClient.get(
        '/v1/profiles/search?q=${Uri.encodeComponent(query)}&limit=$limit',
        requiresAuth: true,
      );

      validateResponse(response);

      final body = parseJsonListBody(response);
      final users = body.map((json) => ProfileUser.fromJson(json)).toList();

      logInfo('Found ${users.length} users');
      return users;
    } on ProfileException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Error searching users', e, stackTrace);
      throw ProfileException(
        message: 'Error al buscar usuarios: $e',
        code: 'SEARCH_ERROR',
        details: e,
      );
    }
  }
}
