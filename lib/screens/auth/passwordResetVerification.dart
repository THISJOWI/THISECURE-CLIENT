import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/i18n/translations.dart';

class PasswordResetVerificationScreen extends StatefulWidget {
  final String email;
  const PasswordResetVerificationScreen({super.key, required this.email});

  @override
  State<PasswordResetVerificationScreen> createState() => _PasswordResetVerificationScreenState();
}

class _PasswordResetVerificationScreenState extends State<PasswordResetVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isVerified = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    final code = _codeController.text.trim();
    if (code.length == 6 && !_isLoading && !_isVerified) {
      _verifyOtp();
    }
  }

  // Step 1: Verify OTP
  Future<void> _verifyOtp() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter the code'.i18n)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.authUrl}/verify-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'otp': code}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        setState(() {
          _isVerified = true;
        });
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Code verified. Set new password.'.i18n)),
            );
        }
      } else {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(body['message'] ?? 'Invalid code'.i18n)),
            );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connection error'.i18n)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Step 2: Reset Password
  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final otp = _codeController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter new password'.i18n)),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match'.i18n)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.authUrl}/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
            'email': widget.email, 
            'otp': otp, 
            'newPassword': newPassword
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Password reset successfully'.i18n)),
            );
            // Navigate to login or home
            Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(body['message'] ?? 'Failed to reset password'.i18n)),
            );
        }
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connection error'.i18n)),
        );
       }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Background Gradients
          Positioned(
            top: -50,
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
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
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
                            color: Colors.white.withValues(alpha: 0.05),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isVerified ? Icons.lock_open_rounded : Icons.verified_user_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),

                         Text(
                          _isVerified ? 'Set New Password'.i18n : 'Verification Code'.i18n,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                         Text(
                          _isVerified 
                             ? 'Please enter your new password.'.i18n
                             : 'We sent a verification code to your email.'.i18n,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.6),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        
                        if (!_isVerified) ...[
                             // Glassmorphism Container for OTP
                             ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E).withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: _codeController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          letterSpacing: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        maxLength: 6,
                                        decoration: InputDecoration(
                                          counterText: "",
                                          hintText: "******",
                                          hintStyle: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            letterSpacing: 12,
                                          ),
                                          filled: true,
                                          fillColor: Colors.black.withValues(alpha: 0.2),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                                              width: 1,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: Colors.white.withValues(alpha: 0.1),
                                              width: 1,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 20),
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      Container(
                                        width: double.infinity,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: LinearGradient(
                                            colors: [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.tertiary],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _verifyOtp,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 24, 
                                                  width: 24, 
                                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                                )
                                              : Text(
                                                  'Verify Code'.i18n,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ] else ...[
                            // Glassmorphism Container for Password Reset
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E).withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: _newPasswordController,
                                        style: const TextStyle(color: Colors.white),
                                        obscureText: _obscurePassword,
                                        decoration: InputDecoration(
                                          labelText: 'New Password'.i18n,
                                          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                          prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.7), size: 20),
                                          suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscurePassword ? Icons.visibility : Icons.visibility_off, 
                                                color: Colors.white.withValues(alpha: 0.5),
                                                size: 20,
                                              ),
                                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                                          ),
                                          filled: true,
                                          fillColor: Colors.black.withValues(alpha: 0.2),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      TextField(
                                        controller: _confirmPasswordController,
                                        style: const TextStyle(color: Colors.white),
                                        obscureText: _obscurePassword,
                                        decoration: InputDecoration(
                                          labelText: 'Confirm Password'.i18n,
                                          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                          prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.7), size: 20),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                                          ),
                                          filled: true,
                                          fillColor: Colors.black.withValues(alpha: 0.2),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      Container(
                                        width: double.infinity,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: LinearGradient(
                                            colors: [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.tertiary],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _resetPassword,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 24, 
                                                  width: 24, 
                                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                                )
                                              : Text(
                                                  'Reset Password'.i18n,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ]
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
