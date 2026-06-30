# LDAP Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Isolate LDAP into `lib/features/ldap/`, centralize feature flags via `DeploymentProvider`, add granular connection test, and add LDAP step to registration flow (SelfHosted only). Cloud users never see LDAP.

**Architecture:** `DeploymentProvider` (ChangeNotifier) provides `isSelfHosted`/`isLdapConfigured`. `LdapConfigProvider` manages LDAP config CRUD. `LdapTestProvider` runs a state-machine test (TCP→Bind→Search). All LDAP UI lives under `lib/features/ldap/`.

**Tech Stack:** Flutter, Provider, SharedPreferences, http

---

### Task 1: Create DeploymentProvider

**Files:**
- Create: `lib/features/deployment/providers/deployment_provider.dart`

- [ ] **Step 1: Write the file**

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeploymentProvider extends ChangeNotifier {
  String _deploymentMode = '';
  bool _ldapConfigured = false;
  bool _ldapAdmin = false;

  bool get isSelfHosted => _deploymentMode == 'SelfHosted';
  bool get isCloud => _deploymentMode == 'Cloud';
  bool get isLdapConfigured => _ldapConfigured;
  bool get isLdapAdmin => _ldapAdmin;
  String get deploymentMode => _deploymentMode;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _deploymentMode = prefs.getString('deployment_mode') ?? '';
    _ldapConfigured = prefs.getBool('ldap_configured') ?? false;
    notifyListeners();
  }

  Future<void> setDeploymentMode(String mode) async {
    _deploymentMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deployment_mode', mode);
    notifyListeners();
  }

  Future<void> setLdapConfigured(bool value) async {
    _ldapConfigured = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ldap_configured', value);
    notifyListeners();
  }

  void setLdapAdmin(bool value) {
    _ldapAdmin = value;
    notifyListeners();
  }

  void clearLdap() {
    _ldapConfigured = false;
    _ldapAdmin = false;
    notifyListeners();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/deployment/providers/deployment_provider.dart
git commit -m "feat: add DeploymentProvider for centralized feature flags"
```

---

### Task 2: Create LdapConfigProvider

**Files:**
- Create: `lib/features/ldap/providers/ldap_config_provider.dart`

- [ ] **Step 1: Write the file**

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thisjowi/data/local/secure_storage_service.dart';

class LdapConfig {
  final String host;
  final String port;
  final String bindDn;
  final String baseDn;
  final String usernameAttr;
  final String password;

  LdapConfig({
    this.host = '',
    this.port = '389',
    this.bindDn = '',
    this.baseDn = '',
    this.usernameAttr = 'uid',
    this.password = '',
  });

  LdapConfig copyWith({
    String? host,
    String? port,
    String? bindDn,
    String? baseDn,
    String? usernameAttr,
    String? password,
  }) {
    return LdapConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      bindDn: bindDn ?? this.bindDn,
      baseDn: baseDn ?? this.baseDn,
      usernameAttr: usernameAttr ?? this.usernameAttr,
      password: password ?? this.password,
    );
  }

  String get ldapUrl => host.isNotEmpty ? 'ldap://$host:$port' : '';
}

class LdapConfigProvider extends ChangeNotifier {
  LdapConfig _config = LdapConfig();
  final SecureStorageService _secureStorage = SecureStorageService();

  LdapConfig get config => _config;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('ldap_host') ?? '';
    final port = prefs.getString('ldap_port') ?? '389';
    final bindDn = prefs.getString('ldap_bind_dn') ?? '';
    final baseDn = prefs.getString('ldap_base_dn') ?? '';
    final usernameAttr = prefs.getString('ldap_username_attr') ?? 'uid';
    final password = await _secureStorage.getValue('ldap_password') ?? '';
    _config = LdapConfig(
      host: host,
      port: port,
      bindDn: bindDn,
      baseDn: baseDn,
      usernameAttr: usernameAttr,
      password: password,
    );
    notifyListeners();
  }

  Future<void> saveConfig(LdapConfig config) async {
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ldap_host', config.host);
    await prefs.setString('ldap_port', config.port);
    await prefs.setString('ldap_bind_dn', config.bindDn);
    await prefs.setString('ldap_base_dn', config.baseDn);
    await prefs.setString('ldap_username_attr', config.usernameAttr);
    await _secureStorage.saveValue('ldap_password', config.password);
    notifyListeners();
  }

  Future<void> clearConfig() async {
    _config = LdapConfig();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ldap_host');
    await prefs.remove('ldap_port');
    await prefs.remove('ldap_bind_dn');
    await prefs.remove('ldap_base_dn');
    await prefs.remove('ldap_username_attr');
    await _secureStorage.deleteValue('ldap_password');
    notifyListeners();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/ldap/providers/ldap_config_provider.dart
git commit -m "feat: add LdapConfigProvider for LDAP config CRUD"
```

---

### Task 3: Create LdapConnectionService

**Files:**
- Create: `lib/features/ldap/services/ldap_connection_service.dart`

- [ ] **Step 1: Write the file**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/services/token_manager.dart';

enum LdapTestStep { tcpConnection, bind, searchBaseDn }

class LdapTestStepResult {
  final LdapTestStep step;
  final bool success;
  final String message;

  LdapTestStepResult({required this.step, required this.success, required this.message});
}

class LdapTestResult {
  final bool overallSuccess;
  final List<LdapTestStepResult> steps;
  final String? firstError;

  LdapTestResult({required this.overallSuccess, required this.steps, this.firstError});
}

class LdapConnectionService {
  TokenManager get _tokenManager => TokenManager();

  Future<LdapTestResult> testConnection({
    required String host,
    required String port,
    required String bindDn,
    required String baseDn,
    required String password,
  }) async {
    final steps = <LdapTestStepResult>[];
    final ldapUrl = 'ldap://$host:$port';

    // Step 1: TCP connection
    try {
      final socket = await Socket.connect(host, int.tryParse(port) ?? 389,
          timeout: const Duration(seconds: 10));
      socket.destroy();
      steps.add(LdapTestStepResult(
        step: LdapTestStep.tcpConnection,
        success: true,
        message: 'Servidor LDAP alcanzable en $host:$port',
      ));
    } on SocketException catch (e) {
      steps.add(LdapTestStepResult(
        step: LdapTestStep.tcpConnection,
        success: false,
        message: 'No se puede conectar a $host:$port: ${e.message}',
      ));
      return LdapTestResult(
        overallSuccess: false,
        steps: steps,
        firstError: 'Host no alcanzable. Verifica la dirección y el puerto.',
      );
    } catch (e) {
      steps.add(LdapTestStepResult(
        step: LdapTestStep.tcpConnection,
        success: false,
        message: 'Error de conexión: $e',
      ));
      return LdapTestResult(
        overallSuccess: false,
        steps: steps,
        firstError: 'Error inesperado al conectar con el servidor.',
      );
    }

    // Step 2 & 3: Delegate to backend for Bind + Base DN search
    final token = await _tokenManager.getToken();
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/organizations/test-connection'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'ldapUrl': ldapUrl,
              'ldapBaseDn': baseDn,
              'ldapBindDn': bindDn,
              'ldapBindPassword': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(response.body);
      final success = response.statusCode == 200 && body['success'] == true;

      if (bindDn.isNotEmpty) {
        if (success) {
          steps.add(LdapTestStepResult(
            step: LdapTestStep.bind,
            success: true,
            message: 'Bind exitoso',
          ));
        } else {
          steps.add(LdapTestStepResult(
            step: LdapTestStep.bind,
            success: false,
            message: body['message'] ?? 'Bind fallido',
          ));
          return LdapTestResult(
            overallSuccess: false,
            steps: steps,
            firstError: 'Credenciales LDAP inválidas. Verifica Bind DN y contraseña.',
          );
        }
      }

      if (success) {
        steps.add(LdapTestStepResult(
          step: LdapTestStep.searchBaseDn,
          success: true,
          message: 'Base DN encontrada',
        ));
      } else {
        steps.add(LdapTestStepResult(
          step: LdapTestStep.searchBaseDn,
          success: false,
          message: body['message'] ?? 'Base DN no encontrada',
        ));
        return LdapTestResult(
          overallSuccess: false,
          steps: steps,
          firstError: 'Base DN no encontrada. Verifica la ruta.',
        );
      }

      return LdapTestResult(overallSuccess: true, steps: steps);
    } on SocketException {
      return LdapTestResult(
        overallSuccess: false,
        steps: steps,
        firstError: 'No se puede conectar al backend desde el cliente.',
      );
    } catch (e) {
      steps.add(LdapTestStepResult(
        step: LdapTestStep.bind,
        success: false,
        message: e.toString(),
      ));
      return LdapTestResult(
        overallSuccess: false,
        steps: steps,
        firstError: 'Error de conexión con el servidor.',
      );
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/ldap/services/ldap_connection_service.dart
git commit -m "feat: add LdapConnectionService with granular test steps"
```

---

### Task 4: Create LdapTestProvider

**Files:**
- Create: `lib/features/ldap/providers/ldap_test_provider.dart`

- [ ] **Step 1: Write the file**

```dart
import 'package:flutter/foundation.dart';
import 'package:thisjowi/features/ldap/services/ldap_connection_service.dart';
import 'package:thisjowi/features/ldap/providers/ldap_config_provider.dart';

enum LdapTestStatus { idle, testing, success, error }

class LdapTestProvider extends ChangeNotifier {
  final LdapConnectionService _connectionService = LdapConnectionService();
  final LdapConfigProvider _configProvider;

  LdapTestStatus _status = LdapTestStatus.idle;
  LdapTestResult? _result;
  bool _isRunning = false;

  LdapTestProvider(this._configProvider);

  LdapTestStatus get status => _status;
  LdapTestResult? get result => _result;
  bool get isRunning => _isRunning;
  bool get isSuccess => _status == LdapTestStatus.success;

  Future<void> runTest() async {
    if (_isRunning) return;
    _isRunning = true;
    _status = LdapTestStatus.testing;
    _result = null;
    notifyListeners();

    try {
      final config = _configProvider.config;
      _result = await _connectionService.testConnection(
        host: config.host,
        port: config.port,
        bindDn: config.bindDn,
        baseDn: config.baseDn,
        password: config.password,
      );
      _status = _result!.overallSuccess ? LdapTestStatus.success : LdapTestStatus.error;
    } catch (e) {
      _result = LdapTestResult(
        overallSuccess: false,
        steps: [],
        firstError: e.toString(),
      );
      _status = LdapTestStatus.error;
    } finally {
      _isRunning = false;
      notifyListeners();
    }
  }

  void reset() {
    _status = LdapTestStatus.idle;
    _result = null;
    _isRunning = false;
    notifyListeners();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/ldap/providers/ldap_test_provider.dart
git commit -m "feat: add LdapTestProvider state machine"
```

---

### Task 5: Create LDAP Widgets

**Files:**
- Create: `lib/features/ldap/widgets/ldap_config_form.dart`
- Create: `lib/features/ldap/widgets/ldap_test_feedback.dart`
- Create: `lib/features/ldap/widgets/ldap_status_indicator.dart`

- [ ] **Step 1: Create ldap_config_form.dart**

```dart
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

  Future<void> _handleTest() async {
    if (!_formKey.currentState!.validate()) return;
    final config = LdapConfig(
      host: _hostController.text.trim(),
      port: _portController.text.trim(),
      bindDn: _bindDnController.text.trim(),
      baseDn: _baseDnController.text.trim(),
      usernameAttr: _usernameAttrController.text.trim(),
      password: _passwordController.text,
    );
    await context.read<LdapConfigProvider>().saveConfig(config);
    await context.read<LdapTestProvider>().runTest();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final config = LdapConfig(
      host: _hostController.text.trim(),
      port: _portController.text.trim(),
      bindDn: _bindDnController.text.trim(),
      baseDn: _baseDnController.text.trim(),
      usernameAttr: _usernameAttrController.text.trim(),
      password: _passwordController.text,
    );
    await context.read<LdapConfigProvider>().saveConfig(context.read<LdapConfigProvider>().config);
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900]! : Colors.grey[50]!;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildField('LDAP Host'.i18n, 'ldap.myserver.com', _hostController, false),
          const SizedBox(height: 12),
          _buildField('LDAP Port'.i18n, '389', _portController, false),
          const SizedBox(height: 12),
          _buildField('Bind DN'.i18n, 'cn=admin,dc=example,dc=com', _bindDnController, false),
          const SizedBox(height: 12),
          _buildField('Base DN'.i18n, 'dc=example,dc=com', _baseDnController, false),
          const SizedBox(height: 12),
          _buildField('Username Attribute'.i18n, 'uid', _usernameAttrController, false),
          const SizedBox(height: 12),
          _buildField('Bind Password'.i18n, null, _passwordController, true),
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

  Widget _buildField(String label, String? hint, TextEditingController controller, bool isPassword) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? '${label.i18n} is required' : null,
    );
  }
}
```

- [ ] **Step 2: Create ldap_test_feedback.dart**

```dart
import 'package:flutter/material.dart';
import 'package:thisjowi/features/ldap/services/ldap_connection_service.dart';

class LdapTestFeedback extends StatelessWidget {
  final LdapTestResult result;

  const LdapTestFeedback({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.overallSuccess
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.overallSuccess ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.firstError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.firstError!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ...result.steps.map((step) => _buildStepRow(step)),
          if (result.overallSuccess)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Conexión LDAP exitosa',
                    style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepRow(LdapTestStepResult step) {
    final label = switch (step.step) {
      LdapTestStep.tcpConnection => 'Conexión TCP',
      LdapTestStep.bind => 'Autenticación (Bind)',
      LdapTestStep.searchBaseDn => 'Búsqueda Base DN',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            step.success ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: step.success ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text('$label: ${step.message}', style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create ldap_status_indicator.dart**

```dart
import 'package:flutter/material.dart';

class LdapStatusIndicator extends StatelessWidget {
  final bool isConnected;

  const LdapStatusIndicator({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? Colors.green : Colors.red,
            boxShadow: [
              BoxShadow(
                color: (isConnected ? Colors.green : Colors.red).withOpacity(0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isConnected ? 'LDAP Conectado' : 'LDAP Desconectado',
          style: TextStyle(
            fontSize: 13,
            color: isConnected ? Colors.green[700] : Colors.red[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/ldap/widgets/ldap_config_form.dart \
       lib/features/ldap/widgets/ldap_test_feedback.dart \
       lib/features/ldap/widgets/ldap_status_indicator.dart
git commit -m "feat: add LDAP widgets (config form, test feedback, status indicator)"
```

---

### Task 6: Create LdapConfigScreen (Settings)

**Files:**
- Create: `lib/features/ldap/screens/ldap_config_screen.dart`

- [ ] **Step 1: Write the file**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/features/deployment/providers/deployment_provider.dart';
import 'package:thisjowi/features/ldap/providers/ldap_config_provider.dart';
import 'package:thisjowi/features/ldap/providers/ldap_test_provider.dart';
import 'package:thisjowi/features/ldap/widgets/ldap_config_form.dart';
import 'package:thisjowi/features/ldap/widgets/ldap_status_indicator.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/core/api.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
      final token = await AuthService().getCurrentToken();
      final orgId = ''; // TODO: obtener orgId del perfil
      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/v1/admin/organizations/$orgId/ldap'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      await context.read<DeploymentProvider>().clearLdap();
      await context.read<LdapConfigProvider>().clearConfig();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al desconectar LDAP: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isDisconnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('LDAP Configuration'.i18n)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer2<DeploymentProvider, LdapConfigProvider>(
              builder: (context, dep, ldap, _) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: LdapStatusIndicator(isConnected: dep.isLdapConfigured),
                );
              },
            ),
            const LdapConfigForm(),
            const SizedBox(height: 24),
            Consumer<DeploymentProvider>(
              builder: (context, dep, _) {
                if (!dep.isLdapAdmin) return const SizedBox.shrink();
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/ldap/screens/ldap_config_screen.dart
git commit -m "feat: add LdapConfigScreen for settings"
```

---

### Task 7: Move existing LDAP components

**Files:**
- Move: `lib/components/ldap_selector.dart` → `lib/features/ldap/widgets/ldap_selector.dart`
- Move: `lib/components/ldap_user_card.dart` → `lib/features/ldap/widgets/ldap_user_card.dart`

- [ ] **Step 1: Copy files to new location**

```bash
cp lib/components/ldap_selector.dart lib/features/ldap/widgets/ldap_selector.dart
cp lib/components/ldap_user_card.dart lib/features/ldap/widgets/ldap_user_card.dart
```

- [ ] **Step 2: Update imports in the moved files**

In `lib/features/ldap/widgets/ldap_selector.dart`: no import changes needed (only imports `translations.dart`).
In `lib/features/ldap/widgets/ldap_user_card.dart`: no import changes needed (only imports `translations.dart`).

- [ ] **Step 3: Keep the old files temporarily to avoid breaking existing imports. They will be cleaned up in the final task.**

- [ ] **Step 4: Commit**

```bash
git add lib/features/ldap/widgets/ldap_selector.dart \
       lib/features/ldap/widgets/ldap_user_card.dart
git commit -m "feat: copy LDAP components to features/ldap/widgets/"
```

---

### Task 8: Simplify deployment_setup.dart (remove LDAP)

**Files:**
- Modify: `lib/screens/auth/deployment_setup.dart`

- [ ] **Step 1: Read the current file to understand the exact code to remove**

The file currently has ~984 lines. We need to:
1. Remove all `_ldap*` controllers, variables, and their dispose calls (lines 30-36, 52-53, 61-66)
2. Remove `_ldapEnabled` and LDAP-related state
3. Remove `_onLdapQuestion()` method
4. Remove `_onLdapConfigSave()` method
5. Remove LDAP config saving from `_saveAndFinish()`
6. Remove `_ldapChoiceCard()` widget and all LDAP step UI
7. Change step count from 3-4 to just 2 (mode + server)
8. After server config, just save and finish (no LDAP question step)

- [ ] **Step 2: Rewrite deployment_setup.dart (simplified)**

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thisjowi/components/deployment_mode_selector.dart';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/i18n/translations.dart';

class DeploymentSetupScreen extends StatefulWidget {
  final String? intent;

  const DeploymentSetupScreen({super.key, this.intent});

  @override
  State<DeploymentSetupScreen> createState() => _DeploymentSetupScreenState();
}

class _DeploymentSetupScreenState extends State<DeploymentSetupScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  String? _deploymentMode;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  bool _useSsl = true;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
    _portController.text = '443';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _animateForward() {
    _fadeController.reset();
    _fadeController.forward();
  }

  Future<void> _onDeploymentModeSelected(String mode) async {
    setState(() => _deploymentMode = mode);
    if (mode == 'Cloud') {
      await _saveAndFinish();
    } else {
      setState(() {
        _currentStep = 1;
        _portController.text = _useSsl ? '443' : '80';
      });
      _animateForward();
    }
  }

  void _onSslChanged(bool value) {
    setState(() {
      _useSsl = value;
      _portController.text = value ? '443' : '80';
    });
  }

  Future<void> _onServerConfigContinue() async {
    if (_hostController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please enter the server host".i18n),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    await _saveAndFinish();
  }

  Future<void> _saveAndFinish() async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deployment_mode', _deploymentMode!);

      if (_deploymentMode == 'SelfHosted') {
        final host = _hostController.text.trim();
        final port = _portController.text.trim();
        await prefs.setString('self_hosted_host', host);
        await prefs.setString('self_hosted_port', port);
        await prefs.setBool('self_hosted_use_ssl', _useSsl);

        final protocol = _useSsl ? 'https' : 'http';
        final url = port.isNotEmpty ? '$protocol://$host:$port' : '$protocol://$host';
        await ApiConfig.saveManualBaseUrl(url);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    if (!mounted) return;

    if (widget.intent == 'settings') {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0: return "Deployment Mode".i18n;
      case 1: return "Server Configuration".i18n;
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            if (_deploymentMode == 'SelfHosted')
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(
                      _stepTitle(_currentStep),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_currentStep + 1}/2',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            // Step content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return DeploymentModeSelector(
          key: ValueKey('mode_$_deploymentMode'),
          selectedMode: _deploymentMode,
          onModeSelected: _onDeploymentModeSelected,
        );
      case 1:
        return _buildServerConfig();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildServerConfig() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Server Configuration".i18n,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your server details".i18n,
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _hostController,
            decoration: InputDecoration(
              labelText: "Server Host".i18n,
              hintText: "api.myserver.com",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _portController,
            decoration: InputDecoration(
              labelText: "Port".i18n,
              hintText: "443",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            keyboardType: TextInputType.number,
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text("Use SSL".i18n, style: TextStyle(color: textColor)),
            subtitle: Text(
              _useSsl ? "https://" : "http://",
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
            ),
            value: _useSsl,
            onChanged: _onSslChanged,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSaving ? null : _onServerConfigContinue,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text("Continue".i18n, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/auth/deployment_setup.dart
git commit -m "refactor: simplify deployment_setup, remove LDAP from wizard"
```

---

### Task 9: Update register flow to include LDAP step

**Files:**
- Modify: `lib/screens/auth/register_flow.dart`
- Modify: `lib/screens/auth/register.dart`
- Modify: `lib/screens/auth/registerForm.dart`

- [ ] **Step 1: Update register_flow.dart to add LDAP step after registration**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/features/deployment/providers/deployment_provider.dart';
import 'package:thisjowi/features/ldap/providers/ldap_config_provider.dart';
import 'package:thisjowi/features/ldap/providers/ldap_test_provider.dart';
import 'package:thisjowi/features/ldap/widgets/ldap_config_form.dart';
import 'package:thisjowi/features/ldap/widgets/ldap_selector.dart';
import 'package:thisjowi/screens/auth/registerForm.dart';

class RegisterFlowScreen extends StatefulWidget {
  final bool isEmbedded;
  final Function(Map<String, dynamic>)? onSuccess;

  const RegisterFlowScreen({
    super.key,
    this.isEmbedded = false,
    this.onSuccess,
  });

  @override
  State<RegisterFlowScreen> createState() => _RegisterFlowScreenState();
}

class _RegisterFlowScreenState extends State<RegisterFlowScreen> {
  final String _accountType = 'Community';
  bool _showLdapStep = false;
  bool _ldapStepDone = false;

  void _goBack() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _handleSuccess(Map<String, dynamic> result) {
    final dep = context.read<DeploymentProvider>();
    if (dep.isSelfHosted && !_ldapStepDone) {
      setState(() => _showLdapStep = true);
    } else {
      if (widget.onSuccess != null) {
        widget.onSuccess!(result);
      }
    }
  }

  void _handleLdapChoice(bool enableLdap) async {
    if (enableLdap) {
      setState(() => _showLdapStep = true);
    } else {
      _ldapStepDone = true;
      if (widget.onSuccess != null) {
        widget.onSuccess!({});
      }
    }
  }

  void _handleLdapSaved() {
    _ldapStepDone = true;
    context.read<DeploymentProvider>().setLdapConfigured(true);
    context.read<DeploymentProvider>().setLdapAdmin(true);
    if (widget.onSuccess != null) {
      widget.onSuccess!({});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_showLdapStep) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('LDAP Configuration')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LdapSelector(onLdapSelected: _handleLdapChoice),
              if (_showLdapStep) ...[
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const LdapConfigForm(onSaved: _handleLdapSaved),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RegisterForm(
          accountType: _accountType,
          onSuccess: _handleSuccess,
          onBack: _goBack,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update register.dart to remove LDAP config reading (it will be handled by the flow)**

Keep register.dart but simplify it since LDAP URL will come from providers now, not prefs:

Edit `lib/screens/auth/register.dart`:

Replace the `_getLdapUrl()` method and its usage:

Remove the method and inline ldapUrl logic. The register.dart currently reads ldap_configured from prefs. Instead, it should get it from the DeploymentProvider.

Actually, let me look at register.dart more carefully to understand the full flow.

The register.dart is the screen shown when /register is navigated to. It:
1. Has _getLdapUrl() that reads from prefs
2. Passes ldapUrl to EmailVerification screen
3. The EmailVerification sends it in the API call

For the new flow, the LDAP config is saved by the user in the LDAP step of the registration flow. After saving, the `DeploymentProvider.isLdapConfigured` is true and `LdapConfigProvider` has the config. So register.dart can read from the provider instead.

Let me keep it simple - register.dart just needs to get ldapUrl from LdapConfigProvider instead of prefs.

```dart
// In register.dart, replace _getLdapUrl:
String? _getLdapUrl() {
  final config = context.read<LdapConfigProvider>().config;
  return config.ldapUrl.isNotEmpty ? config.ldapUrl : null;
}
```

And add the import for LdapConfigProvider.

- [ ] **Step 3: registerForm.dart - simplify LDAP reading**

In registerForm.dart, the ldap fetching logic (lines 160-164) should use provider instead of prefs:

```dart
final ldapConfigured = context.read<DeploymentProvider>().isLdapConfigured;
final config = context.read<LdapConfigProvider>().config;
final ldapUrl = ldapConfigured && config.host.isNotEmpty ? config.ldapUrl : null;
```

- [ ] **Step 4: Commit**

```bash
git add lib/screens/auth/register_flow.dart \
       lib/screens/auth/register.dart \
       lib/screens/auth/registerForm.dart
git commit -m "feat: add LDAP step to registration flow for SelfHosted"
```

---

### Task 10: Update login.dart to use Provider

**Files:**
- Modify: `lib/screens/auth/login.dart`

- [ ] **Step 1: Replace LDAP checks with Provider**

Replace lines 311-319:
```dart
      final prefs = await SharedPreferences.getInstance();
      final ldapConfigured = prefs.getBool('ldap_configured') ?? false;

      if (ldapConfigured) {
        await _authService.loginWithLdap(email, password);
      } else {
        await _authService.login(email, password);
      }
```

With:
```dart
      if (context.read<DeploymentProvider>().isLdapConfigured) {
        await _authService.loginWithLdap(email, password);
      } else {
        await _authService.login(email, password);
      }
```

Also replace the `_loadDeploymentConfig()` method to use DeploymentProvider instead of reading prefs directly, or simply call `provider.loadFromPrefs()`.

Replace:
```dart
  Future<void> _loadDeploymentConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('deployment_mode');
    if (mounted) {
      setState(() {
        _deploymentMode = mode;
      });
    }
  }
```

With:
```dart
  Future<void> _loadDeploymentConfig() async {
    final dep = context.read<DeploymentProvider>();
    await dep.loadFromPrefs();
    if (mounted) {
      setState(() {
        _deploymentMode = dep.deploymentMode;
      });
    }
  }
```

Replace the `_showRegisterLdapDomain()` method (lines ~159-219) - this method saves LDAP config and creates organization. It should now delegate to LdapConfigProvider and DeploymentProvider instead of writing prefs directly.

Replace the method body with calls to LdapConfigProvider:
```dart
  Future<void> _showRegisterLdapDomain() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const _LdapDomainDialog(),
    );
    if (result == null || !mounted) return;

    final config = LdapConfig(
      host: result['host']!,
      port: result['port']!,
      bindDn: result['bindDn']!,
      baseDn: result['baseDn']!,
      usernameAttr: result['usernameAttr']!,
      password: result['password']!,
    );
    await context.read<LdapConfigProvider>().saveConfig(config);
    await context.read<DeploymentProvider>().setLdapConfigured(true);
    await context.read<DeploymentProvider>().setLdapAdmin(true);
    await _authService.register(
      email: _emailController.text,
      password: _passwordController.text,
      ldapUrl: config.ldapUrl,
    );
    // Create org
    await OrgService.createOrgIfNeeded(_emailController.text);
  }
```

Also remove the unused LDAP-related imports if no longer needed.

- [ ] **Step 2: Commit**

```bash
git add lib/screens/auth/login.dart
git commit -m "refactor: use DeploymentProvider for LDAP checks in login"
```

---

### Task 11: Update SettingScreen for LDAP admin entry

**Files:**
- Modify: `lib/screens/settings/SettingScreen.dart`

- [ ] **Step 1: Add LDAP Configuration entry for admin**

Find the "Disconnect Domain" section (around line 1469-1488) and add an "LDAP Configuration" entry before it that navigates to LdapConfigScreen:

```dart
// LDAP Configuration (admin only)
if (_deploymentMode == 'SelfHosted' && _isOrgAdmin) ...[
  ListTile(
    leading: const Icon(Icons.admin_panel_settings_outlined),
    title: Text('LDAP Configuration'.i18n),
    subtitle: Consumer<DeploymentProvider>(
      builder: (context, dep, _) => LdapStatusIndicator(isConnected: dep.isLdapConfigured),
    ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LdapConfigScreen()),
      );
    },
  ),
  const Divider(),
],
```

Add imports:
```dart
import 'package:thisjowi/features/ldap/screens/ldap_config_screen.dart';
import 'package:thisjowi/features/ldap/widgets/ldap_status_indicator.dart';
```

Remove the old `_handleDisconnectDomain()` if it's being replaced by the LdapConfigScreen version.

- [ ] **Step 2: Commit**

```bash
git add lib/screens/settings/SettingScreen.dart
git commit -m "feat: add LDAP Configuration entry to settings for admin"
```

---

### Task 12: Update org_service.dart

**Files:**
- Modify: `lib/services/org_service.dart`

- [ ] **Step 1: Update createOrgIfNeeded to use providers**

Replace direct SharedPreferences reads with providers:

```dart
import 'package:thisjowi/features/deployment/providers/deployment_provider.dart';
import 'package:thisjowi/features/ldap/providers/ldap_config_provider.dart';

class OrgService {
  static Future<void> createOrgIfNeeded(
    String email, {
    DeploymentProvider? depProvider,
    LdapConfigProvider? ldapProvider,
  }) async {
    if (depProvider == null || !depProvider.isSelfHosted || !depProvider.isLdapConfigured) return;

    final config = ldapProvider?.config ?? LdapConfig();
    if (config.host.isEmpty) return;
    // ... rest of the method using config instead of prefs
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/org_service.dart
git commit -m "refactor: org_service uses providers instead of raw prefs"
```

---

### Task 13: Update main.dart to register providers

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add imports and register providers**

Add imports:
```dart
import 'package:thisjowi/features/deployment/providers/deployment_provider.dart';
import 'package:thisjowi/features/ldap/providers/ldap_config_provider.dart';
import 'package:thisjowi/features/ldap/providers/ldap_test_provider.dart';
```

Add providers to MultiProvider:
```dart
  ChangeNotifierProvider(create: (_) => DeploymentProvider()..loadFromPrefs()),
  ChangeNotifierProvider(create: (_) {
    final ldapConfig = LdapConfigProvider()..loadFromPrefs();
    return ldapConfig;
  }),
  ChangeNotifierProxyProvider<LdapConfigProvider, LdapTestProvider>(
    create: (ctx) => LdapTestProvider(ctx.read<LdapConfigProvider>()),
    update: (ctx, ldapConfig, prev) => prev ?? LdapTestProvider(ldapConfig),
  ),
```

- [ ] **Step 2: Commit**

```bash
git add lib/main.dart
git commit -m "feat: register DeploymentProvider, LdapConfigProvider, LdapTestProvider"
```

---

### Task 14: Cleanup

**Files:**
- Update imports across the app that still point to old `lib/components/ldap_*` files
- Move remaining references from old files to new feature folder

- [ ] **Step 1: Find all remaining references to old paths**

```bash
rg "package:thisjowi/components/ldap_" --include "*.dart" -l
```

- [ ] **Step 2: Update each reference to use `package:thisjowi/features/ldap/widgets/`**

For each file found, update the import path.

Also check: are `ldap_selector.dart` and `ldap_user_card.dart` still used anywhere at the new path? If so, they need their own import updates in `components/ldap_selector.dart` → `features/ldap/widgets/ldap_selector.dart`.

- [ ] **Step 3: Remove old files after all references are updated**

```bash
git rm lib/components/ldap_selector.dart
git rm lib/components/ldap_user_card.dart
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: cleanup old LDAP component files and update imports"
```

---

## Spec Coverage Check

- **Cloud never sees LDAP**: handled by `DeploymentProvider.isSelfHosted` gating all LDAP UI
- **LDAP asked in registration**: handled by `RegisterFlowScreen` showing LDAP selector after form submit
- **Admin-only reconfiguration**: handled by `isLdapAdmin` gating in `SettingScreen` and `LdapConfigScreen`
- **Granular connection test**: handled by `LdapConnectionService` with 3-step feedback
- **Feature folder isolation**: all new code under `lib/features/ldap/` and `lib/features/deployment/`
- **Simplified deployment wizard**: `deployment_setup.dart` reduced from 984 lines to ~200 lines
