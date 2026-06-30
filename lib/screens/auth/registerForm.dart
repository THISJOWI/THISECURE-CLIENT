import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/components/navigation.dart';
import 'package:thisjowi/components/social_login_button.dart';
import 'package:thisjowi/components/environment_mode_chip.dart';
import 'package:thisjowi/core/environment_profile_manager.dart';
import 'package:thisjowi/data/models/server_info.dart';
import 'package:thisjowi/core/exceptions/auth_exceptions.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/screens/settings/LegalDocumentsScreen.dart';
import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/services/google_auth_service.dart';
import 'package:thisjowi/services/github_auth_service.dart';
import 'package:thisjowi/services/microsoft_auth_service.dart';

class RegisterForm extends StatefulWidget {
  final Function(Map<String, dynamic> result) onSuccess;
  final VoidCallback? onBack;
  final String accountType;

  const RegisterForm({
    super.key,
    required this.onSuccess,
    this.onBack,
    required this.accountType,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _fullNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final GithubAuthService _githubAuthService = GithubAuthService();
  final MicrosoftAuthService _microsoftAuthService = MicrosoftAuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedPolicies = false;
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
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSocialLogin(Future<void> Function() loginMethod) async {
    setState(() => _isLoading = true);
    try {
      await loginMethod();
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyBottomNavigation()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorSnackBar.show(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ErrorSnackBar.show(context, 'Please complete all fields'.i18n);
      return;
    }

    if (!_acceptedPolicies) {
      ErrorSnackBar.show(context, 'You must accept the terms to continue'.i18n);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (EnvironmentProfileManager().isSelfHosted && !_serverInfo.smtp) {
        await _authService.register(
          email: email,
          password: password,
          fullName: fullName,
          otp: '',
        );
        if (!mounted) return;
        setState(() => _isLoading = false);
        widget.onSuccess({
          'email': email,
          'password': password,
          'fullName': fullName,
          'token': 'bypass',
        });
      } else {
        await _authService.initiateRegister(email);
        if (!mounted) return;
        setState(() => _isLoading = false);
        widget.onSuccess({'email': email, 'password': password, 'fullName': fullName, 'token': null});
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorSnackBar.show(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorSnackBar.show(context, 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: Colors.transparent),
          ),
          if (widget.onBack != null)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  onPressed: widget.onBack,
                ),
              ),
            ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_add_rounded,
                          size: 70,
                          color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create Account'.i18n,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign up to get started'.i18n,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white.withValues(alpha: 0.6) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (widget.accountType.isNotEmpty)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.accountType == 'Business' ? 'Business Account' : 'Personal Account',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Environment mode toggle
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: EnvironmentModeChip(showServerConfig: true),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A2A2A).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? Colors.black : Colors.black).withValues(alpha: isDark ? 0.2 : 0.08),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _fullNameController,
                                  style: TextStyle(color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface),
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.person_outline,
                                        color: isDark ? Colors.white.withValues(alpha: 0.7) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        size: 20),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                    labelText: 'Full Name'.i18n,
                                    labelStyle: TextStyle(
                                        color: isDark ? Colors.white.withValues(alpha: 0.5) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                                    ),
                                    filled: true,
                                    fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _emailController,
                                  style: TextStyle(color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface),
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.emailAddress,
                                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.email_outlined,
                                        color: isDark ? Colors.white.withValues(alpha: 0.7) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        size: 20),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                    labelText: 'Email'.i18n,
                                    labelStyle: TextStyle(
                                        color: isDark ? Colors.white.withValues(alpha: 0.5) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                                    ),
                                    filled: true,
                                    fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface),
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleRegister(),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.lock_outline,
                                        color: isDark ? Colors.white.withValues(alpha: 0.7) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        size: 20),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: isDark ? Colors.white.withValues(alpha: 0.5) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    labelText: 'Password'.i18n,
                                    labelStyle: TextStyle(
                                        color: isDark ? Colors.white.withValues(alpha: 0.5) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                                    ),
                                    filled: true,
                                    fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _acceptedPolicies,
                                        onChanged: (v) => setState(() => _acceptedPolicies = v ?? false),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _acceptedPolicies = !_acceptedPolicies),
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark ? Colors.white.withValues(alpha: 0.7) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                              height: 1.4,
                                            ),
                                            children: [
                                              TextSpan(text: 'I accept the '.i18n),
                                              WidgetSpan(
                                                alignment: PlaceholderAlignment.middle,
                                                child: GestureDetector(
                                                  onTap: () => Navigator.of(context).push(
                                                    MaterialPageRoute(builder: (_) => const LegalDocumentsScreen()),
                                                  ),
                                                  child: Text(
                                                    'Privacy Policy'.i18n,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Theme.of(context).colorScheme.primary,
                                                      fontWeight: FontWeight.w600,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              TextSpan(text: ' and '.i18n),
                                              WidgetSpan(
                                                alignment: PlaceholderAlignment.middle,
                                                child: GestureDetector(
                                                  onTap: () => Navigator.of(context).push(
                                                    MaterialPageRoute(builder: (_) => const LegalDocumentsScreen()),
                                                  ),
                                                  child: Text(
                                                    'Terms & Conditions'.i18n,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Theme.of(context).colorScheme.primary,
                                                      fontWeight: FontWeight.w600,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.tertiary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : Text('Create Account'.i18n,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!_isLoading)
                        _buildSocialButtons(),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ".i18n,
                            style: TextStyle(
                                color: isDark ? Colors.white.withValues(alpha: 0.6) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: Text(
                              "Sign In".i18n,
                              style: TextStyle(
                                color: isDark ? Colors.white : Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButtons() {
    final isSelfHosted = EnvironmentProfileManager().isSelfHosted;
    final showGoogle = !isSelfHosted || _serverInfo.hasGoogle;
    final showGithub = !isSelfHosted || _serverInfo.hasGithub;
    final showMicrosoft = !isSelfHosted || _serverInfo.hasMicrosoft;
    final hasAny = showGoogle || showGithub || showMicrosoft;
    if (!hasAny) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showGoogle)
            SocialLoginButton(
              imagePath: 'assets/google_logo.png',
              color: Colors.red,
              onTap: () => _handleSocialLogin(_googleAuthService.login),
            ),
          if (showGoogle && (showGithub || showMicrosoft))
            const SizedBox(width: 20),
          if (showGithub)
            SocialLoginButton(
              imagePath: 'assets/github_logo.png',
              color: Colors.black,
              onTap: () => _handleSocialLogin(_githubAuthService.login),
            ),
          if (showGithub && showMicrosoft)
            const SizedBox(width: 20),
          if (showMicrosoft)
            SocialLoginButton(
              icon: Icons.window,
              color: const Color(0xFF00A4EF),
              onTap: () => _handleSocialLogin(_microsoftAuthService.login),
            ),
        ],
      ),
    );
  }
}
