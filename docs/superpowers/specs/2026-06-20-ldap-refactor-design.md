# Refactor LDAP: Feature Folder + Flujo con Diagnóstico

## Problem

LDAP está disperso por toda la app con `if (deploymentMode == 'SelfHosted')` repetidos en 15+ archivos. El wizard de deployment_setup.dart (984 líneas) mezcla configuración de servidor con LDAP. Cuando LDAP falla, no hay forma de saber si es por conexión de red, credenciales inválidas, o configuración incorrecta. Los usuarios Cloud ven código LDAP que no les aplica.

## Design

### Principios

1. **Cloud nunca ve LDAP** — ni en onboarding, ni en settings, ni en login
2. **LDAP se pregunta en onboarding**, tras configurar servidor
3. **Solo el admin LDAP** puede reconfigurarlo desde settings
4. **Test de conexión granular** con diagnóstico claro (red vs credenciales vs ruta)

### Flujo de Onboarding + Registro (SelfHosted)

```
Onboarding:
1. Elegir modo: Cloud (fin) | SelfHosted
2. Servidor: host + puerto + SSL
3. → Flujo de registro

Registro (SelfHosted):
4. Formulario de registro (email, nombre, password)
5. ❓ "¿Quieres configurar LDAP?" → Sí / No
6. [No] → Registro normal, fin.
   [Sí] → Formulario LDAP:
   - Host + Puerto LDAP
   - Bind DN + Contraseña
   - Base DN + Filtro de búsqueda
   - Atributo de usuario
   - [Test Conexión] → feedback por paso:
     ✅ Host:puerto alcanzable (TCP)
     ✅ Bind DN autentica correctamente
     ✅ Base DN existe y es accesible
     ❌ [Error específico por paso]
7. El usuario registrado queda como admin LDAP de la org
```

El LDAP se configura DURANTE el registro, no en el wizard de deployment_setup. deployment_setup solo hace modo + servidor.

### Flujo de Login

```
Login normal, sin rastro LDAP si no configurado.
Si LDAP está habilitado:
- Se muestra opción de login LDAP
- Errores claros: "Servidor LDAP no responde" vs "Credenciales inválidas" vs "Usuario no encontrado"
```

### Settings (solo admin LDAP)

```
Settings → "Configuración LDAP" (solo visible si SelfHosted + eres admin)
├── Mismos campos + test de conexión granular
├── Indicador 🟢 Conectado / 🔴 Desconectado
├── [Guardar cambios]
└── [Desconectar dominio] (solo admin)
```

### Arquitectura

```
lib/
  features/
    ldap/                              ← TODO lo LDAP aislado
      providers/
        ldap_config_provider.dart      # estado: config, isConfigured, isAdmin
        ldap_test_provider.dart        # test conexión paso a paso (state machine)
      services/
        ldap_connection_service.dart   # test conexión con diagnóstico
      screens/
        ldap_config_screen.dart        # formulario desde settings
      widgets/
        ldap_config_form.dart          # formulario reutilizable (onboarding + settings)
        ldap_test_feedback.dart        # test con feedback visual por paso
        ldap_status_indicator.dart     # 🟢🔴 indicador conectado/desconectado
    deployment/
      providers/
        deployment_provider.dart       # ChangeNotifier: isSelfHosted, isLdapEnabled
      widgets/
        deployment_mode_selector.dart  # existente, sin cambios
        server_config_form.dart        # extraído de deployment_setup.dart
      screens/
        deployment_setup.dart          # simplificado: modo + servidor (sin LDAP)
  screens/
    settings/
      SettingScreen.dart               # entrada LDAP solo si admin
    auth/
      login.dart                       # sin lógica LDAP directa
      register_flow.dart               # paso LDAP después de servidor
  services/
    ldap_service.dart                  # loginWithLdap (lo que queda tras extraer config)
```

### DeploymentProvider (ChangeNotifier)

```
Properties:
  - deploymentMode: String ('Cloud' | 'SelfHosted')
  - isSelfHosted: bool (getter)
  - isLdapConfigured: bool
  - isLdapAdmin: bool

Methods:
  - setDeploymentMode(String mode)
  - setLdapConfigured(bool value)
  - setLdapAdmin(bool value)
  - loadFromPrefs()  # init desde SharedPreferences
  - saveToPrefs()

Consume:
  DeploymentProvider.of(context).isSelfHosted → bool
  context.watch<DeploymentProvider>().isLdapConfigured → bool
```

### Test de Conexión Granular

El test de conexión LDAP ejecuta pasos secuenciales y reporta el primero que falla:

```
Paso 1: TCP connection to host:port
  → ✅ Connected / ❌ Connection refused / ❌ Timeout (30s)

Paso 2: Bind with credentials (bind DN + password)
  → ✅ Bound successfully / ❌ Invalid credentials / ❌ Insufficient access

Paso 3: Search base DN
  → ✅ Base DN found / ❌ No such object / ❌ Insufficient access

Resultado final: ✅ Todo OK | ❌ [primer error con sugerencia]
```

Esto permite al usuario saber exactamente qué está mal sin adivinar.

### Routing

- `/deployment-setup` → se simplifica (solo modo + servidor)
- No se añaden rutas nuevas; LDAP config es un paso en el flujo de registro/widget embebido
- La ruta a settings LDAP es navegación interna desde SettingScreen

### Cloud Isolation

- `DeploymentProvider.isSelfHosted == false` → ningún widget LDAP se renderiza
- Los imports de `features/ldap/` solo se hacen desde widgets condicionales
- El árbol de widgets LDAP nunca se construye en modo Cloud

### Errores de Login LDAP

| Condición | Mensaje |
|-----------|---------|
| Servidor no responde | "No se puede conectar al servidor LDAP. Verifica tu conexión de red." |
| Credenciales inválidas | "Usuario o contraseña LDAP incorrectos." |
| Usuario no existe | "No se encontró un usuario LDAP con esas credenciales." |
| Tiempo de espera | "La conexión LDAP tardó demasiado. Intenta de nuevo." |

## Archivos a Modificar

### Nuevos

| Archivo | Propósito |
|---------|-----------|
| `lib/features/ldap/providers/ldap_config_provider.dart` | Estado LDAP |
| `lib/features/ldap/providers/ldap_test_provider.dart` | State machine test |
| `lib/features/ldap/services/ldap_connection_service.dart` | Test conexión |
| `lib/features/ldap/screens/ldap_config_screen.dart` | Settings form |
| `lib/features/ldap/widgets/ldap_config_form.dart` | Form reutilizable |
| `lib/features/ldap/widgets/ldap_test_feedback.dart` | Feedback test |
| `lib/features/ldap/widgets/ldap_status_indicator.dart` | Indicador estado |
| `lib/features/deployment/providers/deployment_provider.dart` | Feature flags |

### Modificar

| Archivo | Cambio |
|---------|--------|
| `lib/screens/auth/deployment_setup.dart` | Simplificar: solo modo + servidor, sin LDAP |
| `lib/screens/auth/login.dart` | Quitar lógica LDAP directa, usar provider |
| `lib/screens/auth/register_flow.dart` | Agregar paso LDAP tras servidor |
| `lib/screens/settings/SettingScreen.dart` | Entrada LDAP condicional (admin) |
| `lib/services/org_service.dart` | Simplificar, usar ldap_config_provider |
| `lib/services/auth_service.dart` | Mantener loginWithLdap, sin cambios mayores |
| `lib/main.dart` | Registrar DeploymentProvider en MultiProvider |

### Eliminar (o mover a features/ldap/)

| Archivo | Razón |
|---------|-------|
| `lib/components/ldap_selector.dart` | Mover a features/ldap/widgets/ |
| `lib/components/ldap_user_card.dart` | Mover a features/ldap/widgets/ |
| `lib/services/organizationService.dart` | Mover testLdapConnection a features/ldap/ |

## Testing

### Unit tests
- `DeploymentProvider`: modo cloud/selfhosted, persistencia
- `LdapTestProvider`: state machine pasos, transiciones, errores
- `LdapConnectionService`: diagnóstico de cada paso

### Widget tests
- `LdapConfigForm`: renderizado condicional, test connection flow
- `LdapTestFeedback`: cada estado de feedback se muestra correctamente
- `LdapStatusIndicator`: verde/rojo según estado

### Integration tests
- Flujo onboarding SelfHosted completo con y sin LDAP
- Login LDAP con servidor real (mock)
- Settings: admin puede modificar, no-admin no ve entrada

## No Incluido (scope explícito)

- No se refactoriza el backend (endpoints LDAP existentes se mantienen)
- No se cambia el modelo de datos de Organization/AuthUser
- No se cambia el flujo de registro para Cloud
- No se añaden nuevas funcionalidades LDAP (solo refactor)
