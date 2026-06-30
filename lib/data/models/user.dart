class User {
  final String? id;
  final String email;
  final String? fullName;
  final String? country;
  final String? accountType; // "Business" or "Community"
  final String? hostingMode;
  final String? avatarUrl;
  final String? orgId;
  final String? ldapUsername;
  final String? ldapDomain;
  final bool isLdapUser;
  final bool isSamlUser;
  final String? samlNameId;
  final String? publicKey;

  User({
    this.id,
    required this.email,
    this.fullName,
    this.country,
    this.accountType,
    this.hostingMode,
    this.avatarUrl,
    this.orgId,
    this.ldapUsername,
    this.ldapDomain,
    this.isLdapUser = false,
    this.isSamlUser = false,
    this.samlNameId,
    this.publicKey,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final ldapUsr = json['ldapUsername'] ?? json['ldap_username'];
    return User(
      id: (json['userId'] ?? json['id'] ?? json['_id'])?.toString(),
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['name'],
      country: json['country'],
      accountType: json['accountType'] ?? json['account_type'],
      hostingMode: json['hostingMode'] ?? json['hosting_mode'],
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      orgId: json['orgId'] ?? json['org_id'],
      ldapUsername: ldapUsr,
      ldapDomain: json['ldapDomain'] ?? json['ldap_domain'],
      isLdapUser: json['isLdapUser'] ??
          json['ldapUser'] ??
          json['is_ldap_user'] ??
          (ldapUsr != null),
      isSamlUser: json['isSamlUser'] ??
          json['samlUser'] ??
          json['is_saml_user'] ??
          false,
      samlNameId: json['samlNameId'] ?? json['saml_name_id'],
      publicKey: json['publicKey'] ?? json['public_key'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'country': country,
      'accountType': accountType,
      'hostingMode': hostingMode,
      'avatarUrl': avatarUrl,
      'orgId': orgId,
      'ldapUsername': ldapUsername,
      'ldapDomain': ldapDomain,
      'isLdapUser': isLdapUser,
      'isSamlUser': isSamlUser,
      'samlNameId': samlNameId,
      'publicKey': publicKey,
    };
  }

  bool get isBusinessAccount => accountType?.toLowerCase() == 'business';
}
