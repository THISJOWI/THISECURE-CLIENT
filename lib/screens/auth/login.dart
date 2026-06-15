import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/core/app_colors.dart';
import 'package:thisjowi/core/exceptions/auth_exceptions.dart';
import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/services/biometricService.dart';
import 'package:thisjowi/services/google_auth_service.dart';
import 'package:thisjowi/services/github_auth_service.dart';
import 'package:thisjowi/services/microsoft_auth_service.dart';
import 'package:thisjowi/services/token_manager.dart';
import 'package:thisjowi/services/offline_auth_service.dart';
import 'package:thisjowi/components/social_login_button.dart';
import 'package:thisjowi/components/navigation.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/screens/auth/forgotPassword.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final BiometricService _biometricService = BiometricService();
  final AuthService _authService = AuthService();
  final OfflineAuthService _offlineAuthService = OfflineAuthService();
  final TokenManager _tokenManager = TokenManager();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final GithubAuthService _githubAuthService = GithubAuthService();
  final MicrosoftAuthService _microsoftAuthService = MicrosoftAuthService();
  bool _isLoading = false;
  bool _hasSavedSession = false;
  bool _biometricAvailable = false;
  String _biometricType = 'Biometric';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await _googleAuthService.login();
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

  Future<void> _handleGithubLogin() async {
    setState(() => _isLoading = true);
    try {
      await _githubAuthService.login();
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

  Future<void> _handleMicrosoftLogin() async {
    setState(() => _isLoading = true);
    try {
      await _microsoftAuthService.login();
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

  Future<void> _checkBiometricAvailability() async {
    final token = await _tokenManager.getToken();
    final userId = await _tokenManager.getUserId();
    final canCheck = await _biometricService.canCheckBiometrics();
    final isEnabled = await _biometricService.isBiometricEnabled(userId: userId);
    final biometricType = await _biometricService.getBiometricTypeName();

    if (mounted) {
      setState(() {
        _hasSavedSession = token != null && token.isNotEmpty;
        _biometricAvailable = canCheck && isEnabled && _hasSavedSession;
        _biometricType = biometricType;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _isLoading = true);

    final authenticated = await _biometricService.authenticate(
      localizedReason: 'Authenticate to access THISECURE'.i18n,
    );

    if (authenticated && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyBottomNavigation()),
        (route) => false,
      );
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorSnackBar.show(context, 'Authentication failed'.i18n);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Login automático con LDAP cuando el dominio del email lo tiene habilitado


  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ErrorSnackBar.show(
          context, 'Please complete email and password'.i18n);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.login(email, password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Navigate to main screen replacing the stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyBottomNavigation()),
        (route) => false,
      );
    } on NetworkException catch (_) {
      // Si falla la conexión, intentar login offline
      await _tryOfflineLogin(email, password);
    } on SocketException catch (_) {
      // Si falla la conexión, intentar login offline
      await _tryOfflineLogin(email, password);
    } on ServerException catch (_) {
      // Si el servidor devuelve error (incluyendo 530), intentar login offline
      await _tryOfflineLogin(email, password);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorSnackBar.show(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorSnackBar.show(context, 'Login failed'.i18n);
    }
  }

  /// Intenta login offline cuando no hay conexión al servidor
  Future<void> _tryOfflineLogin(String email, String password) async {
    try {
      // Verificar si el usuario existe localmente
      final isLocalUser = await _offlineAuthService.isUserLocal(email);

      if (!isLocalUser) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ErrorSnackBar.show(
          context,
          'No server connection and user does not exist locally'.i18n
        );
        return;
      }

      // Intentar login offline
      final user = await _offlineAuthService.loginOffline(email, password);

      if (user != null) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MyBottomNavigation()),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ErrorSnackBar.show(
          context,
          'Incorrect password for local user'.i18n,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
        ErrorSnackBar.show(
        context,
        "Offline login error: %s".i18n.fill([e.toString()]),
      );
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
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
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
                    (isDark ? AppColors.accent : Theme.of(context).colorScheme.primary)
                        .withValues(alpha: 0.3),
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

          Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.4),
                              blurRadius: 40,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.lock_person_rounded,
                          size: 70,
                          color: isDark ? AppColors.text : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(
                        "Welcome Back".i18n,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          color: isDark ? AppColors.text : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sign in to continue".i18n,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? AppColors.text.withValues(alpha: 0.6) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(32.0),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2A2A).withValues(alpha: 0.85)
                                  : Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.08),
                                width: 1,
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
                                  controller: _emailController,
                                  style: TextStyle(color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface),
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.emailAddress,
                                  onFieldSubmitted: (_) =>
                                      _passwordFocusNode.requestFocus(),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.email_outlined,
                                        color: isDark
                                            ? AppColors.text.withValues(alpha: 0.7)
                                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        size: 20),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 20),
                                    labelText: "Email".i18n,
                                    labelStyle: TextStyle(
                                        color: isDark
                                            ? AppColors.text.withValues(alpha: 0.5)
                                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.1)
                                              : Colors.black.withValues(alpha: 0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.5)),
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.black.withValues(alpha: 0.2)
                                        : Colors.black.withValues(alpha: 0.03),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: _obscurePassword,
                                  style: TextStyle(color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface),
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.lock_outline,
                                        color: isDark
                                            ? AppColors.text.withValues(alpha: 0.7)
                                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        size: 20),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: isDark
                                            ? AppColors.text.withValues(alpha: 0.5)
                                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    labelText: "Password".i18n,
                                    labelStyle: TextStyle(
                                        color: isDark
                                            ? AppColors.text.withValues(alpha: 0.5)
                                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.1)
                                              : Colors.black.withValues(alpha: 0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.5)),
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.black.withValues(alpha: 0.2)
                                        : Colors.black.withValues(alpha: 0.03),
                                  ),
                                ),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Forgot Password?'.i18n,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.text.withValues(alpha: 0.7)
                                            : Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Login Button
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.tertiary
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            "Sign In".i18n,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Social Login Buttons
                      if (!_isLoading)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                                    SocialLoginButton(
                                imagePath: 'assets/google_logo.png',
                                color: Colors.red,
                                onTap: _handleGoogleLogin,
                              ),
                            const SizedBox(width: 20),
                            SocialLoginButton(
                              imagePath: 'assets/github_logo.png',
                              color: Colors.black,
                              onTap: _handleGithubLogin,
                            ),
                            const SizedBox(width: 20),
                            SocialLoginButton(
                              icon: Icons.window,
                              color: const Color(0xFF00A4EF),
                              onTap: _handleMicrosoftLogin,
                            ),
                            if (_biometricAvailable) ...[
                              const SizedBox(width: 20),
                              GestureDetector(
                                onTap: _handleBiometricLogin,
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : Colors.black.withValues(alpha: 0.1)),
                                  ),
                                  child: Icon(
                                    _biometricType == 'Face ID'
                                        ? Icons.face_rounded
                                        : Icons.fingerprint_rounded,
                                    size: 30,
                                    color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ".i18n,
                            style: TextStyle(
                                color: isDark
                                    ? AppColors.text.withValues(alpha: 0.6)
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                                context, '/register'),
                            child: Text(
                              "Sign Up".i18n,
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
}
