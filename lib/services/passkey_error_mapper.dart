import 'package:passkeys/exceptions.dart';

import '../core/api.dart';

/// Detects iOS WebAuthn configuration errors that need to be translated into
/// user-friendly messages instead of the raw native exception text.
class PasskeyErrorMapper {
  /// Returns a user-friendly message if [error] matches a known configuration
  /// error, or `null` if it should fall through to the default handler.
  static String? map(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (_isAssociatedDomainError(lower)) {
      final host = _hostFromBaseUrl();
      return 'App not associated with the server domain. '
          'The administrator must host an Apple App Site Association file at '
          'https://$host/.well-known/apple-app-site-association';
    }

    if (error is PasskeyAuthCancelledException) {
      return null; // handled by caller as cancelled
    }
    if (error is PasskeyUnsupportedException) {
      return 'This device does not support passkeys.';
    }
    if (error is MissingGoogleSignInException) {
      return 'Sign in to your Google account to create passkeys.';
    }
    if (error is SyncAccountNotAvailableException) {
      return 'Sign in to your Google Account to create passkeys.';
    }
    if (error is DomainNotAssociatedException) {
      return 'Missing or invalid AASA file on the server';
    }
    if (error is DeviceNotSupportedException) {
      return 'This device does not support passkeys.';
    }

    return null;
  }

  static bool _isAssociatedDomainError(String lower) {
    return lower.contains('isn\'t associated with domain') ||
        lower.contains('is not associated with domain') ||
        lower.contains('associated with domain') ||
        lower.contains('application with identifier');
  }

  static String _hostFromBaseUrl() {
    var cleaned = ApiConfig.baseUrl
        .replaceAll('http://', '')
        .replaceAll('https://', '');
    final slash = cleaned.indexOf('/');
    if (slash >= 0) cleaned = cleaned.substring(0, slash);
    final colon = cleaned.indexOf(':');
    if (colon >= 0) cleaned = cleaned.substring(0, colon);
    return cleaned;
  }
}
