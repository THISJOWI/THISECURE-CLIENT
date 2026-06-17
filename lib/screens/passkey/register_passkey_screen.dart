import 'package:flutter/material.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/components/liquid_glass.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/services/passkeyService.dart';
import 'package:thisjowi/services/passkey_ceremony_service.dart';

class RegisterPasskeyScreen extends StatefulWidget {
  final PasskeyService passkeyService;
  final PasskeyCeremonyService ceremonyService;
  final String userDisplayName;

  const RegisterPasskeyScreen({
    super.key,
    required this.passkeyService,
    required this.ceremonyService,
    required this.userDisplayName,
  });

  @override
  State<RegisterPasskeyScreen> createState() => _RegisterPasskeyScreenState();
}

class _RegisterPasskeyScreenState extends State<RegisterPasskeyScreen> {
  final _nameController = TextEditingController();
  bool _busy = false;
  final String _biometricLabel = 'fingerprint, Face ID, or screen lock';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ErrorSnackBar.showWarning(context, 'Passkey name'.i18n);
      return;
    }
    setState(() => _busy = true);
    try {
      final payload = await widget.ceremonyService.register(
        name: name,
        userDisplayName: widget.userDisplayName,
      );
      if (!mounted) return;
      final res = await widget.passkeyService.create(payload);
      if (!mounted) return;
      if (res['success'] == true) {
        ErrorSnackBar.showSuccess(context, 'Passkey created'.i18n);
        Navigator.pop(context, true);
      } else {
        ErrorSnackBar.show(context, res['message'] ?? 'Passkey creation failed'.i18n);
      }
    } catch (e) {
      if (!mounted) return;
      if (e.toString().toLowerCase().contains('cancel')) {
        ErrorSnackBar.showInfo(context, 'Registration cancelled'.i18n);
      } else {
        ErrorSnackBar.show(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register passkey'.i18n),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LiquidGlass.wrap(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.fingerprint,
                    size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Use %s to create this passkey'.fill([_biometricLabel]).i18n,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: 'Passkey name'.i18n,
                    prefixIcon: const Icon(Icons.title),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _register,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Register passkey'.i18n),
                  ),
                ),
              ],
            ),
            context,
            borderRadius: 16,
            padding: const EdgeInsets.all(20),
          ),
        ),
      ),
    );
  }
}
