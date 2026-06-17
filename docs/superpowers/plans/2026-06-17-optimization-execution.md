# THISECURE Optimization — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Optimize THISECURE app for space, memory, CPU across all platforms (Android, iOS, macOS, Windows, Linux, Web).

**Architecture:** 4 sequential phases, tasks batched by safety/dependency. Phase 1 is purely eliminative (zero risk). Phase 2 refactors large files and unifies DI. Phase 3 optimizes runtime behavior. Phase 4 configures build tooling.

**Tech Stack:** Flutter 3.24+, Dart SDK 3.5+, Provider, Drift, Flutter Secure Storage

**Execution order (respect dependency chains):**
- Fase 1: 1.1 + 1.2 + 1.4 + 1.5 (parallel) → 1.3 (can run parallel to others) → 1.6 (depends on all above)
- Fase 2: 2.4 + 2.6 + 2.7 (parallel) → 2.5 → 2.1 → 2.2 + 2.3 (parallel)
- Fase 3: 3.6 + 3.2 + 3.4 (parallel) → 3.5 + 3.1 (parallel) → 3.7 → 3.3
- Fase 4: 4.1 + 4.2 + 4.3 (parallel) → 4.4

---

## Fase 1: Cirugía de Espacio

### Task 1.1 — Eliminar archivos duplicados Dart (31 pares)

**Files:**
- Delete: `lib/core/service_locator 2.dart`
- Delete: `lib/core/theme_provider 2.dart`
- Delete: `lib/core/http_client 2.dart`
- Delete: `lib/core/exceptions/profile_exceptions 2.dart`
- Delete: `lib/core/exceptions/account_exceptions 2.dart`
- Delete: `lib/core/exceptions/auth_exceptions 2.dart`
- Delete: `lib/core/providers/otp_provider 2.dart`
- Delete: `lib/services/account_service 2.dart`
- Delete: `lib/services/base_service 2.dart`
- Delete: `lib/services/token_manager 2.dart`
- Delete: `lib/services/api_client 2.dart`
- Delete: `lib/services/profile_service 2.dart`
- Delete: `lib/data/models/password_entry 2.dart`
- Delete: `lib/data/models/profile_user 2.dart`
- Delete: `lib/data/models/auth_user 2.dart`
- Delete: `lib/data/models/account_user 2.dart`
- Delete: `lib/data/models/otp_entry 2.dart`
- Delete: `lib/components/social_login_button 2.dart`
- Delete: `lib/components/error_bar 2.dart`
- Delete: `lib/components/country_map_picker 2.dart`
- Delete: `lib/components/biometric_settings 2.dart`
- Delete: `lib/components/sync_debug_panel 2.dart`
- Delete: `lib/utils/app_logger 2.dart`
- Delete: `lib/screens/debug/logs_screen 2.dart`

- [ ] **Step 1: Delete all duplicate files**

```bash
rm -f \
  lib/core/service_locator\ 2.dart \
  lib/core/theme_provider\ 2.dart \
  lib/core/http_client\ 2.dart \
  lib/core/exceptions/profile_exceptions\ 2.dart \
  lib/core/exceptions/account_exceptions\ 2.dart \
  lib/core/exceptions/auth_exceptions\ 2.dart \
  lib/core/providers/otp_provider\ 2.dart \
  lib/services/account_service\ 2.dart \
  lib/services/base_service\ 2.dart \
  lib/services/token_manager\ 2.dart \
  lib/services/api_client\ 2.dart \
  lib/services/profile_service\ 2.dart \
  lib/data/models/password_entry\ 2.dart \
  lib/data/models/profile_user\ 2.dart \
  lib/data/models/auth_user\ 2.dart \
  lib/data/models/account_user\ 2.dart \
  lib/data/models/otp_entry\ 2.dart \
  lib/components/social_login_button\ 2.dart \
  lib/components/error_bar\ 2.dart \
  lib/components/country_map_picker\ 2.dart \
  lib/components/biometric_settings\ 2.dart \
  lib/components/sync_debug_panel\ 2.dart \
  lib/utils/app_logger\ 2.dart \
  lib/screens/debug/logs_screen\ 2.dart
```

- [ ] **Step 2: Verify**

```bash
flutter analyze
```

Expected: No errors or new warnings. If imports from deleted files exist, fix those first.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "chore: remove 25 duplicate dart files (* 2.dart)"
```

---

### Task 1.2 — Eliminar dependencias no usadas

**Files:**
- Modify: `pubspec.yaml` (remove 3 lines)

- [ ] **Step 1: Edit pubspec.yaml to remove unused dependencies**

Remove these 3 lines from pubspec.yaml:

```yaml
  rename: ^3.1.0
  skeletonizer: ^2.1.1
  flutter_watch_os_connectivity: ^1.0.0
```

- [ ] **Step 2: Clean and reinstall**

```bash
flutter clean
rm -rf ~/.pub-cache/hosted/pub.dev/rename* ~/.pub-cache/hosted/pub.dev/skeletonizer* ~/.pub-cache/hosted/pub.dev/flutter_watch_os_connectivity*
flutter pub get
# wait for pub get to complete
```

- [ ] **Step 3: Verify**

```bash
flutter analyze
```

Expected: No errors. Remove warnings if any leftover imports exist.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock && git commit -m "chore: remove unused dependencies (rename, skeletonizer, flutter_watch_os_connectivity)"
```

---

### Task 1.3 — Comprimir assets de imagen

**Files:**
- Modify: `assets/logo.png` (overwrite with compressed version)
- Modify: `assets/empresa.png` (overwrite with compressed version)
- Modify: `assets/removed.png` (overwrite with compressed version)

- [ ] **Step 1: Check available tools**

```bash
which pngquant 2>/dev/null || which optipng 2>/dev/null || which pngcrush 2>/dev/null || echo "No PNG compression tools found"
```

If pngquant is available:
```bash
# Compress logo.png (404KB -> ~80KB)
pngquant --quality=65-80 --force --output assets/logo.png assets/logo.png
# Compress empresa.png (130KB -> ~40KB)
pngquant --quality=65-80 --force --output assets/empresa.png assets/empresa.png
# Compress removed.png (10KB -> ~3KB)
pngquant --quality=65-80 --force --output assets/removed.png assets/removed.png
```

If pngquant is NOT available:
```bash
# Use macOS built-in sips or install pngquant
brew install pngquant 2>/dev/null || brew install optipng 2>/dev/null
```

Then retry compression.

- [ ] **Step 2: Verify files are smaller**

```bash
ls -lh assets/logo.png assets/empresa.png assets/removed.png
```

Expected: logo.png < 100KB, empresa.png < 50KB, removed.png < 5KB

- [ ] **Step 3: Verify flutter still loads them**

```bash
flutter analyze
```

- [ ] **Step 4: Commit**

```bash
git add assets/logo.png assets/empresa.png assets/removed.png && git commit -m "perf: compress PNG assets (logo: 404KB->~80KB, empresa: 130KB->~40KB, removed: 10KB->~3KB)"
```

---

### Task 1.4 — Eliminar archivos temporales de la raíz

**Files:**
- Delete: `session-ses_244b.md`, `session-ses_244b 2.md`
- Delete: `skills-lock.json`, `skills-lock 2.json`
- Delete: `temp_ns.json`, `temp_ns 2.json`
- Delete: `.flutter-plugins-dependencies` duplicate files (2 through 6)
- Delete: `flutter_01.log`
- Delete: `.DS_Store` in `lib/`, `lib/core/`, `lib/data/`
- Delete: `BIOMETRIC_AUTH_GUIDE.md` (if not referenced)
- Modify: `.gitignore`

- [ ] **Step 1: Delete temporary files**

```bash
rm -f \
  session-ses_244b.md \
  "session-ses_244b 2.md" \
  skills-lock.json \
  "skills-lock 2.json" \
  temp_ns.json \
  "temp_ns 2.json" \
  ".flutter-plugins-dependencies 2" \
  ".flutter-plugins-dependencies 3" \
  ".flutter-plugins-dependencies 4" \
  ".flutter-plugins-dependencies 5" \
  ".flutter-plugins-dependencies 6" \
  flutter_01.log
```

- [ ] **Step 2: Remove .DS_Store files**

```bash
find lib/ -name ".DS_Store" -delete
```

- [ ] **Step 3: Update .gitignore**

Read current `.gitignore` and add these entries:

```
# Temp files
*.log
temp_*.json
session-*.md
skills-lock.json
* 2.*
* 3.*
* 4.*
* 5.*
* 6.*
.flutter-plugins-dependencies

# macOS
.DS_Store
```

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "chore: remove temp files and update gitignore"
```

---

### Task 1.5 — Eliminar código de ejemplo no usado

**Files:**
- Delete: `lib/presentation/screens/biometric_auth_example.dart`
- Delete: `lib/presentation/screens/biometric_auth_screen.dart`
- Delete: `lib/presentation/screens/biometric_example_main.dart`
- Delete: `lib/presentation/screens/biometric_screen.dart`

- [ ] **Step 1: Verify no imports reference these files**

```bash
grep -r "presentation/screens" lib/ --include="*.dart"
```

Expected: No results (zero references from main code)

- [ ] **Step 2: Move to docs/examples/ for safekeeping (or delete if not needed)**

```bash
mkdir -p docs/examples/biometric
cp lib/presentation/screens/*.dart docs/examples/biometric/
rm -rf lib/presentation/
```

- [ ] **Step 3: Verify**

```bash
flutter analyze
```

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "chore: remove unused presentation example screens"
```

---

### Task 1.6 — flutter clean y reconstrucción

- [ ] **Step 1: Clean rebuild**

```bash
flutter clean
flutter pub get
flutter analyze
```

Expected: Clean analysis with no errors.

- [ ] **Step 2: Commit**

```bash
git commit --allow-empty -m "chore: flutter clean after Phase 1 cleanup"
```

---

## Fase 2: Higiene de Código

### Task 2.1 — Extraer _SearchDebounce a archivo compartido

**Files:**
- Create: `lib/components/search_debounce.dart`
- Modify: `lib/screens/home/HomeScreen.dart` (lines containing _SearchDebounce)
- Modify: `lib/screens/password/PasswordScreen.dart` (lines containing _SearchDebounce)

- [ ] **Step 1: Create search_debounce.dart**

```dart
import 'dart:async';
import 'package:flutter/material.dart';

class SearchDebounce {
  final Duration duration;
  Timer? _timer;

  SearchDebounce({this.duration = const Duration(milliseconds: 300)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
```

- [ ] **Step 2: Replace in HomeScreen.dart**

Read HomeScreen.dart to find the _SearchDebounce class and its usages. Replace:
- Remove the private `_SearchDebounce` class definition
- Replace `final _searchDebounce = _SearchDebounce();` with `final _searchDebounce = SearchDebounce();`
- Ensure import is added: `import 'package:thisjowi/components/search_debounce.dart';`
- Replace `_searchDebounce.run(() { ... })` calls

- [ ] **Step 3: Replace in PasswordScreen.dart**

Same pattern as Step 2.

- [ ] **Step 4: Verify**

```bash
flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "refactor: extract SearchDebounce to shared component"
```

---

### Task 2.2 — Refactorizar SettingScreen (1492 líneas)

**Files:**
- Create: `lib/screens/settings/components/profile_section.dart`
- Create: `lib/screens/settings/components/password_change_section.dart`
- Create: `lib/screens/settings/components/theme_section.dart`
- Create: `lib/screens/settings/components/api_config_section.dart`
- Create: `lib/screens/settings/components/export_import_section.dart`
- Create: `lib/screens/settings/components/danger_zone_section.dart`
- Create: `lib/screens/settings/components/biometric_section.dart`
- Modify: `lib/screens/settings/SettingScreen.dart` (reduce to ~200 lines as orchestrator)

- [ ] **Step 1: Read SettingScreen.dart fully**

Read the entire file to understand its structure.

- [ ] **Step 2: Extract each section**

For each section component:
- Create a new StatefulWidget for the section
- Move the relevant code from SettingScreen into it
- Each section handles its own TextEditingController lifecycle (dispose)
- Each section receives only the data it needs via constructor or Provider

- [ ] **Step 3: Rewrite SettingScreen.dart as orchestrator**

Compose all sections in a ListView, each section wrapped in a card or section header.

- [ ] **Step 4: Verify**

```bash
flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "refactor: split SettingScreen (1492 lines) into 7 components"
```

---

### Task 2.3 — Separar HomeScreen (1056 líneas)

**Files:**
- Create: `lib/screens/home/components/password_list_tab.dart`
- Create: `lib/screens/home/components/notes_list_tab.dart`
- Create: `lib/screens/home/components/home_fab.dart`
- Create: `lib/screens/home/components/sync_banner.dart`
- Modify: `lib/screens/home/HomeScreen.dart`

- [ ] **Step 1: Read HomeScreen.dart fully**

- [ ] **Step 2: Extract password list tab section**

- [ ] **Step 3: Extract notes list tab section**

- [ ] **Step 4: Extract FAB and sync banner**

- [ ] **Step 5: Rewrite HomeScreen as TabBarView orchestrator**

- [ ] **Step 6: Verify**

```bash
flutter analyze
```

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "refactor: split HomeScreen (1056 lines) into 4 components"
```

---

### Task 2.4 — Arreglar memory leaks de TextEditingController

**Files:**
- Modify: `lib/screens/settings/SettingScreen.dart` (add dispose for _currentPasswordController)
- Modify: Any other files with undisposed controllers

- [ ] **Step 1: Find all TextEditingController usages**

```bash
grep -rn "TextEditingController()" lib/ --include="*.dart"
```

- [ ] **Step 2: For each, verify dispose() exists**

For SettingScreen.dart, add:
```dart
@override
void dispose() {
  _currentPasswordController.dispose();
  _newPasswordController.dispose();
  _confirmPasswordController.dispose();
  super.dispose();
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze
```

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "fix: add missing TextEditingController.dispose() to prevent memory leaks"
```

---

### Task 2.5 — Unificar ServiceLocator dentro de Provider

**Files:**
- Modify: `lib/main.dart` (add Provider entries for each repository)
- Modify: All files that use `ServiceLocator()` (search each one)
- Delete: `lib/core/service_locator.dart`

- [ ] **Step 1: Find all ServiceLocator usages**

```bash
grep -rn "ServiceLocator\(\)" lib/ --include="*.dart"
```

- [ ] **Step 2: Add Provider entries to main.dart**

```dart
// In the providers list in MainApp.build:
ChangeNotifierProvider(create: (_) => ThemeProvider()),
ChangeNotifierProvider(create: (_) => OtpProvider()),
ChangeNotifierProvider(create: (_) => SyncProvider()),
Provider<PasswordsRepository>(create: (_) => PasswordsRepository()),
Provider<NotesRepository>(create: (_) => NotesRepository()),
Provider<OtpRepository>(create: (_) => OtpRepository()),
Provider<ProfileRepository>(create: (_) => ProfileRepository()),
```

- [ ] **Step 3: Replace each ServiceLocator() call with context.read<>()**

For each file found in Step 1, replace:
```dart
// Before:
ServiceLocator().passwordsRepository

// After:
context.read<PasswordsRepository>()
```

For non-widget classes, pass dependencies through constructor or use Provider.of with listen: false.

- [ ] **Step 4: Delete service_locator.dart**

```bash
rm lib/core/service_locator.dart
```

- [ ] **Step 5: Verify**

```bash
flutter analyze
```

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "refactor: migrate ServiceLocator to Provider DI"
```

---

### Task 2.6 — Añadir const constructors masivos

**Files:**
- Modify: `analysis_options.yaml` (add lint rules)
- Modify: All `.dart` files (via dart fix)

- [ ] **Step 1: Add lint rules to analysis_options.yaml**

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - prefer_const_declarations
```

- [ ] **Step 2: Run dart fix**

```bash
dart fix --apply lib/
```

- [ ] **Step 3: Verify**

```bash
flutter analyze
```

Fix any remaining lint warnings manually.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "style: add const constructors via dart fix and lint rules"
```

---

### Task 2.7 — Optimizar animaciones existentes

**Files:**
- Modify: `lib/components/background_orbs.dart`
- Modify: `lib/components/liquid_glass.dart`
- Modify: `lib/screens/splash/splash.dart` (if animated)

- [ ] **Step 1: Read each file**

- [ ] **Step 2: Add RepaintBoundary**

Wrap CustomPaint/Animation widgets in RepaintBoundary:
```dart
RepaintBoundary(
  child: CustomPaint(
    painter: _OrbPainter(animation.value),
    size: Size.infinite,
  ),
)
```

- [ ] **Step 3: Add const where missing**

Ensure widget constructors use const where possible.

- [ ] **Step 4: Verify**

```bash
flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "perf: wrap animations in RepaintBoundary, add const"
```

---

## Fase 3: Optimización Runtime

### Task 3.1 — Lazy loading de providers pesados

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Read main.dart providers section**

- [ ] **Step 2: Move heavy providers to lazy initialization**

```dart
// Current:
ChangeNotifierProvider(create: (_) => OtpProvider()),
ChangeNotifierProvider(create: (_) => SyncProvider()),

// These are already lazy by default in Provider (only created when watched).
// If they do work in constructor, move that work to a separate init method.
```

If OtpProvider/SyncProvider have heavy constructor work, refactor:
```dart
class OtpProvider extends ChangeNotifier {
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    // Heavy work here
  }
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze
```

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "perf: lazy provider initialization for Otp and Sync"
```

---

### Task 3.2 — RepaintBoundary en animaciones y scrolls

**Files:**
- Modify: Various screen files with scrollable lists
- Modify: `lib/screens/otp/TOPT.dart` (animated OTP)
- Modify: `lib/components/background_orbs.dart`

- [ ] **Step 1: Find all ListView builders**

```bash
grep -rn "ListView\(" lib/ --include="*.dart" | head -30
```

- [ ] **Step 2: Wrap scroll views in RepaintBoundary**

For each ListView that contains complex items (not simple Text widgets), wrap in RepaintBoundary.

- [ ] **Step 3: Verify**

```bash
flutter analyze
```

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "perf: add RepaintBoundary to scroll views and animations"
```

---

### Task 3.3 — compute() para operaciones pesadas

**Files:**
- Modify: `lib/services/cryptoService.dart`
- Modify: `lib/services/sync_service.dart`
- Modify: `lib/services/password_generator_service.dart`
- Modify: `lib/services/import_export_service.dart`
- Modify: `lib/services/otpService.dart`

- [ ] **Step 1: Identify compute-candidate functions in cryptoService.dart**

Read cryptoService.dart to find encrypt/decrypt methods.

- [ ] **Step 2: Create top-level compute functions**

In the same file or a helper, create static/top-level functions:
```dart
// In cryptoService.dart or encryption_helper.dart
Future<String> encryptInBackground(String plainText, String key) async {
  return await compute(_encryptInIsolate, _EncryptParams(plainText, key));
}

String _encryptInIsolate(_EncryptParams params) {
  // Full encryption logic here
  return encrypted;
}
```

- [ ] **Step 3: Replace sync calls with compute() calls**

```dart
// Before:
final encrypted = encryptService.encrypt(password, key);

// After:
final encrypted = await encryptInBackground(password, key);
```

- [ ] **Step 4: Repeat for sync_service.dart export/import**

- [ ] **Step 5: Verify**

```bash
flutter analyze
```

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "perf: move heavy crypto/sync ops to compute() isolates"
```

---

### Task 3.4 — Optimizar imágenes en runtime

**Files:**
- Modify: All files using Image.asset, Image.network, AssetImage, NetworkImage

- [ ] **Step 1: Find all image usages**

```bash
grep -rn "Image\.asset\|Image\.network\|AssetImage\|NetworkImage\|FileImage" lib/ --include="*.dart"
```

- [ ] **Step 2: For each static-image usage, add cacheWidth/cacheHeight**

```dart
// Before:
Image.asset('assets/logo.png')

// After:
Image.asset('assets/logo.png', cacheWidth: 128, cacheHeight: 128)
```

Use `context` to determine display size, or hardcode the display size from the widget.

- [ ] **Step 3: For avatar images (profile), add cacheWidth**

```dart
Image.network(avatarUrl, cacheWidth: 96, cacheHeight: 96)
```

- [ ] **Step 4: Verify**

```bash
flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "perf: add cacheWidth/cacheHeight to all image loads"
```

---

### Task 3.5 — Provider select() para evitar rebuilds

**Files:**
- Modify: All files using `context.watch<ThemeProvider>()`, `context.watch<OtpProvider>()`, `context.watch<SyncProvider>()`, `Consumer<ThemeProvider>`, etc.

- [ ] **Step 1: Find all watch/Consumer usages**

```bash
grep -rn "context\.watch\|Consumer<" lib/ --include="*.dart"
```

- [ ] **Step 2: For each, replace with select() where only one field is needed**

```dart
// Before:
final themeProvider = context.watch<ThemeProvider>();
// themeProvider.themeMode used somewhere
// themeProvider.isDarkMode used somewhere else (but causes rebuild)

// After:
final isDark = context.select<ThemeProvider, bool>((t) => t.isDarkMode);
final themeMode = context.select<ThemeProvider, ThemeMode>((t) => t.flutterThemeMode);
```

- [ ] **Step 3: For Consumer<> widgets, convert to ConsumerWidget with selectors**

```dart
// Before:
Consumer<ThemeProvider>(
  builder: (context, tp, _) => Text(tp.isDarkMode ? 'Dark' : 'Light'),
)

// After: Use the existing _SystemUIUpdater pattern or just select
```

- [ ] **Step 4: Verify**

```bash
flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "perf: use Provider select() to minimize rebuilds"
```

---

### Task 3.6 — ListView.builder en listas existentes

**Files:**
- Modify: All `.dart` files with `ListView(children: [.map(])` patterns

- [ ] **Step 1: Find all ListView(children:) patterns**

```bash
grep -rn "ListView(" lib/ --include="*.dart"
```

- [ ] **Step 2: For each dynamic list, convert to builder**

```dart
// Before:
ListView(
  children: passwords.map((p) => PasswordCard(p)).toList(),
)

// After:
ListView.builder(
  itemCount: passwords.length,
  itemBuilder: (context, index) => PasswordCard(
    passwords[index],
    key: ValueKey(passwords[index].id),
  ),
)
```

- [ ] **Step 3: For short static lists, keep as ListView(children:) (no benefit)**

- [ ] **Step 4: Verify**

```bash
flutter analyze
```

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "perf: convert ListView to ListView.builder for dynamic lists"
```

---

### Task 3.7 — Inicialización lazy de servicios pesados

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/services/sync_service.dart`
- Modify: `lib/services/auth_service.dart`

- [ ] **Step 1: Review main.dart initialization sequence**

```dart
// Current sequence:
await AppLogger.initialize();
await EnvLoader.load();
await ApiConfig.init();
await TokenManager().init();
```

- [ ] **Step 2: Difer non-critical inits**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... critical inits ...
  
  runApp(const MainApp());
  
  // Difer heavy inits to after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    SyncService.instance.initialize();  // non-critical
  });
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze
```

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "perf: lazy-init non-critical services after first frame"
```

---

## Fase 4: Build & CI

### Task 4.1 — Configurar ProGuard/R8 para Android

**Files:**
- Modify: `android/app/build.gradle`
- Create: `android/app/proguard-rules.pro`

- [ ] **Step 1: Edit android/app/build.gradle**

Add to `buildTypes.release`:
```gradle
release {
    signingConfig signingConfigs.debug // Or release
    minifyEnabled true
    shrinkResources true
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
}
```

- [ ] **Step 2: Create proguard-rules.pro**

```
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Drift / SQLite
-dontwarn org.sqlite.**
-keep class org.sqlite.** { *; }
```

- [ ] **Step 3: Verify**

```bash
flutter build apk --release
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "build: enable ProGuard/R8 minification for Android"
```

---

### Task 4.2 — Tree-shaking y ofuscación en build

**Files:**
- Create: `scripts/build_release.sh`

- [ ] **Step 1: Create build script**

```bash
#!/bin/bash
set -e

echo "Building THISECURE release..."

# Android build
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/debug-info/android \
  --tree-shake-icons

# iOS build (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
  flutter build ipa --release \
    --obfuscate \
    --split-debug-info=build/debug-info/ios \
    --tree-shake-icons
fi

echo "Build complete!"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x scripts/build_release.sh
```

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "build: add release build script with obfuscation and tree-shaking"
```

---

### Task 4.3 — iOS App Thinning

**Files:**
- Modify: None (Xcode project settings)

- [ ] **Step 1: Verify iOS release build**

```bash
flutter build ipa --release
```

Expected: Build succeeds.

- [ ] **Step 2: Commit (or note)**

```bash
git add scripts/build_release.sh 2>/dev/null || true
git commit -m "build: iOS App Thinning via release flags"
```

---

### Task 4.4 — Workflows de build por plataforma

**Files:**
- Modify/Check: `.github/` (if CI workflows exist)

- [ ] **Step 1: Read .github/workflows/**

Check if CI workflows exist and read them.

- [ ] **Step 2: Add optimized build commands to workflows**

If workflows exist, update with:
```yaml
# In the build step:
run: flutter build apk --release --obfuscate --split-debug-info=build/debug-info --tree-shake-icons
```

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "ci: add optimized build commands to workflows"
```
