class ServerInfo {
  final bool smtp;
  final List<String> oauth;
  final bool ldap;
  final bool selfHosted;

  const ServerInfo({
    this.smtp = false,
    this.oauth = const [],
    this.ldap = false,
    this.selfHosted = false,
  });

  bool get hasGoogle => oauth.contains('google');
  bool get hasGithub => oauth.contains('github');
  bool get hasMicrosoft => oauth.contains('microsoft');

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    final oauthRaw = json['oauth'];
    final oauthList = oauthRaw is List ? oauthRaw.cast<String>() : <String>[];
    return ServerInfo(
      smtp: json['smtp'] as bool? ?? false,
      oauth: oauthList,
      ldap: json['ldap'] as bool? ?? false,
      selfHosted: json['selfHosted'] as bool? ?? false,
    );
  }

  factory ServerInfo.empty() => const ServerInfo();
}

