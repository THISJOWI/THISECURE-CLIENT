import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';

class LdapConfig {
  final String host;
  final String port;
  final String bindDn;
  final String baseDn;
  final String usernameAttr;
  final String password;

  LdapConfig({
    this.host = '',
    this.port = '389',
    this.bindDn = '',
    this.baseDn = '',
    this.usernameAttr = 'uid',
    this.password = '',
  });

  LdapConfig copyWith({
    String? host,
    String? port,
    String? bindDn,
    String? baseDn,
    String? usernameAttr,
    String? password,
  }) {
    return LdapConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      bindDn: bindDn ?? this.bindDn,
      baseDn: baseDn ?? this.baseDn,
      usernameAttr: usernameAttr ?? this.usernameAttr,
      password: password ?? this.password,
    );
  }

  String get ldapUrl => host.isNotEmpty ? 'ldap://$host:$port' : '';
}

class LdapConfigProvider extends ChangeNotifier {
  LdapConfig _config = LdapConfig();
  final SecureStorageService _secureStorage = SecureStorageService();

  LdapConfig get config => _config;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('ldap_host') ?? '';
    final port = prefs.getString('ldap_port') ?? '389';
    final bindDn = prefs.getString('ldap_bind_dn') ?? '';
    final baseDn = prefs.getString('ldap_base_dn') ?? '';
    final usernameAttr = prefs.getString('ldap_username_attr') ?? 'uid';
    final password = await _secureStorage.getValue('ldap_password') ?? '';
    _config = LdapConfig(
      host: host,
      port: port,
      bindDn: bindDn,
      baseDn: baseDn,
      usernameAttr: usernameAttr,
      password: password,
    );
    notifyListeners();
  }

  Future<void> saveConfig(LdapConfig config) async {
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ldap_host', config.host);
    await prefs.setString('ldap_port', config.port);
    await prefs.setString('ldap_bind_dn', config.bindDn);
    await prefs.setString('ldap_base_dn', config.baseDn);
    await prefs.setString('ldap_username_attr', config.usernameAttr);
    await _secureStorage.saveValue('ldap_password', config.password);
    notifyListeners();
  }

  Future<void> clearConfig() async {
    _config = LdapConfig();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ldap_host');
    await prefs.remove('ldap_port');
    await prefs.remove('ldap_bind_dn');
    await prefs.remove('ldap_base_dn');
    await prefs.remove('ldap_username_attr');
    await _secureStorage.deleteValue('ldap_password');
    notifyListeners();
  }
}
