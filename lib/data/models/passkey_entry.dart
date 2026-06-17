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
    int parsedSignCount = 0;
    final sc = json['signCount'];
    if (sc is int) {
      parsedSignCount = sc;
    } else if (sc != null) {
      parsedSignCount = int.tryParse(sc.toString()) ?? 0;
    }
    return PasskeyEntry(
      id: (json['id'] ?? '').toString(),
      credentialId: (json['credentialId'] ?? '').toString(),
      publicKey: (json['publicKey'] ?? '').toString(),
      rpId: (json['rpId'] ?? '').toString(),
      rpName: (json['rpName'] ?? '').toString(),
      userHandle: (json['userHandle'] ?? '').toString(),
      userDisplayName: (json['userDisplayName'] ?? '').toString(),
      signCount: parsedSignCount,
      name: (json['name'] ?? '').toString(),
      transports: rawTransports is List
          ? rawTransports.map((e) => e.toString()).toList()
          : <String>[],
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
