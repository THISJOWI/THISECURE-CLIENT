# Environment Profiles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to create, switch, and manage multiple environment profiles (Cloud + Self-Hosted) from settings.

**Architecture:** A singleton `EnvironmentProfileManager` stores profiles in SharedPreferences with isolated storage keys per profile. Settings screen gains an "Environments" item that opens a profile list screen. Switching profiles clears session and redirects to login.

**Tech Stack:** Flutter/Dart, SharedPreferences, flutter_secure_storage, Provider

## Global Constraints

- All new storage keys must be prefixed with `profile_{id}_` to isolate per-profile data
- The "Cloud" profile (id: `cloud`) must always exist and cannot be deleted
- Switching profiles must clear current session and navigate to login
- Test connection: GET `{serverUrl}/health` must return 200
- Follow existing code patterns (Provider for state, services for business logic)

---

### Task 1: EnvironmentProfile Model

**Files:**
- Create: `lib/core/environment_profile.dart`

**Interfaces:**
- Produces: `EnvironmentProfile` class, `EnvironmentType` enum

- [ ] **Step 1: Create the model file**

```dart
enum EnvironmentType { cloud, selfHosted }

class EnvironmentProfile {
  final String id;
  final String name;
  final EnvironmentType type;
  final String? serverUrl;
  final DateTime createdAt;
  DateTime lastUsedAt;

  EnvironmentProfile({
    required this.id,
    required this.name,
    required this.type,
    this.serverUrl,
    required this.createdAt,
    DateTime? lastUsedAt,
  }) : lastUsedAt = lastUsedAt ?? createdAt;

  bool get isCloud => type == EnvironmentType.cloud;
  bool get isSelfHosted => type == EnvironmentType.selfHosted;

  factory EnvironmentProfile.cloud()
    => EnvironmentProfile(
      id: 'cloud',
      name: 'Cloud',
      type: EnvironmentType.cloud,
      createdAt: DateTime.now(),
    );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'serverUrl': serverUrl,
    'createdAt': createdAt.toIso8601String(),
    'lastUsedAt': lastUsedAt.toIso8601String(),
  };

  factory EnvironmentProfile.fromJson(Map<String, dynamic> json) => EnvironmentProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    type: EnvironmentType.values.byName(json['type'] as String),
    serverUrl: json['serverUrl'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastUsedAt: DateTime.tryParse(json['lastUsedAt'] as String? ?? ''),
  );

  EnvironmentProfile copyWith({
    String? name,
    EnvironmentType? type,
    String? serverUrl,
    DateTime? lastUsedAt,
  }) => EnvironmentProfile(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    serverUrl: serverUrl ?? this.serverUrl,
    createdAt: createdAt,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
}
```

---

### Task 2: EnvironmentProfileManager

**Files:**
- Create: `lib/core/environment_profile_manager.dart`

**Interfaces:**
- Produces: `EnvironmentProfileManager` singleton with methods for CRUD + switching

- [ ] **Step 1: Create the manager**

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thisjowi/core/environment_profile.dart';
import 'package:thisjowi/services/token_manager.dart';

class EnvironmentProfileManager extends ChangeNotifier {
  static const _profilesKey = 'environment_profiles';
  static const _activeIdKey = 'active_profile_id';

  static final EnvironmentProfileManager _instance = EnvironmentProfileManager._();
  factory EnvironmentProfileManager() => _instance;
  EnvironmentProfileManager._();

  List<EnvironmentProfile> _profiles = [];
  String? _activeProfileId;

  List<EnvironmentProfile> get profiles => List.unmodifiable(_profiles);
  EnvironmentProfile? get activeProfile =>
    _profiles.cast<EnvironmentProfile?>().firstWhere(
      (p) => p?.id == _activeProfileId,
      orElse: () => null,
    );
  bool get isCloud => activeProfile?.isCloud ?? true;
  bool get isSelfHosted => activeProfile?.isSelfHosted ?? false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _activeProfileId = prefs.getString(_activeIdKey);

    final raw = prefs.getString(_profilesKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _profiles = list.map((e) => EnvironmentProfile.fromJson(e as Map<String, dynamic>)).toList();
    }

    // Ensure cloud profile always exists
    if (!_profiles.any((p) => p.id == 'cloud')) {
      _profiles.insert(0, EnvironmentProfile.cloud());
    }

    // Default to cloud if no active profile set
    if (_activeProfileId == null || !_profiles.any((p) => p.id == _activeProfileId)) {
      _activeProfileId = 'cloud';
      await prefs.setString(_activeIdKey, _activeProfileId!);
    }

    notifyListeners();
  }

  Future<void> _persistProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_profiles.map((p) => p.toJson()).toList());
    await prefs.setString(_profilesKey, raw);
  }

  Future<void> addProfile(EnvironmentProfile profile) async {
    _profiles.add(profile);
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> updateProfile(EnvironmentProfile profile) async {
    final index = _profiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      _profiles[index] = profile;
      await _persistProfiles();
      notifyListeners();
    }
  }

  Future<void> deleteProfile(String id) async {
    if (id == 'cloud') return; // Cannot delete cloud
    _profiles.removeWhere((p) => p.id == id);
    if (_activeProfileId == id) {
      _activeProfileId = 'cloud';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeIdKey, _activeProfileId!);
    }
    await _persistProfiles();
    notifyListeners();
  }

  Future<void> switchTo(String profileId) async {
    final profile = _profiles.firstWhere((p) => p.id == profileId);
    profile.lastUsedAt = DateTime.now();

    _activeProfileId = profileId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeIdKey, profileId);
    await _persistProfiles();

    // Apply API URL
    if (profile.isCloud) {
      await ApiConfig.clearManualBaseUrl();
    } else if (profile.serverUrl != null) {
      await ApiConfig.saveManualBaseUrl(profile.serverUrl!);
    }

    notifyListeners();
  }

  /// Storage key prefix for the active profile
  String get activeStoragePrefix => 'profile_${_activeProfileId ?? 'cloud'}_';
}
```

Add import for ApiConfig at top:
```dart
import 'package:thisjowi/core/api.dart';
```

---

### Task 3: Environment List Screen

**Files:**
- Create: `lib/screens/environments/environment_list_screen.dart`

**Interfaces:**
- Consumes: `EnvironmentProfileManager`, `EnvironmentProfile`
- Routes to: `EnvironmentAddScreen`

- [ ] **Step 1: Create the environment list screen**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/core/environment_profile.dart';
import 'package:thisjowi/core/environment_profile_manager.dart';
import 'package:thisjowi/components/liquid_glass.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/screens/environments/environment_add_screen.dart';

class EnvironmentListScreen extends StatelessWidget {
  const EnvironmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Environments'.i18n, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<EnvironmentProfileManager>(
        builder: (context, mgr, _) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: mgr.profiles.length,
                  itemBuilder: (context, index) {
                    final profile = mgr.profiles[index];
                    final isActive = profile.id == mgr.activeProfile?.id;
                    return _ProfileTile(
                      profile: profile,
                      isActive: isActive,
                      onSwitch: isActive ? null : () => _confirmSwitch(context, mgr, profile),
                      onDelete: profile.id == 'cloud' ? null : () => _confirmDelete(context, mgr, profile),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: LiquidGlass.wrap(
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EnvironmentAddScreen()),
                      ),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: Text('Add Environment'.i18n, style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmSwitch(BuildContext context, EnvironmentProfileManager mgr, EnvironmentProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: SizedBox(
          width: 400,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: LiquidGlass.wrap(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Switch Environment'.i18n, style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(height: 12),
                  Text(
                    'Switching to "${profile.name}". Your current session will end and you will be redirected to login.'.i18n,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel'.i18n),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          mgr.switchTo(profile.id);
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        },
                        child: Text('Switch & Logout'.i18n),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, EnvironmentProfileManager mgr, EnvironmentProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: SizedBox(
          width: 400,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: LiquidGlass.wrap(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Delete Environment'.i18n, style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to delete "${profile.name}"? This action cannot be undone.'.i18n,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel'.i18n),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                        onPressed: () {
                          Navigator.pop(ctx);
                          mgr.deleteProfile(profile.id);
                        },
                        child: Text('Delete'.i18n),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final EnvironmentProfile profile;
  final bool isActive;
  final VoidCallback? onSwitch;
  final VoidCallback? onDelete;

  const _ProfileTile({
    required this.profile,
    required this.isActive,
    this.onSwitch,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          profile.isCloud ? Icons.cloud : Icons.dns,
          color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        title: Text(
          profile.name,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          profile.isCloud ? 'Cloud hosted by thisuite'.i18n
            : profile.serverUrl ?? 'Not configured'.i18n,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active'.i18n,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (onSwitch != null)
              TextButton(
                onPressed: onSwitch,
                child: Text('Switch'.i18n),
              ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
```

---

### Task 4: Environment Add Screen

**Files:**
- Create: `lib/screens/environments/environment_add_screen.dart`

**Interfaces:**
- Consumes: `EnvironmentProfileManager`
- Routes: pops back to `EnvironmentListScreen` on success

- [ ] **Step 1: Create the add environment screen**

```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:thisjowi/core/environment_profile.dart';
import 'package:thisjowi/core/environment_profile_manager.dart';
import 'package:thisjowi/components/liquid_glass.dart';
import 'package:thisjowi/i18n/translations.dart';

class EnvironmentAddScreen extends StatefulWidget {
  const EnvironmentAddScreen({super.key});

  @override
  State<EnvironmentAddScreen> createState() => _EnvironmentAddScreenState();
}

class _EnvironmentAddScreenState extends State<EnvironmentAddScreen> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    var url = _urlController.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    setState(() { _isTesting = true; _testResult = null; });

    try {
      final response = await http.get(Uri.parse('$url/health')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        setState(() { _testResult = 'Connection successful'.i18n; _testSuccess = true; });
      } else {
        setState(() { _testResult = 'Server responded with status ${response.statusCode}'.i18n; _testSuccess = false; });
      }
    } catch (e) {
      setState(() { _testResult = 'Connection failed: $e'.i18n; _testSuccess = false; });
    } finally {
      setState(() { _isTesting = false; });
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    var url = _urlController.text.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final profile = EnvironmentProfile(
      id: 'self_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      type: EnvironmentType.selfHosted,
      serverUrl: url,
      createdAt: DateTime.now(),
    );

    await EnvironmentProfileManager().addProfile(profile);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Add Environment'.i18n, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Environment Name'.i18n, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. My Server'.i18n,
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 20),
            Text('Server URL'.i18n, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://192.168.1.100'.i18n,
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.wifi_tethering),
              label: Text('Test Connection'.i18n),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(_testSuccess ? Icons.check_circle : Icons.error,
                    color: _testSuccess ? Colors.green : Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_testResult!, style: TextStyle(
                      color: _testSuccess ? Colors.green : Colors.red,
                    )),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            LiquidGlass.wrap(
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _save,
                  child: Text('Save Environment'.i18n, style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Task 5: Update Settings Screen

**Files:**
- Modify: `lib/screens/settings/SettingScreen.dart`

- [ ] **Step 1: Add import for EnvironmentProfileManager**

After the existing imports, add:
```dart
import 'package:thisjowi/core/environment_profile_manager.dart';
import 'package:thisjowi/screens/environments/environment_list_screen.dart';
```

- [ ] **Step 2: Add Environments item in the settings list**

Insert a new section heading and item before "Change Password" (after Country). Replace the existing section structure:

Find the country item (around line 1292) and add after it:
```dart
// Environments
const SizedBox(height: 8),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  child: Text(
    'ENVIRONMENTS'.i18n,
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    ),
  ),
),
_buildSettingItem(
  icon: Icons.dns_outlined,
  title: 'Servers'.i18n,
  subtitle: '${EnvironmentProfileManager().activeProfile?.name ?? 'Cloud'} • ${EnvironmentProfileManager().isCloud ? 'Cloud' : 'Self-Hosted'}',
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EnvironmentListScreen()),
    );
  },
),
```

---

### Task 6: Update main.dart Initialization

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add import for EnvironmentProfileManager**

```dart
import 'package:thisjowi/core/environment_profile_manager.dart';
```

- [ ] **Step 2: Initialize EnvironmentProfileManager after ApiConfig**

Find the block:
```dart
await EnvLoader.load();
await ApiConfig.init();
```

Replace with:
```dart
await EnvLoader.load();
await ApiConfig.init();
await EnvironmentProfileManager().load();
```

- [ ] **Step 3: Add EnvironmentProfileManager as a Provider**

Find the `MultiProvider` section and add:
```dart
ChangeNotifierProvider(create: (_) => EnvironmentProfileManager()),
```

---

### Task 7: Update TokenManager for Profile-Isolated Keys

**Files:**
- Modify: `lib/services/token_manager.dart`

- [ ] **Step 1: Add method to get profile-prefixed keys**

Add import:
```dart
import 'package:thisjowi/core/environment_profile_manager.dart';
```

Add a helper method:
```dart
String _profileKey(String key) {
  final prefix = EnvironmentProfileManager().activeStoragePrefix;
  return '$prefix$key';
}
```

- [ ] **Step 2: Update all key references to use _profileKey**

Update `_tokenKey`, `_tokenExpiryKey`, `_refreshTokenKey`, `_lastValidatedKey`, `_userIdKey` usage. Instead of static consts, use the helper:

Replace in `setToken`:
```dart
await _secureStorage.write(key: _profileKey(_tokenKey), value: token);
```

And in all other methods. Apply the pattern consistently.

- [ ] **Step 3: Update clearToken to clear all profile tokens**

Replace `clearToken()` with a version that accepts optional profileId:
```dart
Future<void> clearToken({String? profileId}) async {
  _cachedToken = null;
  _cachedExpiry = null;
  _cachedUserId = null;

  final keys = profileId != null
    ? ['profile_${profileId}_$_tokenKey', 'profile_${profileId}_$_tokenExpiryKey', ...]
    : [_tokenKey, _tokenExpiryKey, _refreshTokenKey, _lastValidatedKey, _userIdKey];

  for (final key in keys) {
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {
      await _prefs?.remove(key);
    }
  }
}
```

---

### Task 8: Update DeploymentProvider as Wrapper

**Files:**
- Modify: `lib/features/deployment/providers/deployment_provider.dart`

- [ ] **Step 1: Refactor to delegate to EnvironmentProfileManager**

```dart
import 'package:flutter/foundation.dart';
import 'package:thisjowi/core/environment_profile_manager.dart';

class DeploymentProvider extends ChangeNotifier {
  String get _deploymentMode => EnvironmentProfileManager().isCloud ? 'Cloud' : 'SelfHosted';
  bool get isSelfHosted => EnvironmentProfileManager().isSelfHosted;
  bool get isCloud => EnvironmentProfileManager().isCloud;
  String get deploymentMode => _deploymentMode;

  bool _ldapConfigured = false;
  bool _ldapAdmin = false;

  bool get isLdapConfigured => _ldapConfigured;
  bool get isLdapAdmin => _ldapAdmin;

  Future<void> loadFromPrefs() async {
    // LDAP flags remain in SharedPreferences (per-profile via prefix logic elsewhere)
    final prefs = await SharedPreferences.getInstance();
    _ldapConfigured = prefs.getBool('ldap_configured') ?? false;
    _ldapAdmin = prefs.getBool('ldap_admin') ?? false;
    notifyListeners();
  }

  Future<void> setDeploymentMode(String mode) async {
    // Deployment mode is now determined by EnvironmentProfileManager
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

---

### Task 9: Add Routes to main.dart

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add routes for environment screens**

Find the `routes:` block in `_AppCore.build` and add:
```dart
'/environments': (context) => const EnvironmentListScreen(),
'/environments/add': (context) => const EnvironmentAddScreen(),
```

Add imports:
```dart
import 'package:thisjowi/screens/environments/environment_list_screen.dart';
import 'package:thisjowi/screens/environments/environment_add_screen.dart';
```

---

### Task 10: Backend - LDAP Two-Step Authorization (core/auth)

**Files:**
- Modify: `~/Workspace/thisuite/core/services/auth/internal/handler/ldap_register.go`
- Modify: `~/Workspace/thisuite/core/services/auth/internal/handler/ldap_handler.go`
- Modify: `~/Workspace/thisuite/core/services/auth/internal/service/ldap_service.go`
- Modify: `~/Workspace/thisuite/core/services/auth/internal/model/organization.go`
- Modify: `~/Workspace/thisuite/core/services/auth/internal/repository/org_repo.go`
- Modify: `~/Workspace/thisuite/core/services/auth/migrations/`

- [ ] **Step 1: Add migration for LDAP auth code fields**

Create `services/auth/migrations/004_add_ldap_auth_code.up.sql`:
```sql
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS ldap_auth_code TEXT;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS ldap_auth_code_expires_at TIMESTAMPTZ;
```

- [ ] **Step 2: Update Organization model**

Add fields:
```go
LdapAuthCode          string     `db:"ldap_auth_code" json:"ldap_auth_code,omitempty"`
LdapAuthCodeExpiresAt *time.Time `db:"ldap_auth_code_expires_at" json:"ldap_auth_code_expires_at,omitempty"`
```

- [ ] **Step 3: Add InitiateLdapConfig method to repository**

```go
func (r *OrgRepository) SaveLdapAuthCode(ctx context.Context, orgID string, code string, expiresAt time.Time) error {
    _, err := r.db.Exec(ctx,
        `UPDATE organizations SET ldap_auth_code = $1, ldap_auth_code_expires_at = $2 WHERE id = $3`,
        code, expiresAt, orgID,
    )
    return err
}

func (r *OrgRepository) ClearLdapAuthCode(ctx context.Context, orgID string) error {
    _, err := r.db.Exec(ctx,
        `UPDATE organizations SET ldap_auth_code = NULL, ldap_auth_code_expires_at = NULL WHERE id = $1`,
        orgID,
    )
    return err
}
```

- [ ] **Step 4: Add InitiateLdapConfig service method**

```go
func (s *LdapService) InitiateLdapConfig(ctx context.Context, org *model.Organization, req *InitiateLdapRequest) (string, error) {
    // Check domain not already LDAP-configured
    existingOrg, err := s.orgRepo.FindByDomain(ctx, req.Domain)
    if err == nil && existingOrg.LdapEnabled {
        return "", ErrLdapAlreadyConfigured
    }

    // Save LDAP config (but don't enable yet)
    org.LdapUrl = req.LdapUrl
    org.LdapBaseDn = req.LdapBaseDn
    org.LdapBindDn = req.LdapBindDn
    // Encrypt bind password
    encrypted, err := s.crypto.Encrypt([]byte(req.LdapBindPassword))
    if err != nil {
        return "", err
    }
    org.LdapBindPassword = string(encrypted)
    org.LdapEnabled = false

    // Generate auth code (6-digit)
    code := fmt.Sprintf("%06d", rand.Intn(1000000))
    expiresAt := time.Now().Add(24 * time.Hour)

    if err := s.orgRepo.Update(ctx, org); err != nil {
        return "", err
    }
    if err := s.orgRepo.SaveLdapAuthCode(ctx, org.ID, code, expiresAt); err != nil {
        return "", err
    }

    return code, nil
}

func (s *LdapService) AuthorizeLdapConfig(ctx context.Context, domain string, authCode string) error {
    org, err := s.orgRepo.FindByDomain(ctx, domain)
    if err != nil {
        return ErrOrgNotFound
    }
    if org.LdapEnabled {
        return ErrLdapAlreadyConfigured
    }
    if org.LdapAuthCode == "" || org.LdapAuthCodeExpiresAt == nil || time.Now().After(*org.LdapAuthCodeExpiresAt) {
        return ErrLdapAuthCodeExpired
    }
    if org.LdapAuthCode != authCode {
        return ErrLdapAuthCodeInvalid
    }

    org.LdapEnabled = true
    if err := s.orgRepo.Update(ctx, org); err != nil {
        return err
    }
    return s.orgRepo.ClearLdapAuthCode(ctx, org.ID)
}
```

- [ ] **Step 5: Add handlers**

In `ldap_register.go`:
```go
func (h *LdapHandler) InitiateLdap(c *gin.Context) {
    var req struct {
        Domain            string `json:"domain" binding:"required"`
        LdapUrl           string `json:"ldapUrl" binding:"required"`
        LdapBaseDn        string `json:"ldapBaseDn" binding:"required"`
        LdapBindDn        string `json:"ldapBindDn" binding:"required"`
        LdapBindPassword  string `json:"ldapBindPassword" binding:"required"`
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    userID := middleware.GetUserID(c)
    org, err := h.orgRepo.FindByAdminID(c.Request.Context(), userID)
    if err != nil {
        c.JSON(404, gin.H{"error": "organization not found"})
        return
    }

    code, err := h.ldapService.InitiateLdapConfig(c.Request.Context(), org, &service.InitiateLdapRequest{
        Domain:           req.Domain,
        LdapUrl:          req.LdapUrl,
        LdapBaseDn:       req.LdapBaseDn,
        LdapBindDn:       req.LdapBindDn,
        LdapBindPassword: req.LdapBindPassword,
    })
    if err != nil {
        c.JSON(409, gin.H{"error": err.Error()})
        return
    }

    c.JSON(200, gin.H{"authCode": code})
}
```

In `ldap_handler.go`:
```go
func (h *LdapHandler) AuthorizeLdap(c *gin.Context) {
    var req struct {
        Domain   string `json:"domain" binding:"required"`
        AuthCode string `json:"authCode" binding:"required"`
    }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    if err := h.ldapService.AuthorizeLdapConfig(c.Request.Context(), req.Domain, req.AuthCode); err != nil {
        switch err {
        case service.ErrOrgNotFound:
            c.JSON(404, gin.H{"error": "organization not found"})
        case service.ErrLdapAlreadyConfigured:
            c.JSON(409, gin.H{"error": "LDAP already configured for this domain"})
        case service.ErrLdapAuthCodeExpired:
            c.JSON(410, gin.H{"error": "authorization code has expired"})
        case service.ErrLdapAuthCodeInvalid:
            c.JSON(401, gin.H{"error": "invalid authorization code"})
        default:
            c.JSON(500, gin.H{"error": "internal error"})
        }
        return
    }

    c.JSON(200, gin.H{"status": "authorized"})
}
```

Register routes in `main.go`:
```go
v1Auth.POST("/ldap/initiate", mid.JWTAuth(jwtSecret), mid.Admin(), ldapHandler.InitiateLdap)
v1Auth.POST("/ldap/authorize", ldapHandler.AuthorizeLdap)
```
