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
