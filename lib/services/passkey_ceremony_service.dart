import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

import '../core/api.dart';

class PasskeyCeremonyService {
  PasskeyAuthenticator authenticator = PasskeyAuthenticator();

  Future<Map<String, dynamic>> register({
    required String name,
    required String userDisplayName,
    String? rpIdOverride,
  }) async {
    final rpId = rpIdOverride ?? _hostFromBaseUrl();
    final challenge = _randomBytesBase64Url(32);
    final userHandle = _randomBytesBase64Url(16, withPadding: true);

    final request = RegisterRequestType(
      challenge: challenge,
      relyingParty: RelyingPartyType(id: rpId, name: 'ThisJowi'),
      user: UserType(id: userHandle, name: userDisplayName, displayName: userDisplayName),
      excludeCredentials: const [],
      authSelectionType: AuthenticatorSelectionType(
        authenticatorAttachment: null,
        requireResidentKey: false,
        residentKey: 'preferred',
        userVerification: 'preferred',
      ),
      pubKeyCredParams: [
        PubKeyCredParamType(type: 'public-key', alg: -7),
        PubKeyCredParamType(type: 'public-key', alg: -257),
      ],
      timeout: 60000,
      attestation: 'none',
    );

    final response = await authenticator.register(request);

    return {
      'name': name,
      'credentialId': response.id,
      'publicKey': response.attestationObject,
      'rpId': rpId,
      'rpName': 'ThisJowi',
      'userHandle': userHandle,
      'userDisplayName': userDisplayName,
      'signCount': 0,
      'transports': response.transports.whereType<String>().toList(),
      'credentialType': 'public-key',
      'backupEligible': false,
      'backupState': false,
    };
  }

  String _hostFromBaseUrl() {
    var cleaned = ApiConfig.baseUrl
        .replaceAll('http://', '')
        .replaceAll('https://', '');
    final slash = cleaned.indexOf('/');
    if (slash >= 0) cleaned = cleaned.substring(0, slash);
    final colon = cleaned.indexOf(':');
    if (colon >= 0) cleaned = cleaned.substring(0, colon);
    return cleaned;
  }

  String _randomBytesBase64Url(int length, {bool withPadding = false}) {
    final rnd = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = rnd.nextInt(256);
    }
    var encoded = base64Url.encode(bytes);
    if (!withPadding) {
      encoded = encoded.replaceAll('=', '');
    }
    return encoded;
  }
}
