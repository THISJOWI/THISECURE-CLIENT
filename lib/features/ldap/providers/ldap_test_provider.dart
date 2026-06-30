import 'package:flutter/foundation.dart';
import 'package:thisjowi/features/ldap/providers/ldap_config_provider.dart';
import 'package:thisjowi/features/ldap/services/ldap_connection_service.dart';

enum LdapTestStatus { idle, testing, success, error }

class LdapTestProvider extends ChangeNotifier {
  final LdapConnectionService _connectionService = LdapConnectionService();

  LdapTestStatus _status = LdapTestStatus.idle;
  LdapTestResult? _result;
  bool _isRunning = false;

  LdapTestStatus get status => _status;
  LdapTestResult? get result => _result;
  bool get isRunning => _isRunning;
  bool get isSuccess => _status == LdapTestStatus.success;

  Future<void> runTest(LdapConfig config) async {
    if (_isRunning) return;
    _isRunning = true;
    _status = LdapTestStatus.testing;
    _result = null;
    notifyListeners();

    try {
      _result = await _connectionService.testConnection(
        host: config.host,
        port: config.port,
        bindDn: config.bindDn,
        baseDn: config.baseDn,
        password: config.password,
      );
      _status = _result!.overallSuccess ? LdapTestStatus.success : LdapTestStatus.error;
    } catch (e) {
      _result = LdapTestResult(
        overallSuccess: false,
        steps: [],
        firstError: e.toString(),
      );
      _status = LdapTestStatus.error;
    } finally {
      _isRunning = false;
      notifyListeners();
    }
  }

  void reset() {
    _status = LdapTestStatus.idle;
    _result = null;
    _isRunning = false;
    notifyListeners();
  }
}
