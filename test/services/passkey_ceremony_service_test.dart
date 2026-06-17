import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/exceptions.dart';
import 'package:passkeys/types.dart';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/services/passkey_ceremony_service.dart';

class _FakeAuthenticator extends PasskeyAuthenticator {
  _FakeAuthenticator(this.response);
  final RegisterResponseType response;
  RegisterRequestType? lastRequest;
  int calls = 0;

  @override
  Future<RegisterResponseType> register(RegisterRequestType request) async {
    lastRequest = request;
    calls += 1;
    return response;
  }
}

class _ThrowingAuthenticator extends PasskeyAuthenticator {
  @override
  Future<RegisterResponseType> register(RegisterRequestType request) async {
    throw PasskeyAuthCancelledException();
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ApiConfig.setManualBaseUrl('https://api.thisjowi.com');
  });

  test('register sends request with rpId derived from baseUrl and 32-byte challenge', () async {
    final fake = _FakeAuthenticator(const RegisterResponseType(
      id: 'cred-1',
      rawId: 'raw-1',
      clientDataJSON: 'e30',
      attestationObject: 'att',
      transports: ['internal'],
    ));
    final svc = PasskeyCeremonyService();
    svc.authenticator = fake;
    final req = await svc.register(
      name: 'My key',
      userDisplayName: 'user@example.com',
    );
    expect(req['name'], 'My key');
    expect(req['rpId'], 'api.thisjowi.com');
    expect(req['rpName'], 'ThisJowi');
    expect(req['userDisplayName'], 'user@example.com');
    expect(req['credentialId'], 'cred-1');
    expect(req['publicKey'], 'att');
    expect(req['credentialType'], 'public-key');
    expect(req['transports'], ['internal']);
    expect(fake.lastRequest, isNotNull);
    final c = fake.lastRequest!.challenge;
    final challengeBytes = base64Url.decode(c + '=' * (4 - c.length % 4));
    expect(challengeBytes.length, 32);
    final uh = fake.lastRequest!.user.id;
    final uhBytes = base64Url.decode(uh);
    expect(uhBytes.length, 16);
    expect(req['userHandle'], uh);
  });

  test('register bubbles up authenticator exception', () async {
    final svc = PasskeyCeremonyService();
    svc.authenticator = _ThrowingAuthenticator();
    expect(
      () => svc.register(name: 'x', userDisplayName: 'y'),
      throwsA(isA<PasskeyAuthCancelledException>()),
    );
  });
}
