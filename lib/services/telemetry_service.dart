import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thisjowi/core/env_loader.dart';
import 'package:thisjowi/core/environment_profile_manager.dart';
import 'package:thisjowi/utils/app_logger.dart';

class TelemetryService {
  static bool _initialized = false;
  static bool _enabled = false;

  static const String _optOutKey = 'telemetry_opt_out';

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (!EnvironmentProfileManager().isCloud) {
      appLog.i('📡 Aptabase: self-hosted mode, telemetry disabled');
      return;
    }

    final appKey = EnvLoader.get('APTABASE_APP_KEY');
    if (appKey == null || appKey.isEmpty) {
      appLog.i('📡 Aptabase: no app key configured, telemetry disabled');
      return;
    }

    final host = EnvLoader.get('APTABASE_HOST');

    try {
      if (host != null && host.isNotEmpty) {
        await Aptabase.init(appKey, InitOptions(host: host));
      } else {
        await Aptabase.init(appKey);
      }

      final prefs = await SharedPreferences.getInstance();
      _enabled = !(prefs.getBool(_optOutKey) ?? false);

      if (_enabled) {
        Aptabase.instance.trackEvent('app_started');
        appLog.i('📡 Aptabase initialized successfully');
      } else {
        appLog.i('📡 Aptabase: user opted out, telemetry disabled');
      }
    } catch (e) {
      appLog.w('📡 Aptabase: failed to initialize', error: e);
    }
  }

  static void trackScreen(String screenName) {
    if (!_enabled) return;
    Aptabase.instance.trackEvent('screen_view', {'screen': screenName});
  }

  static void trackEvent(String eventName, {Map<String, dynamic>? data}) {
    if (!_enabled) return;
    Aptabase.instance.trackEvent(eventName, data);
  }

  static Future<void> setOptOut(bool optOut) async {
    _enabled = !optOut;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_optOutKey, optOut);
  }

  static bool get isEnabled => _initialized && _enabled;
}
