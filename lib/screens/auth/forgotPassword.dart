import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/core/environment_profile_manager.dart';
import 'package:thisjowi/data/models/server_info.dart';
import 'package:thisjowi/core/exceptions/account_exceptions.dart';
import 'package:thisjowi/services/account_service.dart';
import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/screens/auth/passwordResetVerification.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AccountService _accountService = AccountService();
  final AuthService _authService = AuthService();
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
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) {
      ErrorSnackBar.show(context, 'Please enter your email'.i18n);
      return;
    }

    if (EnvironmentProfileManager().isSelfHosted && !_serverInfo.smtp) {
      ErrorSnackBar.show(context, 'Email service not configured on this server. Contact your administrator.'.i18n);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _accountService.forgotPassword(_emailController.text.trim());

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent to your email'.i18n)),
        );
        // Navigate to OTP verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PasswordResetVerificationScreen(
                    email: _emailController.text.trim(),
                  )),
        );
      }
    } on AccountException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorSnackBar.show(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorSnackBar.show(context, 'An error occurred'.i18n);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Background Gradients
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
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
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(color: Colors.transparent),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          size: 60,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'Forgot Password?'.i18n,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Enter your email address to receive a verification code.'
                            .i18n,
                        style: TextStyle(
                          fontSize: 15,
                          color: textColor.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Glassmorphism Form
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: (isDark ? const Color(0xFF2A2A2A) : Colors.white)
                                  .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: textColor.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _emailController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    labelText: 'Email'.i18n,
                                    labelStyle: TextStyle(
                                        color: textColor
                                            .withValues(alpha: 0.5)),
                                    prefixIcon: Icon(Icons.email_outlined,
                                        color: textColor
                                            .withValues(alpha: 0.7),
                                        size: 20),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                          color: textColor
                                              .withValues(alpha: 0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.primary
                                              .withValues(alpha: 0.5)),
                                    ),
                                    filled: true,
                                    fillColor:
                                        (isDark ? Colors.black : textColor).withValues(alpha: 0.1),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 18, horizontal: 20),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
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
                                        color: Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _sendOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                                color: textColor,
                                                strokeWidth: 2),
                                          )
                                        : Text(
                                            'Send OTP'.i18n,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
