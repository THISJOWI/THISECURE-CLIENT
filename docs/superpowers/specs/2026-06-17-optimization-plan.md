# Plan de Optimización THISECURE

**Fecha:** 2026-06-17
**Nivel:** Medio — Reestructuración táctica
**Plataformas:** Todas (Android, iOS, macOS, Windows, Linux, Web)

## Resumen

Plan de optimización integral para la app THISECURE, organizado en 4 fases progresivas. Cada fase produce resultados verificables independientemente.

## Fase 1: Cirugía de Espacio

Objetivo: ~2MB menos en disco, builds más rápidas, dependencias limpiadas.

### Tarea 1.1 — Eliminar archivos duplicados de Dart

Eliminar 31 archivos con sufijo ` 2` en `lib/`. Son copias idénticas o versiones viejas que nunca se importan.

Lista completa:

- `lib/core/service_locator 2.dart`
- `lib/core/theme_provider 2.dart`
- `lib/core/http_client 2.dart`
- `lib/core/offline_mode_config 2.dart`
- `lib/core/exceptions/profile_exceptions 2.dart`
- `lib/core/exceptions/account_exceptions 2.dart`
- `lib/core/exceptions/auth_exceptions 2.dart`
- `lib/core/providers/otp_provider 2.dart`
- `lib/services/account_service 2.dart`
- `lib/services/base_service 2.dart`
- `lib/services/token_manager 2.dart`
- `lib/services/api_client 2.dart`
- `lib/services/profile_service 2.dart`
- `lib/data/models/password_entry 2.dart`
- `lib/data/models/profile_user 2.dart`
- `lib/data/models/auth_user 2.dart`
- `lib/data/models/account_user 2.dart`
- `lib/data/models/otp_entry 2.dart`
- `lib/components/social_login_button 2.dart`
- `lib/components/error_bar 2.dart`
- `lib/components/country_map_picker 2.dart`
- `lib/components/biometric_settings 2.dart`
- `lib/components/sync_debug_panel 2.dart`
- `lib/utils/app_logger 2.dart`
- `lib/screens/debug/logs_screen 2.dart`

Verificación: `flutter analyze` sin errores, `flutter build apk --debug` compila.

### Tarea 1.2 — Eliminar dependencias no usadas

Eliminar de `pubspec.yaml`:

- `rename: ^3.1.0` — nunca importado
- `skeletonizer: ^2.1.1` — nunca importado
- `flutter_watch_os_connectivity: ^1.0.0` — nunca importado

Ejecutar `flutter pub get`, `flutter clean`, `flutter analyze`.

### Tarea 1.3 — Comprimir assets de imagen

| Archivo | Tamaño actual | Target | Método |
|---------|-------------|--------|--------|
| `assets/logo.png` | 404 KB | ~25-50 KB | WebP 512px quality 85% o pngquant |
| `assets/empresa.png` | 130 KB | ~20-30 KB | WebP 512px quality 85% o pngquant |
| `assets/removed.png` | 9.4 KB | ~2-3 KB | WebP lossless 128px |

### Tarea 1.4 — Eliminar archivos temporales de la raíz

Eliminar: `session-ses_244b.md`, `session-ses_244b 2.md`, `skills-lock.json`, `skills-lock 2.json`, `temp_ns.json`, `temp_ns 2.json`, `.flutter-plugins-dependencies 2` hasta `6`, `flutter_01.log`, `.DS_Store` en lib/.

Añadir entradas a `.gitignore`.

### Tarea 1.5 — Eliminar código de ejemplo no usado

Eliminar directorio `lib/presentation/screens/` (4 archivos de ejemplo biométrico) o mover a `docs/examples/`.

### Tarea 1.6 — flutter clean y reconstrucción

```bash
flutter clean && flutter pub get && flutter analyze
```

## Fase 2: Higiene de Código

Objetivo: Reducir deuda técnica, eliminar memory leaks, unificar patrones.

### Tarea 2.1 — Extraer _SearchDebounce duplicado a archivo compartido

La clase `_SearchDebounce` está copiada en `HomeScreen.dart` y `PasswordScreen.dart`. Extraer a `lib/components/search_debounce.dart`.

### Tarea 2.2 — Refactorizar SettingScreen (1492 líneas)

Dividir en sub-componentes en `lib/screens/settings/components/`:

- `profile_section.dart` — perfil, nombre, país, avatar
- `password_change_section.dart` — cambio de contraseña
- `theme_section.dart` — selector de tema
- `api_config_section.dart` — URL de API
- `export_import_section.dart` — export/import
- `danger_zone_section.dart` — logout, eliminar cuenta
- `biometric_section.dart` — configuración biométrica

### Tarea 2.3 — Separar HomeScreen (1056 líneas)

Dividir en sub-componentes en `lib/screens/home/components/`:

- `password_list_tab.dart` — lista de contraseñas
- `notes_list_tab.dart` — lista de notas
- `home_fab.dart` — FAB con menú contextual
- `sync_banner.dart` — banner de sincronización

### Tarea 2.4 — Arreglar memory leaks de TextEditingController

Añadir `dispose()` a `_currentPasswordController` en SettingScreen. Revisar todos los controllers en el proyecto.

### Tarea 2.5 — Unificar ServiceLocator dentro de Provider

Convertir cada repositorio de ServiceLocator a Provider. Migrar todos los usos de `ServiceLocator()` a `context.read<>()`. Eliminar `service_locator.dart`.

### Tarea 2.6 — Añadir const constructors masivos

Añadir reglas lint: `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`. Ejecutar `dart fix --apply lib/`.

### Tarea 2.7 — Optimizar animaciones existentes

Revisar `background_orbs.dart` y `liquid_glass.dart`: añadir `RepaintBoundary`, `AnimatedBuilder`, `const` donde aplique.

## Fase 3: Optimización Runtime

Objetivo: Menos CPU/RAM, frames <16ms, menos rebuilds.

### Tarea 3.1 — Lazy loading de providers pesados

Mover `OtpProvider` y `SyncProvider` a inicialización lazy. Providers solo se crean cuando se accede a ellos.

### Tarea 3.2 — RepaintBoundary en animaciones y scrolls

Envolver animaciones (`background_orbs`, `liquid_glass`, `splash`) y listas scrollables en `RepaintBoundary`.

### Tarea 3.3 — compute() para operaciones pesadas

Migrar a `compute()`: encriptación/desencriptación (cryptoService), sincronización batch (sync_service), generación de contraseñas, parsing de CSV/JSON, TOTP generation.

### Tarea 3.4 — Optimizar imágenes en runtime

Añadir `cacheWidth`/`cacheHeight` a todos los `Image.asset`, `Image.network`, `AssetImage`. Buscar todos los usos con grep.

### Tarea 3.5 — Provider select() para evitar rebuilds

Reemplazar `context.watch<>()` con `context.select<>()` para subscribirse solo a propiedades específicas.

### Tarea 3.6 — ListView.builder en listas existentes

Reemplazar `ListView(children: [...])` con `ListView.builder()` en listas dinámicas. Asegurar `key` único en items.

### Tarea 3.7 — Inicialización lazy de servicios pesados

Diferir inicializaciones no críticas fuera de `main()`. Usar `scheduleMicrotask` o lazy singletons.

## Fase 4: Build & CI

Objetivo: APK/IPA más pequeño, builds optimizadas.

### Tarea 4.1 — Configurar ProGuard/R8 para Android

Añadir `minifyEnabled true`, `shrinkResources true` a `android/app/build.gradle`. Crear `proguard-rules.pro`.

### Tarea 4.2 — Tree-shaking y ofuscación en release

Añadir `--obfuscate`, `--split-debug-info`, `--tree-shake-icons` a los comandos de build.

### Tarea 4.3 — iOS App Thinning

Configurar compresión de assets y App Thinning en Xcode para reducir IPA.

### Tarea 4.4 — Workflows de build por plataforma

Crear scripts de CI separados por plataforma con flags optimizados.

## Resultados Esperados

| Métrica | Antes | Después |
|---------|-------|---------|
| Archivos duplicados | 31 | 0 |
| Dependencias no usadas | 3 | 0 |
| Tamaño assets | ~634 KB | ~100-150 KB |
| Archivos >500 líneas | 15 | ~3-4 |
| Memory leaks | 2 | 0 |
| Patrones DI | 2 mezclados | 1 unificado |
| APK release | ~20-25 MB | ~12-15 MB estimado |
