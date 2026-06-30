# Hosting Mode Dropdown in Auth Screens

## Problem

The hosting mode selection (Cloud vs Self-Hosted) currently lives in a separate `DeploymentSetupScreen` that acts as a gate before login/register. This adds friction: users must go through an extra screen before reaching the auth form.

## Design

Replace the separate `DeploymentSetupScreen` with an inline dropdown on both the login and register screens.

### Login Screen

- Replace the passive deployment mode badge (currently just informational text) with an interactive `DropdownButton<String>`
- Options: `Cloud`, `Self-Hosted`
- Changing the dropdown saves the selection to `SharedPreferences` (`deployment_mode` key)
- No additional fields shown — assumes server is already configured
- The "Sign Up" link navigates directly to `/register` (bypasses `DeploymentSetupScreen`)

### Register Screen

- Add the same dropdown above the registration form
- When `Self-Hosted` is selected, show inline fields: **Server Host**, **Port**, **Use SSL** toggle
- No LDAP step (LDAP configuration remains only in login)
- On successful registration, save server config to `SharedPreferences` (same keys as before: `self_hosted_host`, `self_hosted_port`, `self_hosted_use_ssl`)
- The "Back" link navigates to `/login`

### Onboarding

- "Create Account" → `/register` (direct, no `DeploymentSetupScreen`)
- "Log In" → `/login` (direct, no `DeploymentSetupScreen`)

### Routing Changes

- Remove `/deployment-setup` route from `main.dart` if no longer needed
- `DeploymentSetupScreen` widget may still be used elsewhere — verify before removing

### Files to modify

| File | Change |
|------|--------|
| `lib/screens/auth/login.dart` | Add dropdown, remove badge, change Sign Up nav |
| `lib/screens/auth/registerForm.dart` | Add dropdown + conditional server fields |
| `lib/screens/onboarding/onBoarding.dart` | Nav to `/login` and `/register` directly |
| `lib/main.dart` | Remove `/deployment-setup` route (verify no other refs) |
