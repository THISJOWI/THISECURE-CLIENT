import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:thisjowi/core/environment_profile.dart';
import 'package:thisjowi/core/environment_profile_manager.dart';
import 'package:thisjowi/i18n/translations.dart';

class EnvironmentAddScreen extends StatefulWidget {
  const EnvironmentAddScreen({super.key});

  @override
  State<EnvironmentAddScreen> createState() => _EnvironmentAddScreenState();
}

class _EnvironmentAddScreenState extends State<EnvironmentAddScreen> {
  final _nameController = TextEditingController();
  final _hostController = TextEditingController();
  bool _useSsl = false;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    super.dispose();
  }

  String get _displayUrl {
    final host = _hostController.text.trim();
    if (host.isEmpty) return '';
    final port = _useSsl ? 443 : 80;
    final protocol = _useSsl ? 'https' : 'http';
    return '$protocol://$host:$port';
  }

  void _onSslChanged(bool v) {
    setState(() => _useSsl = v);
  }

  bool get _isFormValid =>
    _nameController.text.trim().isNotEmpty &&
    _hostController.text.trim().isNotEmpty;

  Future<void> _testConnection() async {
    final url = _displayUrl;
    if (url.isEmpty) return;

    setState(() { _isTesting = true; _testResult = null; });

    try {
      final response = await http.get(Uri.parse('$url/health')).timeout(const Duration(seconds: 10));
      setState(() {
        _testSuccess = response.statusCode == 200;
        _testResult = _testSuccess
          ? 'Connection successful'.i18n
          : 'Server responded with status ${response.statusCode}'.i18n;
      });
    } catch (e) {
      setState(() { _testResult = 'Connection failed'.i18n; _testSuccess = false; });
    } finally {
      setState(() { _isTesting = false; });
    }
  }

  Future<void> _save() async {
    final host = _hostController.text.trim();
    final name = _nameController.text.trim();
    if (host.isEmpty || name.isEmpty) return;

    final port = _useSsl ? 443 : 80;
    final protocol = _useSsl ? 'https' : 'http';
    final url = '$protocol://$host:$port';

    final profile = EnvironmentProfile(
      id: 'self_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: EnvironmentType.selfHosted,
      serverUrl: url,
      createdAt: DateTime.now(),
    );

    await EnvironmentProfileManager().addProfile(profile);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Header icon
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.dns_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Add Server'.i18n,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Connect to your own infrastructure'.i18n,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 32),

            // Form card
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                      ? const Color(0xFF2A2A2A).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.black).withValues(alpha: isDark ? 0.2 : 0.06),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Name
                      Text(
                        'Name'.i18n,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _nameController,
                        hint: 'e.g. My Server',
                        icon: Icons.label_outline,
                      ),
                      const SizedBox(height: 24),

                      // Host
                      Text(
                        'Host'.i18n,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _hostController,
                        hint: '192.168.1.100',
                        icon: Icons.computer_outlined,
                      ),
                      const SizedBox(height: 16),

                      // SSL toggle
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Secure connection (SSL)'.i18n,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const Spacer(),
                          _buildProtocolToggle(),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Test connection button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: OutlinedButton.icon(
                          onPressed: _isTesting ? null : (_isFormValid ? _testConnection : null),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _testSuccess == true
                              ? Colors.green
                              : Theme.of(context).colorScheme.primary,
                            side: BorderSide(
                              color: _testSuccess == true
                                ? Colors.green.withValues(alpha: 0.4)
                                : _testSuccess == false
                                  ? Colors.red.withValues(alpha: 0.4)
                                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: _isTesting
                            ? SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                                ),
                              )
                            : Icon(
                                _testSuccess == true
                                  ? Icons.check_circle_outline
                                  : _testSuccess == false
                                    ? Icons.error_outline
                                    : Icons.wifi_find,
                                size: 20,
                              ),
                          label: Text(
                            _isTesting
                              ? 'Testing…'
                              : _testSuccess == true
                                ? 'Connected'
                                : _testSuccess == false
                                  ? 'Connection Failed'
                                  : 'Test Connection',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Save button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isFormValid ? _save : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Add Server'.i18n,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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

            // Preview URL
            if (_displayUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link, size: 14,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)),
                      const SizedBox(width: 8),
                      Text(
                        _displayUrl,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint.i18n,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, size: 20,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
      ),
    );
  }

  Widget _buildProtocolToggle() {
    return Switch(
      value: _useSsl,
      onChanged: _onSslChanged,
      activeThumbColor: Theme.of(context).colorScheme.onSurface,
      activeTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      inactiveThumbColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
    );
  }
}
