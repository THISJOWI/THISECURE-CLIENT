/// Modelo de usuario para autenticacion
/// Contiene solo datos relacionados con autenticacion y tokens
class AuthUser {
  final String id;
  final String email;
  final String token;
  final DateTime? tokenExpiry;
  final String? refreshToken;
  final String? orgId;
  final String? ldapUsername;
  final String? ldapDomain;
  final bool isLdapUser;
  final bool isSamlUser;
  final String? samlNameId;
  final DateTime? lastValidated;
  final String? avatarUrl;
  final String accountType;
  final String hostingMode;
  final String? serverUrl;

  AuthUser({
    required this.id,
    required this.email,
    required this.token,
    this.tokenExpiry,
    this.refreshToken,
    this.orgId,
    this.ldapUsername,
    this.ldapDomain,
    this.isLdapUser = false,
    this.isSamlUser = false,
    this.samlNameId,
    this.lastValidated,
    this.avatarUrl,
    this.accountType = 'Community',
    this.hostingMode = 'Cloud',
    this.serverUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final ldapUsr = json['ldapUsername'] ?? json['ldap_username'];

    // Parsear fecha de expiracion del token
    DateTime? expiry;
    if (json['exp'] != null) {
      // JWT exp es en segundos desde epoch
      expiry = DateTime.fromMillisecondsSinceEpoch(json['exp'] * 1000);
    } else if (json['tokenExpiry'] != null) {
      expiry = DateTime.tryParse(json['tokenExpiry']);
    }

    // Parsear fecha de ultima validacion
    DateTime? lastValidated;
    if (json['lastValidated'] != null) {
      lastValidated = DateTime.tryParse(json['lastValidated']);
    }

    return AuthUser(
      id: (json['id'] ?? json['_id'] ?? json['userId'] ?? json['sub'])?.toString() ?? '',
      email: json['email'] ?? '',
      token: json['token'] ?? json['accessToken'] ?? '',
      tokenExpiry: expiry,
      refreshToken: json['refreshToken'] ?? json['refresh_token'],
      orgId: json['orgId']?.toString() ?? json['org_id']?.toString(),
      ldapUsername: ldapUsr?.toString(),
      ldapDomain: json['ldapDomain']?.toString() ?? json['ldap_domain']?.toString(),
      isLdapUser: json['isLdapUser'] ??
          json['ldapUser'] ??
          json['is_ldap_user'] ??
          (ldapUsr != null),
      isSamlUser: json['isSamlUser'] ??
          json['samlUser'] ??
          json['is_saml_user'] ??
          false,
      samlNameId: json['samlNameId'] ?? json['saml_name_id'],
      lastValidated: lastValidated,
      avatarUrl: json['avatarUrl'] ?? json['picture'] ?? json['avatar_url'],
      accountType: json['accountType']?.toString() ??
          json['account_type']?.toString() ??
          'Community',
      hostingMode: json['hostingMode']?.toString() ??
          json['hosting_mode']?.toString() ??
          'Cloud',
      serverUrl: json['serverUrl']?.toString() ?? json['server_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'token': token,
      'tokenExpiry': tokenExpiry?.toIso8601String(),
      'refreshToken': refreshToken,
      'orgId': orgId,
      'ldapUsername': ldapUsername,
      'ldapDomain': ldapDomain,
      'isLdapUser': isLdapUser,
      'isSamlUser': isSamlUser,
      'samlNameId': samlNameId,
      'lastValidated': lastValidated?.toIso8601String(),
      'accountType': accountType,
      'hostingMode': hostingMode,
      'serverUrl': serverUrl,
      'avatarUrl': avatarUrl,
    };
  }

  /// Crea una copia con campos actualizados
  AuthUser copyWith({
    String? id,
    String? email,
    String? token,
    DateTime? tokenExpiry,
    String? refreshToken,
    String? orgId,
    String? ldapUsername,
    String? ldapDomain,
    bool? isLdapUser,
    bool? isSamlUser,
    String? samlNameId,
    DateTime? lastValidated,
    String? avatarUrl,
    String? accountType,
    String? hostingMode,
    String? serverUrl,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      token: token ?? this.token,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      refreshToken: refreshToken ?? this.refreshToken,
      orgId: orgId ?? this.orgId,
      ldapUsername: ldapUsername ?? this.ldapUsername,
      ldapDomain: ldapDomain ?? this.ldapDomain,
      isLdapUser: isLdapUser ?? this.isLdapUser,
      isSamlUser: isSamlUser ?? this.isSamlUser,
      samlNameId: samlNameId ?? this.samlNameId,
      lastValidated: lastValidated ?? this.lastValidated,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      accountType: accountType ?? this.accountType,
      hostingMode: hostingMode ?? this.hostingMode,
      serverUrl: serverUrl ?? this.serverUrl,
    );
  }

  /// Verifica si el token esta expirado
  bool get isTokenExpired {
    if (tokenExpiry == null) return false;
    // Considerar expirado si falta menos de 5 minutos
    const buffer = Duration(minutes: 5);
    return tokenExpiry!.isBefore(DateTime.now().add(buffer));
  }

  /// Verifica si el token es valido para uso offline
  bool get isValidForOffline {
    if (token.isEmpty) return false;
    if (lastValidated == null) return false;
    // Validar si fue validado en los ultimos 7 dias
    const offlineWindow = Duration(days: 7);
    return DateTime.now().difference(lastValidated!) < offlineWindow;
  }

  @override
  String toString() {
    return 'AuthUser(id: $id, email: $email, isLdapUser: $isLdapUser, tokenExpiry: $tokenExpiry)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser &&
        other.id == id &&
        other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  /// Verifica si es cuenta Business
  bool get isBusinessAccount {
    // Check in token payload for account type
    return false; // Default, will be populated from token
  }
}
