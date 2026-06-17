# Passkeys Home Section Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Passkeys" section to the HomeScreen of the THISECURE Flutter client, backed by the existing `passkey` Go service. Real WebAuthn ceremony, server-only, FAB entry point, iOS+Android+Web.

**Architecture:** Mirror the existing `Passwords` flow: a `PasskeyService` (HTTP CRUD) + `PasskeyCeremonyService` (wraps the `passkeys` Corbado package) + `PasskeyEntry` model + `PasskeyItem` row + `RegisterPasskeyScreen` + `PasskeyDetailsDialog`. HomeScreen fetches via `PasskeyService.getAll()`, renders a new section, listens for `passkey/*` sync events, and exposes a "Passkey" FAB option.

**Tech Stack:** Flutter/Dart, http, passkeys ^2.20.0, iOS Associated Domains, Android Digital Asset Links, Web (navigator.credentials via passkeys_web).

**Spec:** `docs/superpowers/specs/2026-06-17-passkeys-home-section-design.md`

---

## File Structure

- `pubspec.yaml` — add `passkeys: ^2.20.0`
- `.env` + `.env.example` — add `PASSKEY_SERVICE_URL=/v1/passkeys`
- `lib/core/api.dart` — add `passkeysUrl` getter
- `lib/data/models/passkey_entry.dart` — new model
- `lib/services/passkeyService.dart` — HTTP CRUD client
- `lib/services/passkey_ceremony_service.dart` — WebAuthn ceremony wrapper
- `lib/screens/home/components/passkey_item.dart` — list row widget
- `lib/screens/passkey/register_passkey_screen.dart` — new screen
- `lib/screens/passkey/passkey_details_dialog.dart` — new dialog
- `lib/screens/home/HomeScreen.dart` — wire section
- `lib/components/button.dart` — add `onCreatePasskey` to `ExpandableActionButton`
- `lib/utils/GlobalActions.dart` — add `createPasskey`
- `lib/i18n/translations.dart` — add EN/ES keys
- `ios/Runner/Runner.entitlements` — associated domains
- `android/app/src/main/res/xml/asset_links.xml` — digital asset links
- `web/index.html` — add passkeys JS bundle
- `test/services/passkey_service_test.dart`, `test/services/passkey_ceremony_service_test.dart`, `test/screens/home/home_screen_passkeys_test.dart`, `test/data/models/passkey_entry_test.dart` — tests

---

### Task 1: Add passkeys dependency to pubspec.yaml

**Files:**
- Modify: `pubspec.yaml:10-46` (dependencies block)

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, inside the `dependencies:` block, add (any position is fine — add right after `mobile_scanner` for grouping):

```yaml
  passkeys: ^2.20.0
```

- [ ] **Step 2: Resolve packages**

Run: `flutter pub get`
Expected: "Got dependencies!" with no errors.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "deps: add passkeys ^2.20.0 (Corbado WebAuthn)"
```

---

### Task 2: Add `passkeysUrl` to ApiConfig + .env

**Files:**
- Modify: `lib/core/api.dart:28-56`
- Modify: `.env`
- Modify: `.env.example`

- [ ] **Step 1: Add `passkeysUrl` getter**

In `lib/core/api.dart`, after the `otpUrl` getter (around line 50, before `messagesUrl`), add:

```dart
  /// URL completa para el servicio de passkeys
  static String get passkeysUrl {
    final path = EnvLoader.getRequired('PASSKEY_SERVICE_URL');
    return '$baseUrl$path';
  }
```

- [ ] **Step 2: Add `PASSKEY_SERVICE_URL` to `.env`**

Append after the `MESSAGES_SERVICE_URL` line:

```
# Passkeys service path
PASSKEY_SERVICE_URL=/v1/passkeys
```

- [ ] **Step 3: Add the same to `.env.example`**

Append after the `MESSAGES_SERVICE_URL` line:

```
# Passkeys service path
PASSKEY_SERVICE_URL=/v1/passkeys
```

- [ ] **Step 4: Verify analyzer**

Run: `dart analyze lib/core/api.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/core/api.dart .env .env.example
git commit -m "feat(api): add passkeys service URL"
```

---

### Task 3: Create `PasskeyEntry` model

**Files:**
- Create: `lib/data/models/passkey_entry.dart`
- Test: `test/data/models/passkey_entry_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/data/models/passkey_entry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:thisjowi/data/models/passkey_entry.dart';

void main() {
  group('PasskeyEntry', () {
    test('fromJson maps all fields', () {
      final entry = PasskeyEntry.fromJson({
        'id': 42,
        'credentialId': 'cred-abc',
        'publicKey': 'pk-xyz',
        'rpId': 'api.thisjowi.com',
        'rpName': 'ThisJowi',
        'userHandle': 'uh-123',
        'userDisplayName': 'user@example.com',
        'signCount': 7,
        'name': 'My MacBook',
        'transports': ['usb', 'nfc', 'ble', 'hybrid', 'internal'],
        'credentialType': 'public-key',
        'backupEligible': true,
        'backupState': false,
        'userId': 'u-1',
      });
      expect(entry.id, '42');
      expect(entry.credentialId, 'cred-abc');
      expect(entry.publicKey, 'pk-xyz');
      expect(entry.rpId, 'api.thisjowi.com');
      expect(entry.rpName, 'ThisJowi');
      expect(entry.userHandle, 'uh-123');
      expect(entry.userDisplayName, 'user@example.com');
      expect(entry.signCount, 7);
      expect(entry.name, 'My MacBook');
      expect(entry.transports, ['usb', 'nfc', 'ble', 'hybrid', 'internal']);
      expect(entry.credentialType, 'public-key');
      expect(entry.backupEligible, true);
      expect(entry.backupState, false);
      expect(entry.userId, 'u-1');
    });

    test('fromJson tolerates missing optional fields', () {
      final entry = PasskeyEntry.fromJson({
        'id': 1,
        'credentialId': 'c',
        'publicKey': 'pk',
        'name': 'N',
      });
      expect(entry.rpId, '');
      expect(entry.rpName, '');
      expect(entry.userHandle, '');
      expect(entry.userDisplayName, '');
      expect(entry.signCount, 0);
      expect(entry.transports, isEmpty);
      expect(entry.credentialType, '');
      expect(entry.backupEligible, false);
      expect(entry.backupState, false);
      expect(entry.userId, '');
    });

    test('toJson roundtrips', () {
      const entry = PasskeyEntry(
        id: '1',
        credentialId: 'c',
        publicKey: 'pk',
        rpId: 'r',
        rpName: 'rn',
        userHandle: 'uh',
        userDisplayName: 'ud',
        signCount: 0,
        name: 'N',
        transports: ['internal'],
        credentialType: 'public-key',
        backupEligible: false,
        backupState: false,
        userId: 'u',
      );
      final json = entry.toJson();
      final back = PasskeyEntry.fromJson({...json, 'id': 1});
      expect(back.id, '1');
      expect(back.name, 'N');
      expect(back.transports, ['internal']);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/passkey_entry_test.dart`
Expected: FAIL — `PasskeyEntry` not defined.

- [ ] **Step 3: Create the model**

Create `lib/data/models/passkey_entry.dart`:

```dart
class PasskeyEntry {
  final String id;
  final String credentialId;
  final String publicKey;
  final String rpId;
  final String rpName;
  final String userHandle;
  final String userDisplayName;
  final int signCount;
  final String name;
  final List<String> transports;
  final String credentialType;
  final bool backupEligible;
  final bool backupState;
  final String userId;

  const PasskeyEntry({
    required this.id,
    required this.credentialId,
    required this.publicKey,
    required this.rpId,
    required this.rpName,
    required this.userHandle,
    required this.userDisplayName,
    required this.signCount,
    required this.name,
    required this.transports,
    required this.credentialType,
    required this.backupEligible,
    required this.backupState,
    required this.userId,
  });

  factory PasskeyEntry.fromJson(Map<String, dynamic> json) {
    final rawTransports = json['transports'];
    return PasskeyEntry(
      id: (json['id'] ?? '').toString(),
      credentialId: (json['credentialId'] ?? '').toString(),
      publicKey: (json['publicKey'] ?? '').toString(),
      rpId: (json['rpId'] ?? '').toString(),
      rpName: (json['rpName'] ?? '').toString(),
      userHandle: (json['userHandle'] ?? '').toString(),
      userDisplayName: (json['userDisplayName'] ?? '').toString(),
      signCount: (json['signCount'] is int) ? json['signCount'] as int : int.tryParse((json['signCount'] ?? '0').toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      transports: rawTransports is List ? rawTransports.map((e) => e.toString()).toList() : <String>[],
      credentialType: (json['credentialType'] ?? '').toString(),
      backupEligible: json['backupEligible'] == true,
      backupState: json['backupState'] == true,
      userId: (json['userId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'credentialId': credentialId,
        'publicKey': publicKey,
        'rpId': rpId,
        'rpName': rpName,
        'userHandle': userHandle,
        'userDisplayName': userDisplayName,
        'signCount': signCount,
        'name': name,
        'transports': transports,
        'credentialType': credentialType,
        'backupEligible': backupEligible,
        'backupState': backupState,
        'userId': userId,
      };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/passkey_entry_test.dart`
Expected: PASS — 3 tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/passkey_entry.dart test/data/models/passkey_entry_test.dart
git commit -m "feat(model): add PasskeyEntry"
```

---

### Task 4: Create `PasskeyService` (HTTP CRUD)

**Files:**
- Create: `lib/services/passkeyService.dart`
- Test: `test/services/passkey_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/services/passkey_service_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/core/env_loader.dart';
import 'package:thisjowi/services/passkeyService.dart';
import 'package:thisjowi/services/token_manager.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await EnvLoader.load();
    ApiConfig.setManualBaseUrl('https://api.thisjowi.com');
  });

  PasskeyService serviceWith(MockClient client) {
    final svc = PasskeyService();
    svc.httpClient = client;
    return svc;
  }

  test('getAll returns parsed list on 200', () async {
    final mock = MockClient((req) async {
      expect(req.url.path, '/v1/passkeys');
      expect(req.headers['Authorization'], 'Bearer fake-token');
      return http.Response(jsonEncode([
        {'id': 1, 'credentialId': 'c', 'publicKey': 'pk', 'name': 'My key'}
      ]), 200);
    });
    final svc = serviceWith(mock);
    // Inject token
    final tm = TokenManager();
    await tm.saveToken('fake-token');

    final res = await svc.getAll();
    expect(res['success'], true);
    final data = res['data'] as List;
    expect(data.length, 1);
    expect(data.first['name'], 'My key');
  });

  test('getAll returns success=false on 401', () async {
    final mock = MockClient((req) async => http.Response('{}', 401));
    final svc = serviceWith(mock);
    final res = await svc.getAll();
    expect(res['success'], false);
    expect(res['data'], <dynamic>[]);
  });

  test('create posts PasskeyRequest body and returns data', () async {
    final mock = MockClient((req) async {
      expect(req.method, 'POST');
      expect(req.url.path, '/v1/passkeys');
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      expect(body['name'], 'My key');
      expect(body['credentialId'], 'cred-1');
      expect(body['publicKey'], 'pk-1');
      return http.Response(jsonEncode({'id': 99, 'name': 'My key'}), 200);
    });
    final svc = serviceWith(mock);
    final res = await svc.create({
      'name': 'My key',
      'credentialId': 'cred-1',
      'publicKey': 'pk-1',
    });
    expect(res['success'], true);
    expect((res['data'] as Map)['id'], 99);
  });

  test('delete returns success on 200', () async {
    final mock = MockClient((req) async {
      expect(req.method, 'DELETE');
      expect(req.url.path, '/v1/passkeys/5');
      return http.Response(jsonEncode({'message': 'deleted'}), 200);
    });
    final svc = serviceWith(mock);
    final res = await svc.delete('5');
    expect(res['success'], true);
  });

  test('getAll returns timeout message on TimeoutException', () async {
    final mock = MockClient((req) async {
      await Future.delayed(const Duration(milliseconds: 50));
      return http.Response('{}', 200);
    });
    final svc = serviceWith(mock);
    svc.timeout = const Duration(milliseconds: 1);
    final res = await svc.getAll();
    expect(res['success'], false);
    expect(res['message'], contains('timeout'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/passkey_service_test.dart`
Expected: FAIL — `PasskeyService` not defined.

- [ ] **Step 3: Create the service**

Create `lib/services/passkeyService.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api.dart';
import 'token_manager.dart';

class PasskeyService {
  String get baseUrl => ApiConfig.passkeysUrl;
  final TokenManager _tokenManager = TokenManager();
  http.Client httpClient = http.Client();
  Duration timeout = const Duration(seconds: 30);

  Future<Map<String, String>?> _getAuthHeaders() async {
    final token = await _tokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _wrap(Future<http.Response> Function() send) async {
    try {
      final res = await send().timeout(timeout);
      final body = _tryDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {
          'success': true,
          'data': body,
          'message': 'OK',
        };
      }
      if (res.statusCode == 401) {
        return {'success': false, 'message': 'Invalid or expired token.', 'data': <dynamic>[]};
      }
      if (res.statusCode == 403) {
        return {'success': false, 'message': 'Access denied.', 'data': <dynamic>[]};
      }
      if (res.statusCode == 500) {
        return {'success': false, 'message': 'Server error. Please try again later.', 'data': <dynamic>[]};
      }
      return {
        'success': false,
        'message': (body is Map && body['error'] != null) ? body['error'].toString() : 'Error: ${res.statusCode}',
        'data': <dynamic>[],
      };
    } on TimeoutException {
      return {'success': false, 'message': 'Connection timeout. Please try again.', 'data': <dynamic>[]};
    } catch (e) {
      return {'success': false, 'message': 'Failed: $e', 'data': <dynamic>[]};
    }
  }

  Future<Map<String, dynamic>> getAll() async {
    final headers = await _getAuthHeaders();
    return _wrap(() => httpClient.get(Uri.parse(baseUrl), headers: headers));
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final headers = await _getAuthHeaders();
    return _wrap(() => httpClient.post(Uri.parse(baseUrl), headers: headers, body: jsonEncode(data)));
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) async {
    final headers = await _getAuthHeaders();
    return _wrap(() => httpClient.put(Uri.parse('$baseUrl/$id'), headers: headers, body: jsonEncode(data)));
  }

  Future<Map<String, dynamic>> delete(String id) async {
    final headers = await _getAuthHeaders();
    return _wrap(() => httpClient.delete(Uri.parse('$baseUrl/$id'), headers: headers));
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/passkey_service_test.dart`
Expected: PASS — 5 tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/services/passkeyService.dart test/services/passkey_service_test.dart
git commit -m "feat(service): add PasskeyService HTTP CRUD"
```

---

### Task 5: Add i18n keys

**Files:**
- Modify: `lib/i18n/translations.dart` (append a new block before the final `};`)

- [ ] **Step 1: Append the new keys block**

In `lib/i18n/translations.dart`, immediately before the closing `};` on line 2279, add:

```dart
  } +

  // ==================== PASSKEYS ====================
  {
    "en": "Passkeys",
    "es": "Passkeys",
  } +
  {
    "en": "Add passkey",
    "es": "Añadir passkey",
  } +
  {
    "en": "Register passkey",
    "es": "Registrar passkey",
  } +
  {
    "en": "Delete passkey?",
    "es": "¿Eliminar passkey?",
  } +
  {
    "en": "No passkeys yet",
    "es": "Aún no hay passkeys",
  } +
  {
    "en": "Use %s to create this passkey",
    "es": "Usa %s para crear este passkey",
  } +
  {
    "en": "Passkey created",
    "es": "Passkey creada",
  } +
  {
    "en": "Passkey deleted",
    "es": "Passkey eliminada",
  } +
  {
    "en": "Passkey creation failed",
    "es": "Error al crear la passkey",
  } +
  {
    "en": "Registration cancelled",
    "es": "Registro cancelado",
  } +
  {
    "en": "Passkey name",
    "es": "Nombre de la passkey",
  } +
  {
    "en": "Add your first passkey to sign in faster",
    "es": "Añade tu primera passkey para iniciar sesión más rápido",
  } +
  {
    "en": "Backup",
    "es": "Respaldo",
  } +
  {
    "en": "Last used",
    "es": "Último uso",
  } +
  {
    "en": "Relying party",
    "es": "Parte confiante",
  } +
  {
    "en": "Never",
    "es": "Nunca",
  };
```

- [ ] **Step 2: Verify analyzer**

Run: `dart analyze lib/i18n/translations.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/i18n/translations.dart
git commit -m "feat(i18n): add passkeys translation keys"
```

---

### Task 6: Create `PasskeyCeremonyService`

**Files:**
- Create: `lib/services/passkey_ceremony_service.dart`
- Test: `test/services/passkey_ceremony_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/services/passkey_ceremony_service_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:passkeys/passkeys.dart';
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

void main() {
  setUp(() {
    ApiConfig.setManualBaseUrl('https://api.thisjowi.com');
  });

  PasskeyCeremonyService buildWith(PasskeyAuthenticator auth) {
    final svc = PasskeyCeremonyService();
    svc.authenticator = auth;
    return svc;
  }

  test('register sends request with rpId derived from baseUrl and 32-byte challenge', () async {
    final fake = _FakeAuthenticator(RegisterResponseType(
      id: 'cred-1',
      rawId: 'raw-1',
      clientDataJSON: Uint8List.fromList(utf8.encode('{}')),
      attestationObject: Uint8List.fromList(utf8.encode('att')),
      transports: ['internal'],
    ));
    final svc = buildWith(fake);
    final req = await svc.register(
      name: 'My key',
      userDisplayName: 'user@example.com',
    );
    expect(req['name'], 'My key');
    expect(req['rpId'], 'api.thisjowi.com');
    expect(req['rpName'], 'ThisJowi');
    expect(req['userDisplayName'], 'user@example.com');
    expect(req['credentialId'], 'cred-1');
    expect(req['publicKey'], isNotEmpty);
    expect(req['credentialType'], 'public-key');
    expect(req['transports'], ['internal']);
    expect(fake.lastRequest, isNotNull);
    // Challenge is 32 bytes
    final c = fake.lastRequest!.challenge;
    final challengeBytes = c is String ? base64Url.decode(c) : c;
    expect(challengeBytes.length, 32);
    // userHandle is 16 bytes
    final uh = fake.lastRequest!.user.id;
    final uhBytes = uh is String ? base64Url.decode(uh) : uh;
    expect(uhBytes.length, 16);
    // user.id hex-decodes to the userHandle string in the request
    expect(req['userHandle'], isNotEmpty);
  });

  test('register bubbles up authenticator exception', () async {
    final svc = PasskeyCeremonyService();
    svc.authenticator = _ThrowingAuthenticator();
    expect(
      () => svc.register(name: 'x', userDisplayName: 'y'),
      throwsA(isA<PasskeyCancelledException>()),
    );
  });
}

class _ThrowingAuthenticator extends PasskeyAuthenticator {
  @override
  Future<RegisterResponseType> register(RegisterRequestType request) async {
    throw PasskeyCancelledException('cancelled');
  }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/passkey_ceremony_service_test.dart`
Expected: FAIL — `PasskeyCeremonyService` not defined.

- [ ] **Step 3: Create the ceremony service**

Create `lib/services/passkey_ceremony_service.dart`:

```dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:passkeys/passkeys.dart';

import '../core/api.dart';

class PasskeyCeremonyService {
  PasskeyAuthenticator authenticator = PasskeyAuthenticator();

  /// Runs the WebAuthn registration ceremony on the device and returns a
  /// payload ready to be POSTed to the backend `/v1/passkeys` endpoint.
  ///
  /// [name] — user-provided friendly name (required).
  /// [userDisplayName] — typically the user's email.
  /// [rpIdOverride] — for tests; defaults to the host of `ApiConfig.baseUrl`.
  Future<Map<String, dynamic>> register({
    required String name,
    required String userDisplayName,
    String? rpIdOverride,
  }) async {
    final rpId = rpIdOverride ?? _hostFromBaseUrl();
    final challenge = _randomBytes(32);
    final userHandle = _randomBytes(16);

    final request = RegisterRequestType(
      challenge: challenge,
      relyingParty: RelyingPartyType(id: rpId, name: 'ThisJowi'),
      user: UserType(id: userHandle, name: userDisplayName, displayName: userDisplayName),
      pubKeyCredParams: [
        const PublicKeyCredentialParameterType(type: 'public-key', alg: -7),
        const PublicKeyCredentialParameterType(type: 'public-key', alg: -257),
      ],
      authenticatorSelection: const AuthenticatorSelectionType(
        residentKey: 'preferred',
        userVerification: 'preferred',
        requireResidentKey: false,
      ),
      timeout: 60000,
      attestation: 'none',
    );

    final response = await authenticator.register(request);

    return {
      'name': name,
      'credentialId': response.id,
      'publicKey': _bytesToBase64Url(response.attestationObject),
      'rpId': rpId,
      'rpName': 'ThisJowi',
      'userHandle': _bytesToBase64Url(userHandle),
      'userDisplayName': userDisplayName,
      'signCount': 0,
      'transports': response.transports ?? <String>[],
      'credentialType': 'public-key',
      'backupEligible': false,
      'backupState': false,
    };
  }

  String _hostFromBaseUrl() {
    final base = ApiConfig.baseUrl;
    var cleaned = base.replaceAll('http://', '').replaceAll('https://', '');
    final slash = cleaned.indexOf('/');
    if (slash >= 0) cleaned = cleaned.substring(0, slash);
    final colon = cleaned.indexOf(':');
    if (colon >= 0) cleaned = cleaned.substring(0, colon);
    return cleaned;
  }

  Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = rnd.nextInt(256);
    }
    return bytes;
  }

  String _bytesToBase64Url(Uint8List bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/passkey_ceremony_service_test.dart`
Expected: PASS — 2 tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/services/passkey_ceremony_service.dart test/services/passkey_ceremony_service_test.dart
git commit -m "feat(ceremony): add PasskeyCeremonyService WebAuthn wrapper"
```

---

### Task 7: Create `PasskeyItem` widget

**Files:**
- Create: `lib/screens/home/components/passkey_item.dart`

- [ ] **Step 1: Create the widget**

Create `lib/screens/home/components/passkey_item.dart`:

```dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:thisjowi/data/models/passkey_entry.dart';
import 'package:thisjowi/i18n/translations.dart';

class PasskeyItem extends StatelessWidget {
  final PasskeyEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PasskeyItem({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: (Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : const Color(0xFF2A2A2A))
                  .withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.fingerprint,
                            color: Theme.of(context).colorScheme.onSurface, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (entry.rpName.isNotEmpty || entry.rpId.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                entry.rpName.isNotEmpty ? entry.rpName : entry.rpId,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (entry.backupEligible)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Tooltip(
                            message: 'Backup'.i18n,
                            child: Icon(Icons.cloud_done_outlined,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                size: 18),
                          ),
                        ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 20),
                        onPressed: onDelete,
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analyzer**

Run: `dart analyze lib/screens/home/components/passkey_item.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/home/components/passkey_item.dart
git commit -m "feat(ui): add PasskeyItem row widget"
```

---

### Task 8: Create `RegisterPasskeyScreen`

**Files:**
- Create: `lib/screens/passkey/register_passkey_screen.dart`
- Test: `test/screens/home/home_screen_passkeys_test.dart` (just imports for now)

- [ ] **Step 1: Create the screen**

Create `lib/screens/passkey/register_passkey_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/components/liquid_glass.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/services/passkeyService.dart';
import 'package:thisjowi/services/passkey_ceremony_service.dart';

class RegisterPasskeyScreen extends StatefulWidget {
  final PasskeyService passkeyService;
  final PasskeyCeremonyService ceremonyService;
  final String userDisplayName;

  const RegisterPasskeyScreen({
    super.key,
    required this.passkeyService,
    required this.ceremonyService,
    required this.userDisplayName,
  });

  @override
  State<RegisterPasskeyScreen> createState() => _RegisterPasskeyScreenState();
}

class _RegisterPasskeyScreenState extends State<RegisterPasskeyScreen> {
  final _nameController = TextEditingController();
  bool _busy = false;
  String _biometricLabel = 'fingerprint, Face ID, or screen lock';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ErrorSnackBar.showWarning(context, 'Passkey name'.i18n);
      return;
    }
    setState(() => _busy = true);
    try {
      final payload = await widget.ceremonyService.register(
        name: name,
        userDisplayName: widget.userDisplayName,
      );
      if (!mounted) return;
      final res = await widget.passkeyService.create(payload);
      if (!mounted) return;
      if (res['success'] == true) {
        ErrorSnackBar.showSuccess(context, 'Passkey created'.i18n);
        Navigator.pop(context, true);
      } else {
        ErrorSnackBar.show(context, res['message'] ?? 'Passkey creation failed'.i18n);
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().toLowerCase().contains('cancel')) {
        ErrorSnackBar.showInfo(context, 'Registration cancelled'.i18n);
      } else {
        ErrorSnackBar.show(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Register passkey'.i18n),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LiquidGlass.wrap(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.fingerprint, size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Use %s to create this passkey'.fill([_biometricLabel]).i18n,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: 'Passkey name'.i18n,
                    prefixIcon: const Icon(Icons.title),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _register,
                    child: _busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Register passkey'.i18n),
                  ),
                ),
              ],
            ),
            context,
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analyzer**

Run: `dart analyze lib/screens/passkey/register_passkey_screen.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/passkey/register_passkey_screen.dart
git commit -m "feat(ui): add RegisterPasskeyScreen"
```

---

### Task 9: Create `PasskeyDetailsDialog`

**Files:**
- Create: `lib/screens/passkey/passkey_details_dialog.dart`

- [ ] **Step 1: Create the dialog**

Create `lib/screens/passkey/passkey_details_dialog.dart`:

```dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:thisjowi/components/liquid_glass.dart';
import 'package:thisjowi/data/models/passkey_entry.dart';
import 'package:thisjowi/i18n/translations.dart';

class PasskeyDetailsDialog extends StatelessWidget {
  final PasskeyEntry entry;

  const PasskeyDetailsDialog({super.key, required this.entry});

  static Future<bool?> show(BuildContext context, PasskeyEntry entry) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => PasskeyDetailsDialog(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: LiquidGlass.wrap(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.primary, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (entry.rpName.isNotEmpty) _row(context, 'Relying party'.i18n, entry.rpName),
                if (entry.rpId.isNotEmpty) _row(context, 'rpId', entry.rpId),
                if (entry.credentialType.isNotEmpty) _row(context, 'Type', entry.credentialType),
                if (entry.transports.isNotEmpty)
                  _row(context, 'Transports', entry.transports.join(', ')),
                _row(context, 'Last used'.i18n, entry.signCount == 0 ? 'Never'.i18n : '${entry.signCount}'),
                _row(context, 'Backup'.i18n, entry.backupEligible ? 'Eligible' : 'No'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.delete_outline),
                        label: Text('Delete'.i18n),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Close'.i18n),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            context,
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analyzer**

Run: `dart analyze lib/screens/passkey/passkey_details_dialog.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/passkey/passkey_details_dialog.dart
git commit -m "feat(ui): add PasskeyDetailsDialog"
```

---

### Task 10: Add `onCreatePasskey` to `ExpandableActionButton`

**Files:**
- Modify: `lib/components/button.dart`

- [ ] **Step 1: Add the new callback and option**

In `lib/components/button.dart`, add `onCreatePasskey` to the widget fields (after `onCreateOtp`, around line 10):

```dart
  final VoidCallback? onCreatePasskey;
```

- [ ] **Step 2: Add the option button handler**

Add a private method inside `_ExpandableActionButtonState` (after `_handleCreateOtp`):

```dart
  void _handleCreatePasskey() {
    setState(() => _isExpanded = false);
    _animationController?.reverse();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && widget.onCreatePasskey != null) widget.onCreatePasskey!();
    });
  }
```

- [ ] **Step 3: Add the option row**

In the `build` method's Stack, add (above the OTP option, around line 166):

```dart
        if (_isExpanded && widget.onCreatePasskey != null)
          _buildOptionButton(
            onTap: _handleCreatePasskey,
            icon: Icons.fingerprint,
            label: 'Passkey'.i18n,
            bottomPadding: 245.0,
          ),
```

- [ ] **Step 4: Verify analyzer**

Run: `dart analyze lib/components/button.dart`
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/components/button.dart
git commit -m "feat(fab): add Passkey action to ExpandableActionButton"
```

---

### Task 11: Add `createPasskey` to `GlobalActions`

**Files:**
- Modify: `lib/utils/GlobalActions.dart`

- [ ] **Step 1: Add imports and the static method**

In `lib/utils/GlobalActions.dart`, add at the top (after the existing imports):

```dart
import 'package:thisjowi/services/passkeyService.dart';
import 'package:thisjowi/services/passkey_ceremony_service.dart';
import 'package:thisjowi/screens/passkey/register_passkey_screen.dart';
```

- [ ] **Step 2: Add the static method**

Append at the end of the `GlobalActions` class (after `createOtp`):

```dart
  static Future<void> createPasskey(BuildContext context,
      {VoidCallback? onSuccess}) async {
    final passkeyService = PasskeyService();
    final ceremony = PasskeyCeremonyService();
    final email = await _currentUserEmail() ?? 'user';
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPasskeyScreen(
          passkeyService: passkeyService,
          ceremonyService: ceremony,
          userDisplayName: email,
        ),
      ),
    );
    if (created == true && onSuccess != null) onSuccess();
  }

  static Future<String?> _currentUserEmail() async {
    try {
      final storage = await _secureStorage;
      return await storage.getValue('cached_email');
    } catch (_) {
      return null;
    }
  }

  static final _secureStorage = SecureStorageService();
```

Wait — `SecureStorageService` is in `lib/data/local/secure_storage_service.dart`. Adjust the import and class reference. Use this version:

At the top, add this import:

```dart
import 'package:thisjowi/data/local/secure_storage_service.dart';
```

And the static fields + helper:

```dart
  static final SecureStorageService _secureStorage = SecureStorageService();

  static Future<String?> _currentUserEmail() async {
    try {
      return await _secureStorage.getValue('cached_email');
    } catch (_) {
      return null;
    }
  }
```

- [ ] **Step 3: Verify analyzer**

Run: `dart analyze lib/utils/GlobalActions.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/utils/GlobalActions.dart
git commit -m "feat(actions): add createPasskey GlobalAction"
```

---

### Task 12: Wire passkey section into HomeScreen

**Files:**
- Modify: `lib/screens/home/HomeScreen.dart`

- [ ] **Step 1: Add imports**

Add to the import list near the top of the file (anywhere before the class):

```dart
import 'package:thisjowi/data/models/passkey_entry.dart';
import 'package:thisjowi/services/passkeyService.dart';
import 'package:thisjowi/screens/home/components/passkey_item.dart';
import 'package:thisjowi/screens/passkey/passkey_details_dialog.dart';
```

- [ ] **Step 2: Add state fields**

Inside `_HomeScreenState`, after `_notes` (around line 40):

```dart
  late final PasskeyService _passkeyService;
  List<PasskeyEntry> _passkeys = [];
```

- [ ] **Step 3: Initialize the service in `_initRepositories`**

Modify `_initRepositories()` (around line 209):

```dart
  void _initRepositories() {
    _passwordsRepository = PasswordsRepository();
    _notesRepository = NotesRepository();
    _passkeyService = PasskeyService();
  }
```

- [ ] **Step 4: Extend `_loadData` to fetch passkeys**

Inside `_loadData`, change the `Future.wait` (around line 265) to include passkeys, and add parsing:

Replace the line:

```dart
    final results = await Future.wait([
      _passwordsRepository.getAllPasswords(waitForSync: true),
      _notesRepository.getAllNotes(waitForSync: true),
    ]);
```

with:

```dart
    final results = await Future.wait([
      _passwordsRepository.getAllPasswords(waitForSync: true),
      _notesRepository.getAllNotes(waitForSync: true),
      _passkeyService.getAll(),
    ]);
```

After the notes dedup block, add:

```dart
    List<PasskeyEntry> passkeys = [];
    final passkeyResult = results[2];
    if (passkeyResult['success'] == true) {
      final raw = passkeyResult['data'];
      if (raw is List) {
        passkeys = raw
            .whereType<Map>()
            .map((m) => PasskeyEntry.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    }
```

And in the `setState` at the end, add `_passkeys = passkeys;`.

Also extend the search filter (around line 304) to include passkeys:

```dart
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      passwords = passwords
          .where((p) =>
              p.title.toLowerCase().contains(query) ||
              p.username.toLowerCase().contains(query))
          .toList();
      notes = notes
          .where((n) =>
              n.title.toLowerCase().contains(query) ||
              n.content.toLowerCase().contains(query))
          .toList();
      passkeys = passkeys
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              p.rpName.toLowerCase().contains(query) ||
              p.rpId.toLowerCase().contains(query))
          .toList();
    }
```

- [ ] **Step 5: Extend the sync listener**

In `_listenToSyncEvents` (around line 67), update the `startsWith` check:

```dart
    _syncListener = () {
      final info = syncProvider.lastEventInfo;
      if (info.startsWith('password/') ||
          info.startsWith('note/') ||
          info.startsWith('passkey/')) {
        _loadData();
      }
    };
```

- [ ] **Step 6: Add the section to the ListView and update empty/skeleton**

In the `ListView` inside `build` (around line 746), add after the Notes section:

```dart
                                    // Divider between Notes and Passkeys
                                    if (_notes.isNotEmpty && _passkeys.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 8),
                                        child: Divider(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.1),
                                          thickness: 1,
                                        ),
                                      ),

                                    // Passkeys Section
                                    if (_passkeys.isNotEmpty) ...[
                                      _buildSectionHeader(
                                        icon: Icons.fingerprint,
                                        title: 'Passkeys'.i18n,
                                        count: _passkeys.length,
                                      ),
                                      ..._passkeys.map((entry) => _buildPasskeyItem(entry)),
                                    ],
```

And update the empty-state condition (line 744) from:

```dart
                          child: _passwords.isEmpty && _notes.isEmpty
                              ? _buildEmptyState()
```

to:

```dart
                          child: _passwords.isEmpty && _notes.isEmpty && _passkeys.isEmpty
                              ? _buildEmptyState()
```

- [ ] **Step 7: Add `_buildPasskeyItem` and `_deletePasskey`**

Add at the bottom of the class (near `_buildNoteItem`):

```dart
  Widget _buildPasskeyItem(PasskeyEntry entry) {
    return PasskeyItem(
      entry: entry,
      onTap: () async {
        final delete = await PasskeyDetailsDialog.show(context, entry);
        if (delete == true) {
          await _deletePasskey(entry);
        }
      },
      onDelete: () => _deletePasskey(entry),
    );
  }

  Future<void> _deletePasskey(PasskeyEntry entry) async {
    final confirm = await _showDeletePasskeyConfirmation(entry);
    if (!confirm) return;
    final res = await _passkeyService.delete(entry.id);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() => _passkeys.removeWhere((p) => p.id == entry.id));
      ErrorSnackBar.showSuccess(context, 'Passkey deleted'.i18n);
    } else {
      ErrorSnackBar.show(context, res['message'] ?? 'Error deleting passkey');
    }
  }

  Future<bool> _showDeletePasskeyConfirmation(PasskeyEntry entry) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AlertDialog(
              backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.85),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Delete passkey?'.i18n,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              content: Text(
                '${'Are you sure you want to delete'.i18n} "${entry.name}"?',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.8)),
                  child: Text('Cancel'.i18n),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Delete'.i18n),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }
```

- [ ] **Step 8: Update the FAB to include passkey callback**

In `build`, change the `ExpandableActionButton` (around line 794):

```dart
          child: ExpandableActionButton(
            onCreatePassword: () =>
                GlobalActions.createPassword(context, onSuccess: _loadData),
            onCreateNote: () =>
                GlobalActions.createNote(context, onSuccess: _loadData),
            onCreateOtp: () => GlobalActions.createOtp(context),
            onCreateMessage: () => GlobalActions.createMessage(context),
            onCreatePasskey: () =>
                GlobalActions.createPasskey(context, onSuccess: _loadData),
          ),
```

- [ ] **Step 9: Verify analyzer**

Run: `dart analyze lib/screens/home/HomeScreen.dart`
Expected: No errors.

- [ ] **Step 10: Commit**

```bash
git add lib/screens/home/HomeScreen.dart
git commit -m "feat(home): render Passkeys section + FAB action"
```

---

### Task 13: Widget test for HomeScreen passkey section

**Files:**
- Create: `test/screens/home/home_screen_passkeys_test.dart`

- [ ] **Step 1: Create the test**

Create `test/screens/home/home_screen_passkeys_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thisjowi/data/models/passkey_entry.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/screens/home/components/passkey_item.dart';

void main() {
  testWidgets('PasskeyItem renders name, rpName, and delete button', (tester) async {
    const entry = PasskeyEntry(
      id: '1',
      credentialId: 'c',
      publicKey: 'pk',
      rpId: 'api.thisjowi.com',
      rpName: 'ThisJowi',
      userHandle: 'uh',
      userDisplayName: 'ud',
      signCount: 0,
      name: 'My MacBook',
      transports: ['internal'],
      credentialType: 'public-key',
      backupEligible: true,
      backupState: false,
      userId: 'u',
    );
    var tapped = false;
    var deleted = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PasskeyItem(
          entry: entry,
          onTap: () => tapped = true,
          onDelete: () => deleted = true,
        ),
      ),
    ));
    expect(find.text('My MacBook'.i18n), findsNothing);
    expect(find.text('My MacBook'), findsOneWidget);
    expect(find.text('ThisJowi'), findsOneWidget);
    await tester.tap(find.byType(PasskeyItem));
    expect(tapped, true);
    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(deleted, true);
  });
}
```

- [ ] **Step 2: Run the test**

Run: `flutter test test/screens/home/home_screen_passkeys_test.dart`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add test/screens/home/home_screen_passkeys_test.dart
git commit -m "test(home): widget test for PasskeyItem"
```

---

### Task 14: iOS associated domains entitlement

**Files:**
- Modify: `ios/Runner/Runner.entitlements`

- [ ] **Step 1: Add associated domains**

Open `ios/Runner/Runner.entitlements` and add (or extend) the `com.apple.developer.associated-domains` array. If the file does not have it, add:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>webcredentials:api.thisjowi.com</string>
</array>
```

If the file already has the key, append a new `<string>` entry.

- [ ] **Step 2: Commit**

```bash
git add ios/Runner/Runner.entitlements
git commit -m "feat(ios): add associated domains for passkeys"
```

---

### Task 15: Android Digital Asset Links

**Files:**
- Create: `android/app/src/main/res/xml/asset_links.json`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Create the asset links file**

Create `android/app/src/main/res/xml/asset_links.json` (replace `YOUR_SHA256_CERT_FINGERPRINT` with the actual SHA-256 fingerprint of the signing certificate — read it later via `keytool -list -v -keystore <keystore> -alias <alias>`):

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_webauthn_operations"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.thisjowi.thisecure",
      "sha256_cert_fingerprints": ["YOUR_SHA256_CERT_FINGERPRINT"]
    }
  }
]
```

- [ ] **Step 2: Reference it from the manifest**

In `android/app/src/main/AndroidManifest.xml`, inside the `<application ...>` tag, add:

```xml
        <meta-data
            android:name="asset_statements"
            android:resource="@xml/asset_links" />
```

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/res/xml/asset_links.json android/app/src/main/AndroidManifest.xml
git commit -m "feat(android): add digital asset links for passkeys"
```

---

### Task 16: Web — add passkeys JS bundle

**Files:**
- Modify: `web/index.html`

- [ ] **Step 1: Add the passkeys script**

In `web/index.html`, in the `<head>` (or before `</body>`), add:

```html
<script src="https://github.com/corbado/flutter-passkeys/releases/download/2.20.0/bundle.js" type="application/javascript"></script>
```

(Verify the bundle URL is the same version as the `passkeys` package. If a newer release exists, use that version. The package README references 2.4.0 as an example — use the matching version for `passkeys: ^2.20.0`.)

- [ ] **Step 2: Commit**

```bash
git add web/index.html
git commit -m "feat(web): add passkeys JS bundle"
```

---

### Task 17: Final verification

**Files:** none (verification only)

- [ ] **Step 1: Run analyzer on all touched files**

Run: `dart analyze lib/services/passkeyService.dart lib/services/passkey_ceremony_service.dart lib/data/models/passkey_entry.dart lib/screens/home/HomeScreen.dart lib/screens/home/components/passkey_item.dart lib/screens/passkey/register_passkey_screen.dart lib/screens/passkey/passkey_details_dialog.dart lib/components/button.dart lib/utils/GlobalActions.dart lib/core/api.dart lib/i18n/translations.dart`
Expected: No errors.

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 3: Run the app on Web (smoke)**

Run: `flutter run -d chrome`
Expected: App launches, HomeScreen shows the empty state. No crashes.

- [ ] **Step 4: Manual passkey registration**

1. Log in.
2. Tap the FAB → "Passkey".
3. Enter a name, tap "Register passkey".
4. Browser should prompt to use a passkey.
5. Approve; backend should accept and the entry should appear on the HomeScreen.

- [ ] **Step 5: Commit if any final tweaks**

```bash
git add -A
git commit -m "chore(passkeys): final verification tweaks" || true
```

---

## Out of scope (for this plan)

- Passkey **assertion** (sign-in with a saved passkey)
- Passkey **edit** UI (backend supports PUT)
- **Offline cache** of passkeys
- iOS / Android native config beyond what's listed (info.plist NSFaceIDUsageDescription etc. is auto-handled by the `passkeys` plugin on first run)
