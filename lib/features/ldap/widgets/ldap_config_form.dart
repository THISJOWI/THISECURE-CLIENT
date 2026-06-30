import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/features/ldap/providers/ldap_config_provider.dart';
import 'package:thisjowi/features/ldap/providers/ldap_test_provider.dart';
import 'package:thisjowi/features/ldap/widgets/ldap_test_feedback.dart';
import 'package:thisjowi/i18n/translations.dart';

class LdapConfigForm extends StatefulWidget {
  final VoidCallback? onSaved;

  const LdapConfigForm({super.key, this.onSaved});

  @override
  State<LdapConfigForm> createState() => _LdapConfigFormState();
}

class _LdapConfigFormState extends State<LdapConfigForm> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _bindDnController = TextEditingController();
  final _baseDnController = TextEditingController();
  final _usernameAttrController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final config = context.read<LdapConfigProvider>().config;
    _hostController.text = config.host;
    _portController.text = config.port;
    _bindDnController.text = config.bindDn;
    _baseDnController.text = config.baseDn;
    _usernameAttrController.text = config.usernameAttr;
    _passwordController.text = config.password;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _bindDnController.dispose();
    _baseDnController.dispose();
    _usernameAttrController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  LdapConfig _buildConfig() {
    return LdapConfig(
      host: _hostController.text.trim(),
      port: _portController.text.trim(),
      bindDn: _bindDnController.text.trim(),
      baseDn: _baseDnController.text.trim(),
      usernameAttr: _usernameAttrController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _handleTest() async {
    if (!_formKey.currentState!.validate()) return;
    final config = _buildConfig();
    await context.read<LdapConfigProvider>().saveConfig(config);
    await context.read<LdapTestProvider>().runTest(config);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final config = _buildConfig();
    await context.read<LdapConfigProvider>().saveConfig(config);
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField('LDAP Host', 'ldap.myserver.com', _hostController),
          const SizedBox(height: 12),
          _buildField('LDAP Port', '389', _portController),
          const SizedBox(height: 12),
          _buildField('Bind DN', 'cn=admin,dc=example,dc=com', _bindDnController),
          const SizedBox(height: 12),
          _buildField('Base DN', 'dc=example,dc=com', _baseDnController),
          const SizedBox(height: 12),
          _buildField('Username Attribute', 'uid', _usernameAttrController),
          const SizedBox(height: 12),
          _buildField('Bind Password', null, _passwordController, isPassword: true),
          const SizedBox(height: 16),
          Consumer<LdapTestProvider>(
            builder: (context, testProvider, _) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: testProvider.isRunning ? null : _handleTest,
                          icon: testProvider.isRunning
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.wifi_tethering),
                          label: Text('Test Connection'.i18n),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _handleSave,
                        icon: const Icon(Icons.save),
                        label: Text('Save'.i18n),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (testProvider.result != null) ...[
                    const SizedBox(height: 16),
                    LdapTestFeedback(result: testProvider.result!),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String? hint, TextEditingController controller, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label.i18n,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? '${label.i18n} is required' : null,
    );
  }
}
