import 'package:flutter/material.dart';
import 'package:thisjowi/core/environment_profile_manager.dart';
import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/screens/auth/registerForm.dart';

class RegisterFlowScreen extends StatefulWidget {
  final bool isEmbedded;
  final Function(Map<String, dynamic>)? onSuccess;

  const RegisterFlowScreen({
    super.key,
    this.isEmbedded = false,
    this.onSuccess,
  });

  @override
  State<RegisterFlowScreen> createState() => _RegisterFlowScreenState();
}

class _RegisterFlowScreenState extends State<RegisterFlowScreen> {
  final String _accountType = 'Community';
  final AuthService _authService = AuthService();
  bool _checkingLdap = true;

  @override
  void initState() {
    super.initState();
    _checkLdapEnabled();
  }

  Future<void> _checkLdapEnabled() async {
    if (!EnvironmentProfileManager().isSelfHosted) {
      if (mounted) setState(() => _checkingLdap = false);
      return;
    }
    final info = await _authService.getServerInfo();
    if (!mounted) return;
    if (info.ldap) {
      Navigator.of(context).pushReplacementNamed('/authSelection');
      return;
    }
    if (mounted) setState(() => _checkingLdap = false);
  }

  void _goBack() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _handleSuccess(Map<String, dynamic> result) {
    if (widget.onSuccess != null) {
      widget.onSuccess!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_checkingLdap) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RegisterForm(
          accountType: _accountType,
          onSuccess: _handleSuccess,
          onBack: _goBack,
        ),
      ),
    );
  }
}
