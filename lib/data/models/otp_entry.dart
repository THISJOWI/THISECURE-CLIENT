/// Model for an OTP entry (Time-based One-Time Password)
class OtpEntry {
  final String id;
  final String name;
  final String issuer;
  final String secret;
  final int digits;
  final int period;
  final String algorithm;
  final String type;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Offline sync fields
  final String? serverId;
  final String? syncStatus;
  final DateTime? lastSyncedAt;

  OtpEntry({
    required this.id,
    required this.name,
    required this.issuer,
    required this.secret,
    this.digits = 6,
    this.period = 30,
    this.algorithm = 'SHA1',
    this.type = 'totp',
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.serverId,
    this.syncStatus,
    this.lastSyncedAt,
  });

  factory OtpEntry.fromJson(Map<String, dynamic> json) {
    return OtpEntry(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      issuer: (json['issuer'] ?? '').toString(),
      secret: (json['secret'] ?? '').toString(),
      digits: json['digits'] ?? 6,
      period: json['period'] ?? 30,
      algorithm: (json['algorithm'] ?? 'SHA1').toString(),
      type: (json['type'] ?? 'totp').toString(),
      userId: (json['userId'] ?? '').toString(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      serverId: json['serverId']?.toString(),
      syncStatus: json['syncStatus'],
      lastSyncedAt: json['lastSyncedAt'] != null 
          ? DateTime.parse(json['lastSyncedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'issuer': issuer,
      'secret': secret,
      'digits': digits,
      'period': period,
      'algorithm': algorithm,
      'type': type,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'serverId': serverId,
      'syncStatus': syncStatus,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  OtpEntry copyWith({
    String? id,
    String? name,
    String? issuer,
    String? secret,
    int? digits,
    int? period,
    String? algorithm,
    String? type,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? serverId,
    String? syncStatus,
    DateTime? lastSyncedAt,
  }) {
    return OtpEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      secret: secret ?? this.secret,
      digits: digits ?? this.digits,
      period: period ?? this.period,
      algorithm: algorithm ?? this.algorithm,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverId: serverId ?? this.serverId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  /// Parse OTP URI (otpauth://totp/...)
  factory OtpEntry.fromUri(String uri, String userId) {
    final parsed = Uri.parse(uri);
    
    if (parsed.scheme != 'otpauth') {
      throw FormatException('Invalid OTP URI scheme: ${parsed.scheme}');
    }
    
    final type = parsed.host; // totp or hotp
    if (type != 'totp') {
      throw FormatException('Only TOTP is supported, got: $type');
    }
    
    // Path format: /issuer:account or /account
    String path = parsed.path;
    if (path.startsWith('/')) path = path.substring(1);
    path = Uri.decodeComponent(path);
    
    String name = path;
    String issuer = '';
    
    if (path.contains(':')) {
      final parts = path.split(':');
      issuer = parts[0];
      name = parts.sublist(1).join(':');
    }
    
    final params = parsed.queryParameters;
    
    // Issuer from query params takes precedence
    if (params['issuer'] != null) {
      issuer = params['issuer']!;
    }
    
    final secret = params['secret'] ?? '';
    if (secret.isEmpty) {
      throw const FormatException('Missing secret in OTP URI');
    }
    
    final digits = int.tryParse(params['digits'] ?? '6') ?? 6;
    final period = int.tryParse(params['period'] ?? '30') ?? 30;
    final algorithm = (params['algorithm'] ?? 'SHA1').toUpperCase();
    
    final now = DateTime.now();
    
    return OtpEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      issuer: issuer,
      secret: secret,
      digits: digits,
      period: period,
      algorithm: algorithm,
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Generate OTP URI for export/QR code
  String toUri() {
    final label = issuer.isNotEmpty ? '$issuer:$name' : name;
    final encodedLabel = Uri.encodeComponent(label);
    
    var uri = 'otpauth://totp/$encodedLabel?secret=$secret';
    
    if (issuer.isNotEmpty) {
      uri += '&issuer=${Uri.encodeComponent(issuer)}';
    }
    if (digits != 6) {
      uri += '&digits=$digits';
    }
    if (period != 30) {
      uri += '&period=$period';
    }
    if (algorithm != 'SHA1') {
      uri += '&algorithm=$algorithm';
    }
    
    return uri;
  }
}
