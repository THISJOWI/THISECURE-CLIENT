import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/core/env_loader.dart';
import 'package:thisjowi/services/passkeyService.dart';
import 'package:thisjowi/services/token_manager.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
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
    final tm = TokenManager();
    await tm.setToken('fake-token');

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
