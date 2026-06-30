import 'package:flutter/foundation.dart';
import 'package:thisjowi/core/environment_profile_manager.dart';

class DeploymentProvider extends ChangeNotifier {
  bool get isSelfHosted => EnvironmentProfileManager().isSelfHosted;
  bool get isCloud => EnvironmentProfileManager().isCloud;
  String get deploymentMode => EnvironmentProfileManager().isCloud ? 'Cloud' : 'SelfHosted';

  Future<void> loadFromPrefs() async {
    notifyListeners();
  }

  Future<void> setDeploymentMode(String mode) async {
    notifyListeners();
  }
}
