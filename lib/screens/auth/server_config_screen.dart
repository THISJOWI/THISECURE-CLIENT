import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/i18n/translations.dart';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  bool _useSsl = true;
  bool _isSaving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _portController.text = '443';
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHost = prefs.getString('self_hosted_host') ?? '';
    final savedPort = prefs.getString('self_hosted_port') ?? '443';
    final savedSsl = prefs.getBool('self_hosted_use_ssl') ?? true;
    if (mounted) {
      setState(() {
        _hostController.text = savedHost;
        _portController.text = savedPort;
        _useSsl = savedSsl;
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter the server host".i18n),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deployment_mode', 'SelfHosted');
    await prefs.setString('self_hosted_host', host);
    final port = _portController.text.trim();
    await prefs.setString('self_hosted_port', port);
    await prefs.setBool('self_hosted_use_ssl', _useSsl);
    final protocol = _useSsl ? 'https' : 'http';
    final url = port.isNotEmpty ? '$protocol://$host:$port' : '$protocol://$host';
    await ApiConfig.saveManualBaseUrl(url);

    if (mounted) {
      Navigator.pop(context, true);
    }
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
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(Icons.dns_outlined, size: 60,
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Server Configuration".i18n,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Configure your self-hosted server".i18n,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white.withValues(alpha: 0.6)
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A2A).withValues(alpha: 0.85)
                              : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _hostController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                              ),
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.url,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.language,
                                    color: isDark ? Colors.white.withValues(alpha: 0.7)
                                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                                labelText: "Server Host".i18n,
                                hintText: "api.myserver.com",
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.white.withValues(alpha: 0.3)
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                ),
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.white.withValues(alpha: 0.5)
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.black.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.03),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _portController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                              ),
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.settings_ethernet,
                                    color: isDark ? Colors.white.withValues(alpha: 0.7)
                                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                                labelText: "Server Port".i18n,
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.white.withValues(alpha: 0.5)
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.black.withValues(alpha: 0.1),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.black.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.03),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Material(
                              type: MaterialType.transparency,
                              child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                "Use SSL".i18n,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                _useSsl ? "https://" : "http://",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white.withValues(alpha: 0.5)
                                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                              value: _useSsl,
                              onChanged: (value) {
                                setState(() {
                                  _useSsl = value;
                                  _portController.text = value ? '443' : '80';
                                });
                              },
                              activeTrackColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4),
                              activeThumbColor: Theme.of(context).colorScheme.secondary,
                            ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveAndContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text("Save & Continue".i18n,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
