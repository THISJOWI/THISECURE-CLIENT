import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/components/auth_method_selector.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/components/navigation.dart';
import 'package:thisjowi/core/environment_profile_manager.dart';
import 'package:thisjowi/core/exceptions/auth_exceptions.dart';
import 'package:thisjowi/data/models/server_info.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/services/google_auth_service.dart';
import 'package:thisjowi/services/microsoft_auth_service.dart';
import 'login.dart';

class AuthSelectionScreen extends StatefulWidget {
  const AuthSelectionScreen({super.key});

  @override
  State<AuthSelectionScreen> createState() => _AuthSelectionScreenState();
}

class _AuthSelectionScreenState extends State<AuthSelectionScreen> {
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final MicrosoftAuthService _microsoftAuthService = MicrosoftAuthService();
  bool _isLoading = false;
  ServerInfo _serverInfo = ServerInfo.empty();

  @override
  void initState() {
    super.initState();
    _fetchServerInfo();
  }

  Future<void> _fetchServerInfo() async {
    if (!EnvironmentProfileManager().isSelfHosted) return;
    final info = await _authService.getServerInfo();
    if (mounted) setState(() => _serverInfo = info);
  }

  @override
  void dispose() {
    _googleAuthService.dispose();
    _microsoftAuthService.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await _googleAuthService.login();
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyBottomNavigation()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleMicrosoftLogin() async {
    setState(() => _isLoading = true);
    try {
      await _microsoftAuthService.login();
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyBottomNavigation()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _handleLdapLogin() {
    final emailCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: SizedBox(
          width: 400,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                      ? const Color(0xFF2A2A2A).withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Corporate LDAP'.i18n,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in with your corporate credentials'.i18n,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: emailCtrl,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'user@company.com',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: pwdCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FutureBuilder(
                        future: null,
                        builder: (context, snapshot) {
                          return ElevatedButton(
                            onPressed: () async {
                              final email = emailCtrl.text.trim();
                              final password = pwdCtrl.text;
                              if (email.isEmpty || password.isEmpty) return;

                              Navigator.pop(ctx);

                              setState(() => _isLoading = true);
                              try {
                                await _authService.loginWithLdap(email, password);
                                if (!mounted) return;
                                setState(() => _isLoading = false);
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const MyBottomNavigation()),
                                  (route) => false,
                                );
                              } on AuthException catch (e) {
                                if (!mounted) return;
                                setState(() => _isLoading = false);
                                ErrorSnackBar.show(context, e.message);
                              } catch (e) {
                                if (!mounted) return;
                                setState(() => _isLoading = false);
                                ErrorSnackBar.show(context, 'Error: $e');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Sign In'.i18n,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showLdap = EnvironmentProfileManager().isSelfHosted && _serverInfo.ldap;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cs.primary,
                                  cs.primary.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              color: cs.onPrimary,
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'THISECURE',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Secure password manager'.i18n,
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    AuthMethodSelector(
                      onLdapTap: showLdap ? _handleLdapLogin : null,
                      onRegularTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      onGoogleTap: !_isLoading ? _handleGoogleLogin : null,
                      onMicrosoftTap: !_isLoading ? _handleMicrosoftLogin : null,
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: cs.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'How do I know which one to choose?'.i18n,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'If your company uses LDAP, select "Corporate LDAP" and enter your corporate email and password. Otherwise, use "Regular Account" to sign in with your email and password.'.i18n,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: CircularProgressIndicator(color: cs.primary),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                '© 2026 THISECURE. All rights reserved.'.i18n,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
