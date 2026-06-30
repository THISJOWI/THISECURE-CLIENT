import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/features/ldap/providers/ldap_config_provider.dart';
import 'package:thisjowi/features/ldap/widgets/ldap_config_form.dart';
import 'package:thisjowi/features/ldap/widgets/ldap_status_indicator.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/services/token_manager.dart';

class LdapConfigScreen extends StatefulWidget {
  const LdapConfigScreen({super.key});

  @override
  State<LdapConfigScreen> createState() => _LdapConfigScreenState();
}

class _LdapConfigScreenState extends State<LdapConfigScreen> {
  bool _isDisconnecting = false;

  Future<void> _handleDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Disconnect Domain'.i18n),
        content: Text('Esta acción deshabilitará LDAP. ¿Continuar?'.i18n),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel'.i18n)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Disconnect'.i18n)),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDisconnecting = true);
    try {
      final token = await TokenManager().getToken();
      if (token == null) return;

      try {
        await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/v1/admin/organizations/ldap'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 10));
      } catch (_) {}

      if (!mounted) return;
      await context.read<LdapConfigProvider>().clearConfig();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isDisconnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LDAP Configuration'.i18n)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<LdapConfigProvider>(
              builder: (context, ldapProv, _) {
                final isConnected = ldapProv.config.host.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: LdapStatusIndicator(isConnected: isConnected),
                );
              },
            ),
            const LdapConfigForm(),
            const SizedBox(height: 24),
            Consumer<LdapConfigProvider>(
              builder: (context, ldapProv, _) {
                if (ldapProv.config.host.isEmpty) return const SizedBox.shrink();
                return OutlinedButton.icon(
                  onPressed: _isDisconnecting ? null : _handleDisconnect,
                  icon: _isDisconnecting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.link_off, color: Colors.red),
                  label: Text('Disconnect Domain'.i18n),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
