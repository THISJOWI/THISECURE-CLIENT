# Passkeys section on HomeScreen — Design

**Date:** 2026-06-17
**Status:** Approved
**Scope:** Add a "Passkeys" section to the HomeScreen of the THISECURE client, backed by the existing `passkey` Go service at `backend/services/passkey/`.

## Context

The backend already exposes a CRUD HTTP API for WebAuthn credentials at `GET/POST/PUT/DELETE /v1/passkeys` (JWT auth, encrypted `publicKey` at rest, Kafka sync events under the service name `passkey`). The Flutter client currently has no passkey service, model, model section, or FAB entry point. This design adds a read-list + create (real WebAuthn ceremony) + delete flow on the HomeScreen.

## Decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Scope | Real WebAuthn flow (registration ceremony on the device) |
| Offline support | Server-only (no Drift table) |
| Ceremony entry point | Add as FAB action only; tap-to-assert is out of scope |
| Platform support | iOS, Android, Web |
| Form fields | Minimal + auto: only `name` is required from the user |
| Library | `passkeys` (Corbado), `^2.20.0` |

## Architecture

- **`passkeys` (Corbado, `^2.20.0`)** drives the WebAuthn ceremony natively on iOS/Android and via `navigator.credentials` on Web.
- **`lib/services/passkeyService.dart`** — thin HTTP client mirroring `PasswordService` (uses `ApiConfig.passkeysUrl`, `TokenManager` for bearer auth, returns the standard `{ success, data, message }` map).
- **`lib/services/passkey_ceremony_service.dart`** — wraps `passkeys` to build the `RegisterRequest` (challenge = random 32 bytes; rpId derived from `ApiConfig.baseUrl` host; userHandle = 16 random bytes; userDisplayName = current user email; relyingPartyId/name defaults) and translate the `RegisterResponse` into the backend `PasskeyRequest` body.
- **`lib/data/models/passkey_entry.dart`** — Dart record of the Go `Passkey` struct.
- **UI**: `PasskeyItem` widget for list rows, new section header on HomeScreen, `RegisterPasskeyScreen` triggered by the FAB, `PasskeyDetailsDialog` for read + delete.

## Data flow

```
[HomeScreen]
   │
   │  tap "Passkey" in ExpandableActionButton
   ▼
[RegisterPasskeyScreen]  ── user enters "name" only ──>
   │
   │  1. passkeys.register(RegisterRequest{challenge, rp, user, pubKeyCredParams})
   │     → device prompts Face ID / Touch ID / platform authenticator
   │  2. PasskeyService.create(PasskeyRequest{name, credentialId, publicKey, ...})
   │     → POST /v1/passkeys
   ▼
[HomeScreen reloads passkeys]  via PasskeyService.getAll() → GET /v1/passkeys
```

List read path mirrors the existing pattern: `PasskeyService.getAll()` → backend → render. The `SyncProvider` listener already triggers reloads for `password/*` and `note/*`; we add `passkey/*` so Kafka events for the `passkey` service refresh the section automatically.

## Components

| File | Role |
|---|---|
| `lib/data/models/passkey_entry.dart` | Dart model + `fromJson`/`toJson` |
| `lib/services/passkeyService.dart` | CRUD HTTP client (getAll, getById, create, update, delete) |
| `lib/services/passkey_ceremony_service.dart` | WebAuthn ceremony via `passkeys`; produces `PasskeyRequest` |
| `lib/screens/home/components/passkey_item.dart` | Liquid glass card row, matches `PasswordItem` styling (icon, name, rpName, badge for backupEligible) |
| `lib/screens/passkey/register_passkey_screen.dart` | Form: single `name` field + "Register" button. Shows platform-specific copy. |
| `lib/screens/passkey/passkey_details_dialog.dart` | Read-only dialog (name, rpId, rpName, signCount, transports, backup flags) with `Delete` action. |
| `lib/screens/home/HomeScreen.dart` (edit) | Add `_passkeys` list, `PasskeyService` instance, fetch in `_loadData`, render new section + skeleton + sync listener, FAB callback. |
| `lib/components/button.dart` (edit) | Add `onCreatePasskey` callback + option button (icon `Icons.fingerprint`, label "Passkey"). |
| `lib/utils/GlobalActions.dart` (edit) | Add `createPasskey(...)` that pushes `RegisterPasskeyScreen`. |
| `lib/core/api.dart` (edit) | Add `passkeysUrl` getter. |
| `.env` + `.env.example` (edit) | Add `PASSKEY_SERVICE_URL=/v1/passkeys`. |
| `lib/i18n/translations.dart` (edit) | Add EN/ES keys (see i18n section). |
| `pubspec.yaml` (edit) | `passkeys: ^2.20.0` |
| `ios/Runner/Runner.entitlements` (edit) | Add `com.apple.developer.associated-domains` array with `webcredentials:api.thisjowi.com`. |
| `android/app/src/main/res/values/strings.xml` + asset links asset | Digital asset links to associate the app with the RP. |
| `web/index.html` (edit) | RP ID script (or pass `rpId` from `ApiConfig.baseUrl`). |

## Error handling

| Scenario | Behavior |
|---|---|
| User cancels platform prompt | No network call. Show info snackbar "Registration cancelled". |
| Ceremony fails (no authenticator, user denied biometric, etc.) | Error snackbar from `passkeys` exception message. |
| `POST /v1/passkeys` returns 4xx/5xx | Error snackbar with server message; stay on form. |
| Network timeout | Same as password service: 30s timeout, "Connection timeout" message. |
| `GET /v1/passkeys` fails | Section is empty; rest of HomeScreen keeps working. No blocking. |
| Sync event arrives but `getAll` fails | Silent — already showing empty state. |

## i18n keys (EN / ES)

- `Passkeys` / `Passkeys`
- `Add passkey` / `Añadir passkey`
- `Register passkey` / `Registrar passkey`
- `Delete passkey?` / `¿Eliminar passkey?`
- `No passkeys yet` / `Aún no hay passkeys`
- `Use %s to create this passkey` / `Usa %s para crear este passkey`
- `Passkey created` / `Passkey creada`
- `Passkey deleted` / `Passkey eliminada`
- `Passkey creation failed` / `Error al crear la passkey`
- `Registration cancelled` / `Registro cancelado`
- `Passkey name` / `Nombre de la passkey`

## Testing

- **Unit** (`test/services/passkey_ceremony_service_test.dart`): challenge is 32 random bytes; userHandle is 16 random bytes; resulting `PasskeyRequest` carries the right `credentialId` / `publicKey` from the fake `RegisterResponse`; `rpId` defaults to the host extracted from `ApiConfig.baseUrl`. Mock `passkeys`.
- **Unit** (`test/services/passkey_service_test.dart`): HTTP contract (200/401/500) maps to the `{success, data, message}` envelope.
- **Widget** (`test/screens/home/home_screen_passkeys_test.dart`): section header shows the count, deleting prompts confirmation, FAB opens the register screen, empty state copy.
- **Manual checklist**: iOS device (Face ID/Touch ID prompt + associated domain), Android device (fingerprint prompt + asset links), Web on `localhost` and `api.thisjowi.com` (browser prompt).

## Out of scope

- Passkey **assertion** (sign-in with a saved passkey) — THISECURE uses email + password / OTP.
- Passkey **edit** (PUT) — backend supports it but no UI in v1 (just register + delete). Re-registration covers renames.
- **Offline cache** — confirmed not in scope.
- **Passkey usage in the autofill pipeline** — independent feature, can be layered on later.
