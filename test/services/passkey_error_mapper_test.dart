import 'package:flutter_test/flutter_test.dart';
import 'package:passkeys/exceptions.dart';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/services/passkey_error_mapper.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    ApiConfig.setManualBaseUrl('https://api.thisjowi.com');
  });

  test('detects iOS Associated Domain error and returns friendly message', () {
    final raw = 'The operation couldn\'t be completed. '
        'Application with identifier LSKYSF7629.com.thisjowi.thisecure '
        'isn\'t associated with domain api.thisjowi.com.';
    final msg = PasskeyErrorMapper.map(raw);
    expect(msg, isNotNull);
    expect(msg, contains('https://api.thisjowi.com/.well-known/apple-app-site-association'));
    expect(msg, contains('administrator'));
  });

  test('detects the "is not associated" variant', () {
    final msg = PasskeyErrorMapper.map(
        'Application with identifier X is not associated with domain api.thisjowi.com');
    expect(msg, isNotNull);
    expect(msg, contains('administrator'));
  });

  test('returns null for PasskeyAuthCancelledException (caller handles it)', () {
    expect(PasskeyErrorMapper.map(PasskeyAuthCancelledException()), isNull);
  });

  test('returns null for generic errors', () {
    expect(PasskeyErrorMapper.map(Exception('something else')), isNull);
  });

  test('maps DomainNotAssociatedException to short label', () {
    expect(PasskeyErrorMapper.map(DomainNotAssociatedException('not associated')),
        'Missing or invalid AASA file on the server');
  });
}
