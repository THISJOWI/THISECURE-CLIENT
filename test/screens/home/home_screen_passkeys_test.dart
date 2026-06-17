import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thisjowi/data/models/passkey_entry.dart';
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
    expect(find.text('My MacBook'), findsOneWidget);
    expect(find.text('ThisJowi'), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    await tester.tap(find.byType(PasskeyItem));
    expect(tapped, true);
    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(deleted, true);
  });
}
