import 'package:http/http.dart' as http;

import 'package:thisjowi/core/exceptions/account_exceptions.dart';
import 'package:thisjowi/data/models/account_user.dart';
import 'package:thisjowi/services/base_service.dart';
import 'package:thisjowi/services/telemetry_service.dart';

class AccountService extends BaseService {
  AccountService() : super('AccountService');

  @override
  void validateResponse(http.Response response) {
    // Handled per-method due to varied error handling
  }

  Future<AccountUser?> getCurrentAccount() async {
    logDebug('Fetching current account');
    try {
      final response = await apiClient.get('/v1/auth/me');
      if (response.statusCode == 200) {
        final json = parseJsonBody(response);
        logInfo('Account fetched successfully');
        return AccountUser.fromJson(json);
      }
      logWarning('Failed to fetch account: ${response.statusCode}');
      return null;
    } catch (e, stackTrace) {
      logError('Error fetching current account', e, stackTrace);
      return null;
    }
  }

  Future<void> forgotPassword(String email) async {
    logInfo('Forgot password requested for: $email');
    try {
      await apiClient.post(
        '/v1/auth/forgot-password',
        body: {'email': email},
        requiresAuth: false,
      );
      logInfo('Forgot password email sent successfully');
    } catch (e, stackTrace) {
      logError('Forgot password request failed', e, stackTrace);
      rethrow;
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    logInfo('Changing password');
    try {
      final response = await apiClient.post(
        '/v1/auth/change-password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );

      if (response.statusCode == 200) {
        logInfo('Password changed successfully');
        TelemetryService.trackEvent('password_changed');
        return;
      }

      final json = parseJsonBody(response);
      final message = json['message'] ?? 'Error al cambiar la contrasena';

      logWarning('Password change rejected: ${response.statusCode} — $message');

      if (response.statusCode == 400) {
        if (message.contains('Current password is incorrect') ||
            message.contains('incorrect')) {
          throw InvalidCurrentPasswordException(message: message, details: json);
        }
        if (message.contains('password must') ||
            message.contains('uppercase') ||
            message.contains('lowercase') ||
            message.contains('digit') ||
            message.contains('special') ||
            message.contains('at least 8')) {
          throw InvalidNewPasswordException(message: message, details: json);
        }
        throw PasswordChangeException(message: message, details: json);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AccountException(
          message: message,
          code: response.statusCode == 401 ? 'UNAUTHORIZED' : 'FORBIDDEN',
          details: json,
        );
      } else if (response.statusCode >= 500) {
        throw AccountServerException(
          statusCode: response.statusCode,
          message: message,
          details: json,
        );
      } else {
        throw PasswordChangeException(message: message, details: json);
      }
    } on AccountException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Change password failed', e, stackTrace);
      throw PasswordChangeException(
        details: e.toString(),
      );
    }
  }

  Future<void> deleteAccount(String password) async {
    logInfo('Deleting account');
    try {
      final response = await apiClient.delete(
        '/v1/auth/delete-account',
        body: {'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        logInfo('Account deleted successfully');
        TelemetryService.trackEvent('account_deleted');
        return;
      }

      final json = parseJsonBody(response);
      final message = json['message'] ?? 'Error al eliminar la cuenta';

      logWarning('Account deletion rejected: ${response.statusCode} — $message');

      if (response.statusCode == 401) {
        throw AccountException(
          message: 'Contraseña incorrecta',
          code: 'INVALID_PASSWORD',
          details: message,
        );
      } else if (response.statusCode == 400) {
        throw AccountException(
          message: message,
          code: 'INVALID_REQUEST',
          details: json,
        );
      } else if (response.statusCode >= 500) {
        throw AccountServerException(
          statusCode: response.statusCode,
          message: message,
          details: json,
        );
      } else {
        throw AccountDeletionException(
          message: message,
          details: json,
        );
      }
    } on AccountException {
      rethrow;
    } catch (e, stackTrace) {
      logError('Unexpected error during account deletion', e, stackTrace);
      throw AccountDeletionException(
        details: e.toString(),
      );
    }
  }
}