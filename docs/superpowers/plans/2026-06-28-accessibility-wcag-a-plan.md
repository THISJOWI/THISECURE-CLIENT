# WCAG A Accessibility — Implementation Plan

## Metadata

- **Spec:** `docs/superpowers/specs/2026-06-28-accessibility-wcag-a-design.md`
- **Target:** WCAG 2.2 Level A
- **Approach:** Semantics-first, reusable `lib/accessibility/` module + screen fixes
- **Audit scope:** 46 Scaffold instances, ~30 screen files, ~180 interactive elements

---

## Task list

### Phase 0: Module + infrastructure (4 tasks)

**0.1 Create `lib/accessibility/` module (8 files)**

Files to create:
```
lib/accessibility/
├── a11y_constants.dart
├── a11y_widgets.dart      # AccessibleIconButton, AccessibleTextField, AccessibleListTile,
│                          # AccessibleFab, SemanticsHeading, SemanticsScreenTitle,
│                          # AccessibleDialog, SemanticsIcon
├── a11y_theme.dart        # Contrast validation, a11yOverrideTheme
├── a11y_focus.dart        # ExplicitFocusOrder, SkipLink, ModalFocusTrap,
│                          # KeyboardShortcut, GlobalShortcuts, AccessibleNavObserver
├── a11y_extensions.dart   # BuildContext: isScreenReaderActive, reduceMotion, highContrast
├── a11y_animations.dart   # AnimatableBuilder (reduced-motion-aware wrapper)
├── a11y_test_utils.dart   # Test helpers for semantics verification
└── a11y_semantics.dart    # DecorativeWrapper, merge/exclude utilities
```

**0.2 Add a11y lint rules**
- `analysis_options.yaml`: add `avoid_print`, `use_key_in_widget_constructors`, `prefer_const_constructors` (already present)
- Consider adding custom lint for `no_tooltip_on_icon_button` if feasible
- Enable `strict-casts` and `strict-raw-types` for safer code

**0.3 Web/index.html fixes**
- `<html lang="en">` — missing lang attribute
- `<meta name="description" content="THiSECURE - Secure password manager and notes app">`
- `<style>` for `@media (prefers-reduced-motion: reduce)` to disable CSS animations

**0.4 Tests for a11y widgets**
- 5 test files in `test/accessibility/`:
  - `a11y_widgets_test.dart` — semantics tree verification for each accessible widget
  - `a11y_focus_test.dart` — SkipLink, ModalFocusTrap, KeyboardShortcut behavior
  - `a11y_theme_test.dart` — contrast validation utility
  - `a11y_animations_test.dart` — reduced-motion behavior
  - `a11y_extensions_test.dart` — MediaQuery wrapper tests

---

### Phase 1: IconButton tooltips (56 fixes across 30 files)

Replace every bare `IconButton` without tooltip with `AccessibleIconButton`.
Open each file, replace widget, provide translated `tooltip` string.

| File | Count | Tooltip strings needed |
|------|-------|----------------------|
| `lib/utils/GlobalActions.dart` | 2 | Copy, Paste |
| `lib/features/ldap/widgets/ldap_user_card.dart` | 1 | Cerrar sesión |
| `lib/components/ldap_user_card.dart` | 1 | Cerrar sesión |
| `lib/components/system_settings_section.dart` | 1 | Settings |
| `lib/components/autofill_card.dart` | 1 | Card actions |
| `lib/components/password_generator_dialog.dart` | 3 | Regenerate (done), Copy (done), Close |
| `lib/components/log_console_overlay.dart` | 3 | Clear logs, Copy, Close |
| `lib/components/country_selector.dart` | 1 | Search |
| `lib/screens/debug/logs_screen.dart` | 3 | Copy, Clear, Refresh (all already done) |
| `lib/screens/onboarding/countryMap.dart` | 1 | Close |
| `lib/screens/password/PasswordScreen.dart` | 6 | Copy username, Copy password, Show password, Edit, Delete, Add password |
| `lib/screens/password/AutofillPickerScreen.dart` | 1 | Close |
| `lib/screens/password/SavePasswordDialog.dart` | 1 | Close |
| `lib/screens/password/EditPasswordScreen.dart` | 2 | Copy password, Show/hide password |
| `lib/screens/notes/EditNoteScreen.dart` | 2 | Save note, Close |
| `lib/screens/environments/environment_list_screen.dart` | 2 | Add environment, Delete |
| `lib/screens/environments/environment_add_screen.dart` | 1 | Back |
| `lib/screens/otp/OtpQrScannerScreen.dart` | 2 | Close, Scan |
| `lib/screens/otp/TOPT.dart` | 3 | Copy code, Show QR, Options |
| `lib/screens/settings/SettingScreen.dart` | 2 | Edit profile, Log out |
| `lib/screens/auth/loginForm.dart` | 1 | Show/hide password |
| `lib/screens/auth/login.dart` | 1 | Server configuration |
| `lib/screens/auth/registerForm.dart` | 2 | Show/hide password, Show/hide confirm password |
| `lib/screens/auth/passwordResetVerification.dart` | 2 | Back, Resend code |
| `lib/screens/auth/forgotPassword.dart` | 1 | Back |
| `lib/screens/auth/emailVerification.dart` | 1 | Resend email |
| `lib/screens/auth/server_config_screen.dart` | 1 | Back |
| `lib/screens/home/components/password_item.dart` | 2 | Copy password, More options |
| `lib/screens/home/components/note_item.dart` | 1 | More options |
| `lib/screens/home/HomeScreen.dart` | 4 | Search, Add, Filter, Close detail |
| `lib/screens/messages/ChatScreen.dart` | 2 | Send message, Attach file |
| `lib/screens/messages/MessagesScreen.dart` | 1 | New message |
| `lib/screens/notes/NotesScreen.dart` | 1 | Add note |

---

### Phase 2: GestureDetector keyboard alternatives (32 fixes across 20 files)

For each GestureDetector:
1. Add `FocusNode` + `autofocus: false`
2. Add `onKeyEvent: (node, event) => ...` handling Enter/Space
3. OR wrap in `Semantics(button: true, label: ..., onTapHint: ...)`
4. OR replace with `InkWell` where appropriate

| File | Lines | Approach |
|------|-------|----------|
| `lib/components/social_login_button.dart` | 19 | Replace with InkWell + Semantics(label: 'Sign in with Google') |
| `lib/components/auth_method_selector.dart` | 79, 117, 175 | Wrap each in Semantics(button:, label:) + Focus |
| `lib/components/account_type_selector.dart` | 235 | Semantics(button:, label:) + Focus |
| `lib/components/deployment_mode_selector.dart` | 228 | Semantics(button:, label:) + Focus |
| `lib/components/environment_mode_chip.dart` | 21, 315 | Semantics + Focus on each chip |
| `lib/components/system_settings_section.dart` | 119 | Semantics + Focus on collapse toggle |
| `lib/components/sync_status_indicator.dart` | 41 | Semantics(button:, label: 'Refresh sync') + Focus |
| `lib/components/country_selector.dart` | 74 | InkWell replacement (already has ListTile pattern) |
| `lib/screens/auth/login.dart` | 595, 658 | Semantics(button:, label: 'Sign in') + Focus |
| `lib/screens/auth/registerForm.dart` | 396, 409, 427, 502 | 4 GestureDetectors → InkWell + Semantics |
| `lib/screens/auth/biometricLock.dart` | 141 | Semantics(button:, label: 'Unlock with biometrics') |
| `lib/screens/onboarding/countryMap.dart` | 94 | Map marker GestureDetectors → Semantics + Focus |
| `lib/screens/onboarding/onBoarding.dart` | 680 | Semantics + Focus |
| `lib/screens/password/PasswordScreen.dart` | 189 | Semantics(button:, label: password title) + Focus |
| `lib/screens/notes/NotesScreen.dart` | 334 | Semantics + Focus |
| `lib/screens/home/HomeScreen.dart` | 488 | Password detail close → AccessibleIconButton |
| `lib/screens/settings/components/profile_card.dart` | 27 | Semantics(button:, label: 'Edit profile photo') + Focus |
| `lib/screens/settings/SettingScreen.dart` | 455, 729 | Semantics + Focus on tap targets |
| `lib/screens/messages/ChatScreen.dart` | 590 | Long press → add Semantics(label: 'Message options') + Focus |
| `lib/features/ldap/widgets/ldap_selector.dart` | 226 | Semantics + Focus |
| `lib/components/ldap_selector.dart` | 226 | Semantics + Focus |
| `lib/components/import_passwords_dialog.dart` | 195 | Semantics + Focus |
| `lib/components/import_notes_dialog.dart` | 201 | Semantics + Focus |

---

### Phase 3: TextField labels (13 fixes)

Add `labelText` to 13 TextFields that use only `hintText`:

| File | Line | Field | labelText |
|------|------|-------|-----------|
| `lib/screens/home/HomeScreen.dart` | 690 | Search | 'Search' |
| `lib/screens/notes/EditNoteScreen.dart` | 276 | Title | 'Title' |
| `lib/screens/notes/NotesScreen.dart` | 314 | Search | 'Search' |
| `lib/screens/messages/ChatScreen.dart` | 635 | Message | 'Message' |
| `lib/screens/messages/MessagesScreen.dart` | 168 | Search | 'Search' |
| `lib/screens/otp/TOPT.dart` | 248 | Search | 'Search' |
| `lib/screens/password/PasswordScreen.dart` | 421 | Search | 'Search passwords' |
| `lib/screens/password/AutofillPickerScreen.dart` | 140 | Search | 'Search' |
| `lib/components/autofill_card.dart` | 271 | Search | 'Search' |
| `lib/components/password_generator_dialog.dart` | 123 | Password field | 'Generated password' |
| `lib/components/log_console_overlay.dart` | 204 | Filter | 'Filter logs' |
| `lib/components/country_selector.dart` | 336 | Search | 'Search countries' |
| `lib/screens/onboarding/onBoarding.dart` | 547 | Server URL | 'Server URL' |

---

### Phase 4: Image semantics (7 fixes)

| File | Line | Type | Action |
|------|------|------|--------|
| `lib/components/social_login_button.dart` | 37 | Image.asset (Google logo) | `semanticsLabel: 'Google'` |
| `lib/components/navigation.dart` | 395 | Image.asset (app logo in desktop nav) | `semanticsLabel: 'THiSECURE logo'` |
| `lib/components/auth_method_selector.dart` | 95 | Image.asset (Google icon) | `semanticsLabel: 'Sign in with Google'` |
| `lib/screens/splash/splash.dart` | 182 | Image.asset (app logo) | `semanticsLabel: 'THiSECURE'` |
| `lib/components/navigation.dart` | 225 | DecorationImage (background) | `ExcludeSemantics` (decorative) |
| `lib/screens/settings/components/profile_card.dart` | 40 | DecorationImage (avatar) | `semanticsLabel: 'Profile photo'` |

---

### Phase 5: ExcludeSemantics on decorative BackdropFilter (48 fixes)

Add `ExcludeSemantics(child: ...)` wrapper around all decorative `BackdropFilter` instances.

Affected files:
- `lib/components/background_orbs.dart` (1) — orbs are decorative
- `lib/components/liquid_glass.dart` (main wrapper) — parameterize ExcludeSemantics via optional param
- `lib/components/button.dart` (2) — glass effect backgrounds are decorative
- `lib/components/auth_method_selector.dart` (3)
- `lib/screens/auth/login.dart` (2)
- `lib/screens/auth/registerForm.dart` (2)
- `lib/screens/home/HomeScreen.dart` (5)
- `lib/screens/password/PasswordScreen.dart` (3)
- `lib/screens/notes/NotesScreen.dart` (3)
- `lib/screens/otp/TOPT.dart` (2)
- `lib/screens/settings/SettingScreen.dart` (2)
- All other BackdropFilter instances across the codebase

Best approach: Add optional `excludeSemantics` parameter to `LiquidGlassWidget` and set it to `true` by default for decorative uses.

---

### Phase 6: Reduced motion (1 task)

**6.1 Animations** — Create `a11y_animations.dart`:

```dart
// AnimatableBuilder: AnimationController wrapper that checks disableAnimations
class AnimatableBuilder extends StatelessWidget {
  // If reduced motion → completes instantly without animation
}
```

Update all files:
- `lib/components/animations/animated_widgets.dart` (7 classes):
  - `StaggeredAnimation` → check `disableAnimations`
  - `FadeSlideScaleAnimation` → instant completion if reduced
  - `PulseAnimation` → remove repeat if reduced
  - `ElasticScaleAnimation` → skip if reduced
  - `RotateAnimation` → skip repeat if reduced
  - `WaveAnimation` → skip if reduced
  - `ShimmerAnimation` → skip if reduced
- `lib/components/button.dart` → Skip expandable action button animations if reduced
- All `AnimatedBuilder` instances across components:
  - `deployment_mode_selector.dart` (2)
  - `account_type_selector.dart` (1)
  - `country_selector.dart` (1)
  - `ldap_selector.dart` (2)

---

### Phase 7: FAB + expansion button (2 fixes)

**7.1** `lib/components/log_console_overlay.dart:82` → FAB:
- Add `tooltip: 'Actions'`

**7.2** `lib/components/button.dart` ExpandableActionButton:
- Add `Semantics(button: true, label: 'Create new...', onTapHint: 'Expands to show create options')` on main toggle
- Fix Stack focus order: options should match visual order (top = first in widget tree, bottom = last)
- Focus first option when expanded (use `FocusScope.of(context).requestFocus(firstOptionFocusNode)`)
- Add `ExcludeSemantics` on rotated icon if decorative

---

### Phase 8: Screen semantics structure (46 Scaffolds across 25+ screens)

For every screen (`Scaffold` instance):

Widget template to add at the top of the body:
```dart
SemanticsScreenTitle(title: 'Screen Name'),
SemanticsHeading(label: 'Section Title'),
SkipLink(target: mainContentKey),
```

Then:
- Wrap decorative backgrounds in `ExcludeSemantics`
- Wrap section titles in `SemanticsHeading`
- Use `MergeSemantics` for compound items (e.g., password card with icon + title + subtitle should read as one unit)

Specific screen groups:

| Group | Screens | Key semantics |
|-------|---------|---------------|
| Auth (9) | login, register, forgotPassword, emailVerification, passwordResetVerification, serverConfig, biometricLock, biometricAuth, authSelection | ScreenTitle, heading on forms, error live regions, merge input+label |
| Home (3) | HomeScreen, password_item, note_item | ScreenTitle, section headings, MergeSemantics on list items |
| Password (4) | PasswordScreen, EditPasswordScreen, SavePasswordDialog, AutofillPickerScreen | ScreenTitle, field grouping with MergeSemantics, dialog focus trap |
| Notes (2) | NotesScreen, EditNoteScreen | ScreenTitle, heading, merge semantics on note items |
| OTP (2) | TOPT, OtpQrScannerScreen | ScreenTitle, QR code semantics (image → label), heading |
| Messages (2) | MessagesScreen, ChatScreen | ScreenTitle, message bubble merge semantics, input semantics |
| Settings (3) | SettingScreen, DebugScreen, LegalDocumentsScreen | ScreenTitle, section headings (AccessibleListTile), tabs semantics |
| Onboarding (3) | splash, onBoarding, countryMap | ScreenTitle, map marker semantics, heading on steps |
| Environment (2) | environment_list_screen, environment_add_screen | ScreenTitle, list item semantics |
| LDAP (3) | ldap_config_screen, ldap_selector, ldap_user_card | ScreenTitle, heading, list item semantics |
| Components (8) | autofill_card, country_selector, password_generator_dialog, import_passwords_dialog, import_notes_dialog, export_passwords_sheet, export_notes_sheet, system_settings_section, log_console_overlay | Dialog focus trap, accessible dropdown/selector, heading semantics |

---

### Phase 9: Focus management + keyboard shortcuts

**9.1 Global shortcuts** — `lib/main.dart`:

```dart
CallbackShortcuts(
  bindings: {
    SingleActivator(LogicalKeyboardKey.keyF, control: true): () => /* focus search */,
    SingleActivator(LogicalKeyboardKey.keyN, control: true): () => /* new item */,
    SingleActivator(LogicalKeyboardKey.escape): () => /* close dialog */,
    SingleActivator(LogicalKeyboardKey.comma, control: true): () => /* open settings */,
  },
  child: ...
)
```

Route-aware: Use `NavigatorObserver` subclass so shortcuts know which screen is active.

**9.2 Focus management per screen:**
- Login form: `FocusTraversalGroup` wrapping email → password → submit
- Register form: `FocusTraversalGroup` wrapping name → email → password → confirm → submit
- EditPassword: `FocusTraversalGroup` wrapping all fields
- EditNote: `FocusTraversalGroup` wrapping title → content
- All dialogs: `ModalFocusTrap` wrapping content, focus first element on open

**9.3 SkipLink:**
- First focusable element on scrollable screens (home, settings, password list, notes list)
- Visible on focus, hidden otherwise via `Offstage`

---

### Phase 10: Navigation semantics

**10.1** `lib/components/navigation.dart`:

```dart
// Bottom nav tab semantics
Semantics(
  selected: currentIndex == index,
  button: true,
  label: tabLabels[index],  // 'Home', 'Messages', 'OTP', 'Settings'
  child: GlassBottomBarTab(...)
)

// Sidebar item semantics
Semantics(
  selected: currentIndex == index,
  button: true,
  label: sidebarItemLabels[index],
  child: InkWell(...)
)
```

- Add `Offstage(maintainSemantics: false)` around non-active `IndexedStack` children to hide off-screen content
- Profile avatar: `Semantics(label: 'User profile', button: true, onTapHint: 'Open settings')`

---

### Phase 11: Error notifications + forms

**11.1** `lib/components/error_bar.dart`:

```dart
// Error snackbar
Semantics(
  liveRegion: 'polite',
  container: true,
  child: Row(
    children: [
      Semantics(label: 'Error:', child: Icon(Icons.error_outline)),
      Expanded(child: Text(message)),
      Semantics(button: true, label: 'Dismiss',
        child: IconButton(onPressed: onDismiss, icon: Icon(Icons.close))),
    ],
  ),
)
```

Same pattern for Success (label: 'Success:'), Info ('Info:'), Warning ('Warning:').

**11.2** Re-enable `showInfo()` in `error_bar.dart` — currently commented out.

**11.3** Add `GlobalKey<FormState>` to `password_generator_dialog.dart:81` Form widget.

---

### Phase 12: Contrast fixes

| File | Line | Current | Target |
|------|------|---------|--------|
| `lib/screens/home/HomeScreen.dart` | 978 | alpha 0.3 | alpha ≥0.55 |
| `lib/screens/otp/TOPT.dart` | 622 | alpha 0.3 | alpha ≥0.55 |
| `lib/components/liquid_glass.dart` | 844 | alpha 0.6 | alpha ≥0.65 |
| `lib/components/liquid_glass.dart` | 70 | alpha 0.5 (border) | alpha ≥0.6 |
| `lib/components/theme_selector.dart` | 102 | alpha 0.6 | alpha ≥0.7 |

All fixes validated with `a11y_theme.dart` → `validateContrast()`.

---

### Phase 13: Platform-specific + web

**13.1 Web:**
- `web/index.html`: `<html lang="en">`, `<meta name="description">`, reduced-motion CSS
- `web/manifest.json`: Fix description from 'A new Flutter project.' to 'THiSECURE - Secure password manager'

**13.2 iOS:**
- `ios/Runner/Info.plist`: No changes needed for WCAG A

**13.3 Android:**
- `android/app/src/main/AndroidManifest.xml`: Confirm `configChanges` includes all needed values (locale, layoutDirection, fontScale)

---

### Phase 14: Tests (2 tasks)

**14.1 Unit + widget tests:**
- `test/accessibility/a11y_widgets_test.dart` — semantics tree for each widget:
  - `AccessibleIconButton` → role=button, label=tooltip, minSize≥44×44
  - `AccessibleTextField` → role=textField, label=labelText
  - `SemanticsHeading` → header=true, label=label
  - `SemanticsScreenTitle` → label=title
  - `AccessibleDialog` → focus trapped inside
  - `AccessibleFab` → role=button, label=tooltip
- `test/accessibility/a11y_focus_test.dart`:
  - SkipLink → moves focus to target
  - ModalFocusTrap → Tab wraps, Escape closes
- `test/accessibility/a11y_animations_test.dart`:
  - With `disableAnimations: true` → animation completes immediately
  - With `disableAnimations: false` → animation plays normally
- `test/accessibility/a11y_theme_test.dart`:
  - `validateContrast()` returns correct results
  - Fixed colors all pass ≥4.5:1 ratio

**14.2 Screen-level semantics tests (5 files):**
- `test/accessibility/auth_semantics_test.dart`:
  - Login screen semantics tree contains: email field, password field, sign-in button with label
  - Tab order: email → password → sign in
- `test/accessibility/home_semantics_test.dart`:
  - Home screen has headings, search labeled, list items have semantics
- `test/accessibility/password_semantics_test.dart`:
  - EditPassword: all fields labeled, all buttons have tooltips
- `test/accessibility/notes_semantics_test.dart`:
  - EditNote: title and content fields labeled
- `test/accessibility/otp_semantics_test.dart`:
  - TOPT: heading, copy button, QR button all labeled

---

## Execution order

```
Phase 0 (module) ─────────────────────── starts first
│
├── Phase 1 (IconButton tooltips) ────── can start after 0.1
├── Phase 2 (GestureDetector keyboard)   can start after 0.1
├── Phase 3 (TextField labels) ───────── independent (no deps)
├── Phase 4 (Images) ─────────────────── independent
├── Phase 5 (ExcludeSemantics) ───────── can start after 0.1
├── Phase 6 (Reduced motion) ─────────── can start after 0.1
├── Phase 7 (FAB) ────────────────────── can start after 0.1
├── Phase 12 (Contrast) ──────────────── independent
└── Phase 13 (Platform) ──────────────── independent
                              
Phase 8 (Screen semantics) ──────────── after 1, 3, 4, 5
Phase 9 (Focus + keyboard) ──────────── after 0.1, 0.4
Phase 10 (Navigation) ───────────────── after 5, 8
Phase 11 (Errors/forms) ─────────────── after 0.1
Phase 14 (Tests) ────────────────────── after 1-13
```

## Suggested parallel batches:

**Batch A** (Phase 0 + what can run independently):
- 0.1 Module files
- 0.2 Lint rules
- 0.3 Web fixes
- 3 TextField labels
- 4 Image semantics
- 12 Contrast fixes
- 13 Platform

**Batch B** (depends on 0.1):
- 1 IconButton tooltips
- 2 GestureDetector keyboard
- 5 ExcludeSemantics
- 6 Reduced motion
- 7 FAB
- 11 Errors/forms

**Batch C** (depends on A+B):
- 8 Screen semantics
- 9 Focus + keyboard
- 10 Navigation

**Batch D** (after everything):
- 14 Tests

---

## Summary

| Phase | Tasks | Est. complexity | Dependencies |
|-------|-------|----------------|--------------|
| 0 — Module | 4 | Medium | — |
| 1 — IconButton tooltips | 1 (56 edits) | Medium | Phase 0 |
| 2 — GestureDetector keyboard | 1 (32 edits) | Large | Phase 0 |
| 3 — TextField labels | 1 (13 edits) | Small | — |
| 4 — Image semantics | 1 (6 edits) | Small | — |
| 5 — ExcludeSemantics | 1 (48 edits) | Small | Phase 0 |
| 6 — Reduced motion | 1 (15+ edits) | Medium | Phase 0 |
| 7 — FAB | 1 (2 edits) | Small | Phase 0 |
| 8 — Screen semantics | 1 (46 Scaffolds) | Large | Phases 1,3,4,5 |
| 9 — Focus + keyboard | 1 | Medium | Phase 0 |
| 10 — Navigation | 1 | Medium | Phases 5,8 |
| 11 — Errors/forms | 1 | Small | Phase 0 |
| 12 — Contrast | 1 (5 edits) | Small | — |
| 13 — Platform | 1 (3 edits) | Small | — |
| 14 — Tests | 2 (10 test files) | Medium | Everything |
| **Total** | **19 tasks** | | |

## Verification

1. `flutter test` — all tests pass
2. `flutter analyze` — no new warnings
3. Keyboard manual test: Tab through entire flow, Enter/Space activate, Escape closes dialogs
4. VoiceOver (macOS/iOS) test: all interactive elements readable
5. `MediaQuery.disableAnimations == true` → animations skip
6. All contrast ratios ≥4.5:1
