# WCAG A Accessibility Implementation — Design Spec

## Overview

Achieve WCAG 2.2 Level A compliance for the THiSECURE Flutter client.

## Current state (audited 2026-06-28)

| Metric | Count | Severity |
|--------|-------|----------|
| `Semantics` widget usage | **0** | HIGH |
| `ExcludeSemantics` usage | **0** | MEDIUM |
| IconButton without tooltip | **56/61 (92%)** | HIGH |
| GestureDetector without keyboard alt | **32/32 (100%)** | HIGH |
| TextField without labelText | **13/47 (28%)** | MEDIUM |
| Images without semanticsLabel | **7/7 (100%)** | HIGH |
| Animation without reduced-motion check | **7 classes + 18 controllers (100%)** | HIGH |
| BackdropFilter without ExcludeSemantics | **48/48 (100%)** | MEDIUM |
| MediaQuery accessibility properties | **0/11 queries** | HIGH |
| FAB without tooltip | **1/1 (100%)** | MEDIUM |
| FocusTraversalGroup/FocusOrder | **0** | LOW |
| Shortcuts/Actions widgets | **0** | MEDIUM |
| A11y lint rules | **0** | MEDIUM |
| A11y dependencies | **0** | MEDIUM |
| `<html lang>` in web/index.html | **missing** | MEDIUM |

## Target Conformance

**WCAG 2.2 Level A** — covering:

| SC | Criterion | Flutter translation |
|----|-----------|-------------------|
| 1.1.1 | Non-text Content | tooltips, semanticsLabel, ExcludeSemantics on decorations |
| 1.3.1 | Info and Relationships | Semantics(heading:), Semantics(header:), roles |
| 1.4.1 | Use of Color | Semantics labels not relying solely on color |
| 2.1.1 | Keyboard | Focus, onKeyEvent, Shortcuts on all interactive elements |
| 2.1.2 | No Keyboard Trap | FocusTraversalGroup, focus wrap in dialogs |
| 2.4.1 | Bypass Blocks | SkipLink widget before main content |
| 2.4.2 | Page Titled | SemanticsScreenTitle on every screen |
| 2.4.3 | Focus Order | FocusOrder, traversal order matching visual |
| 3.1.1 | Language of Page | html lang, MaterialApp.locale |
| 3.3.1 | Error Identification | Form errors announced via Semantics(liveRegion:) |
| 3.3.2 | Labels or Instructions | Every TextField has labelText or semanticsLabel |
| 4.1.2 | Name, Role, Value | Complete Semantics tree on all interactive widgets |

---

## Architecture: `lib/accessibility/` module

```
lib/accessibility/
├── a11y_constants.dart          # minTouchTarget(44), minSpacing, reduced durations
├── a11y_widgets.dart            # AccessibleIconButton, AccessibleTextField, AccessibleListTile,
│                                # AccessibleFab, SemanticsHeading, SemanticsScreenTitle,
│                                # AccessibleDialog, SemanticsIcon, AccessibleFormField
├── a11y_theme.dart              # Contrast-verified colors, a11yOverrideTheme
├── a11y_focus.dart              # ExplicitFocusOrder, SkipLink, ModalFocusTrap, KeyboardShortcut,
│                                # GlobalShortcuts widget, AccessibleNavObserver
├── a11y_extensions.dart         # BuildContext extensions for a11y features
├── a11y_animations.dart         # AnimatableBuilder (reduced-motion aware), useReducedMotion hook
├── a11y_test_utils.dart         # semanticsExpectButton, semanticsExpectTextField, etc.
└── a11y_semantics.dart          # SemanticsConfig (global merge/exclude utilities)
```

### Widget contract

| Widget | Required params | Enforced at | WCAG SC |
|--------|---------------|-------------|---------|
| `AccessibleIconButton` | `tooltip` (non-null String) | Compile time | 1.1.1, 4.1.2 |
| `AccessibleTextField` | `label` (non-null String) | Compile time | 1.3.1, 3.3.2 |
| `AccessibleListTile` | `semanticLabel` (auto from title) | Runtime | 4.1.2 |
| `AccessibleFab` | `tooltip` (non-null String) | Compile time | 1.1.1, 4.1.2 |
| `SemanticsHeading` | `label` (non-null String) | Compile time | 1.3.1 |
| `SemanticsScreenTitle` | `title` (non-null String) | Compile time | 2.4.2 |
| `AccessibleDialog` | n/a (wraps showDialog) | Runtime | 2.1.2 |
| `SemanticsIcon` | `label` (non-null String) | Compile time | 1.1.1, 4.1.2 |

All icon/image-only widgets make `tooltip`/`semanticsLabel` **required**, preventing omission at compile time.

---

## Phase breakdown

### Phase 0: Module + infrastructure (4 tasks)

**0.1** Create all `lib/accessibility/` source files (8 files)
**0.2** Add a11y lint rules to `analysis_options.yaml`:
  - `use_key_in_widget_constructors`
  - `avoid_redundant_accessibility_labels` (consider adding)
  - Custom lint rules if needed
**0.3** Add web fix: `<html lang="en">` in `web/index.html`
**0.4** Write unit + widget tests for all a11y widgets

### Phase 1: IconButton tooltips (1 task)

**1.1** Replace all 56 bare IconButtons with `AccessibleIconButton`, providing translated tooltips:
  - `GlobalActions.dart` (2) → copy, paste
  - `ldap_user_card.dart` (1) → logout
  - `system_settings_section.dart` (1) → settings
  - `autofill_card.dart` (1) → card actions
  - `password_generator_dialog.dart` (3) → copy, regenerate, close
  - `log_console_overlay.dart` (3) → clear, copy, close
  - `country_selector.dart` (1) → search
  - `logs_screen.dart` (3) → copy, clear, refresh
  - `countryMap.dart` (1) → close
  - `PasswordScreen.dart` (6) → copy username, copy password, show, edit, delete, add
  - `AutofillPickerScreen.dart` (1) → close
  - `SavePasswordDialog.dart` (1) → close
  - `EditPasswordScreen.dart` (2) → copy, show password
  - `EditNoteScreen.dart` (2) → save, close
  - `environment_list_screen.dart` (2) → add, delete
  - `environment_add_screen.dart` (1) → back
  - `OtpQrScannerScreen.dart` (2) → close, scan
  - `TOPT.dart` (3) → copy, show QR, options
  - `SettingScreen.dart` (2) → profile, logout
  - `loginForm.dart` / `login.dart` (2) → show password, server config
  - `registerForm.dart` (2) → show password, show confirm password
  - `passwordResetVerification.dart` (2) → back, resend
  - `forgotPassword.dart` (1) → back
  - `emailVerification.dart` (1) → resend
  - `server_config_screen.dart` (1) → back
  - `password_item.dart` (2) → copy password, options
  - `note_item.dart` (1) → options
  - `HomeScreen.dart` (4) → search, add, filter, close
  - `ChatScreen.dart` (2) → send, attach
  - `MessagesScreen.dart` (1) → new message
  - `NotesScreen.dart` (1) → add note

### Phase 2: GestureDetector → keyboard accessible (1 task)

**2.1** Wrap all 32 GestureDetector instances:
  - Add `FocusNode` + `onKeyEvent` for Enter/Space activation
  - OR replace with `InkWell` + `Semantics(button:)` where appropriate
  - OR wrap in `Semantics(button: true, label: ..., onTapHint: ...)`

  Key files: `social_login_button.dart`, `auth_method_selector.dart`, `account_type_selector.dart`, `deployment_mode_selector.dart`, `environment_mode_chip.dart`, `system_settings_section.dart`, `sync_status_indicator.dart`, `country_selector.dart` (tap trigger), `login.dart` (login button area), `registerForm.dart` (4 GestureDetectors), `biometricLock.dart`, `onboarding/countryMap.dart` (markers), `onBoarding.dart`, `PasswordScreen.dart`, `NotesScreen.dart`, `HomeScreen.dart`, `profile_card.dart`, `SettingScreen.dart`, `ChatScreen.dart`, `ldap_selector.dart`, `import_passwords_dialog.dart`, `import_notes_dialog.dart`

### Phase 3: TextField labels (1 task)

**3.1** Add `labelText` or `semanticsLabel` to 13 TextFields that currently use only `hintText`:
  - `HomeScreen.dart:690` → Search bar → `labelText: 'Search'` with `hintText` preserved
  - `EditNoteScreen.dart:276` → Title field → `labelText: 'Title'`
  - `NotesScreen.dart:314` → Search → `labelText: 'Search'`
  - `ChatScreen.dart:635` → Message input → `labelText: 'Message'`
  - `MessagesScreen.dart:168` → Search → `labelText: 'Search'`
  - `TOPT.dart:248` → Search → `labelText: 'Search'`
  - `PasswordScreen.dart:421` → Search → `labelText: 'Search'`
  - `AutofillPickerScreen.dart:140` → Search → `labelText: 'Search'`
  - `autofill_card.dart:271` → Search → `labelText: 'Search'`
  - `password_generator_dialog.dart:123` → Read-only field → `labelText: 'Generated password'`
  - `log_console_overlay.dart:204` → Filter → `labelText: 'Filter'`
  - `country_selector.dart:336` → Search → `labelText: 'Search'`
  - `onBoarding.dart:547` → Server URL → `labelText: 'Server URL'`

### Phase 4: Images semantics (1 task)

**4.1** Add `semanticsLabel` or `excludeFromSemantics` to all 7 Image instances:
  - `social_login_button.dart:37` → `Image.asset` → `semanticsLabel: 'Google'`
  - `navigation.dart:395` → `Image.asset` (logo) → `semanticsLabel: 'THiSECURE logo'`
  - `auth_method_selector.dart:95` → `Image.asset` → `semanticsLabel: 'Google'`
  - `splash.dart:182` → `Image.asset` (logo) → `semanticsLabel: 'THiSECURE'`
  - `navigation.dart:225` → `DecorationImage` → wrap in `ExcludeSemantics` if decorative
  - `profile_card.dart:40` → `DecorationImage` → `semanticsLabel: 'Profile photo'`

### Phase 5: ExcludeSemantics on decorative elements (1 task)

**5.1** Wrap all 48 BackdropFilter instances in `ExcludeSemantics(child: BackdropFilter(...))`:
  - `background_orbs.dart:68` → decorative background blur
  - `liquid_glass.dart:14` → glass effect wrapper (parameterize ExcludeSemantics)
  - `privacy_overlay.dart:57` → keep as is (privacy blur is content, not decorative)
  - `button.dart:108,202` → glass button backgrounds
  - `auth_method_selector.dart:83,121,168` → auth option backgrounds
  - `login.dart:293,363` → decorative background + form glass
  - `registerForm.dart:180,273` → same
  - `HomeScreen.dart:329,392,681,906,969` → dialogs and search backgrounds
  - `PasswordScreen.dart:100,411,474` → dialogs and search
  - `NotesScreen.dart:105,297,482` → dialogs
  - All other BackdropFilter locations

### Phase 6: Reduced motion (1 task)

**6.1** Add `disableAnimations` respect to all animation widgets:
  - Create `a11y_animations.dart` with `AnimatableBuilder` (wraps AnimationController; auto-pauses if `MediaQuery.disableAnimations`)
  - Update all 7 classes in `lib/components/animations/animated_widgets.dart`:
    - `StaggeredAnimation` → check `disableAnimations`
    - `FadeSlideScaleAnimation` → check `disableAnimations`
    - `PulseAnimation` → if disabled animations, skip repeat
    - `ElasticScaleAnimation` → skip if disabled
    - `RotateAnimation` → skip if disabled
    - `WaveAnimation` → skip if disabled
    - `ShimmerAnimation` → skip if disabled
  - Update `button.dart` expandable action button animations
  - Update all 11 `AnimatedBuilder` instances in components
  - Add `prefers-reduced-motion` CSS in `web/index.html`

### Phase 7: FloatingActionButton + Expansion button (1 task)

**7.1** Fix FAB and expandable action button:
  - `log_console_overlay.dart:82` → add `tooltip: 'Actions'`
  - `button.dart` ExpandableActionButton:
    - Add `Semantics(button:)` on main toggle
    - Add `tooltip` / `semanticsLabel` ("Create new...")
    - Fix Stack focus order: options should focus in visual order (top-to-bottom, not widget tree bottom-to-top)
    - Focus first option when expanded

### Phase 8: Screen semantics structure (1 task)

**8.1** Add Semantics structure to every screen:
  - `SemanticsScreenTitle` at top of each Scaffold/screen
  - `SemanticsHeading` for each section title
  - `ExcludeSemantics` on decorative backgrounds/icons
  - Screen-level `semanticsLabel` where needed
  - Route title announcements via `NavigatorObserver`

Screens to cover (46 Scaffold instances):
  - Auth: login, register, forgotPassword, emailVerification, passwordResetVerification, serverConfig, biometricLock, biometricAuth, authSelection
  - Home: HomeScreen, password_item, note_item
  - Password: PasswordScreen, EditPasswordScreen, SavePasswordDialog, AutofillPickerScreen
  - Notes: NotesScreen, EditNoteScreen
  - OTP: TOPT, OtpQrScannerScreen
  - Messages: MessagesScreen, ChatScreen
  - Settings: SettingScreen, DebugScreen, LegalDocumentsScreen
  - Onboarding: splash, onBoarding, countryMap
  - Environment: environment_list_screen, environment_add_screen
  - LDAP: ldap_config_screen, ldap_selector, ldap_user_card
  - Components: autofill_card, country_selector, password_generator_dialog, import_passwords_dialog, import_notes_dialog, export_passwords_sheet, export_notes_sheet, system_settings_section, log_console_overlay

### Phase 9: Focus management + keyboard navigation (1 task)

**9.1** Implement focus management:
  - `GlobalShortcuts` in `main.dart` wrapped in `CallbackShortcuts`:
    - `Ctrl/Cmd+F` → focus search (route-aware)
    - `Ctrl/Cmd+N` → new item
    - `Escape` → close dialog/go back
    - `Ctrl/Cmd+,` → settings
  - `ModalFocusTrap` in `AccessibleDialog`
  - `ExplicitFocusOrder` on forms (login, register, editPassword, editNote)
  - `FocusTraversalGroup` + `TraversalOrder` on complex screens
  - `SkipLink` as first focusable element on scrollable screens

### Phase 10: Navigation semantics (1 task)

**10.1** Fix bottom nav + sidebar accessibility:
  - `navigation.dart`:
    - Wrap `IndexedStack` in `Offstage`/`Visibility` with `maintainSemantics: false` for inactive pages
    - Add `Semantics(selected: true/false, container: true)` on nav tabs
    - Add `accessibilityLabel` on `GlassBottomBarTab` via `semanticsLabel`
    - Sidebar items: `Semantics(selected: true/false, button: true, label: 'tab name')`
    - Profile avatar: `semanticsLabel: 'User profile'` + button role

### Phase 11: Error notifications + forms (1 task)

**11.1** Make error/success/info/warning snackbars accessible:
  - `error_bar.dart`:
    - Wrap icon in `Semantics(label: 'Error:')`, `'Success:'`, `'Info:'`, `'Warning:'`
    - Add close/dismiss button with tooltip
    - Add `Semantics(liveRegion: 'polite')` on snackbar content
    - Re-enable `showInfo()` body
    - Add `onDismiss` callback wiring
  - `password_generator_dialog.dart:81` → add `GlobalKey<FormState>` to Form widget

### Phase 12: Contrast fixes (1 task)

**12.1** Fix all confirmed contrast failures:
  - `HomeScreen.dart:978` → alpha 0.3 on dark bg → increase to ≥0.55
  - `TOPT.dart:622` → alpha 0.3 → increase to ≥0.55
  - `liquid_glass.dart:844` → alpha 0.6 → bump to ≥0.65
  - `liquid_glass.dart:70` → alpha 0.5 border → bump to ≥0.6
  - `theme_selector.dart:102` → alpha 0.6 → bump to ≥0.7
  - Fix error_bar.dart gradient text contrast verification

### Phase 13: Platform-specific + web (1 task)

**13.1** Platform accessibility:
  - `web/index.html`: Add `<html lang="en">`, `<meta name="description">`, reduced-motion CSS
  - `web/manifest.json`: Update description from placeholder
  - `ios/Runner/Info.plist`: Add `UIAccessibility` keys if needed
  - `android/app/src/main/AndroidManifest.xml`: Add accessibility service configuration

### Phase 14: Tests (2 tasks)

**14.1** Widget tests for a11y components:
  - `test/accessibility/a11y_widgets_test.dart`
  - `test/accessibility/a11y_focus_test.dart`
  - `test/accessibility/a11y_theme_test.dart`
  - `test/accessibility/a11y_animations_test.dart`
  - `test/accessibility/a11y_extensions_test.dart`

**14.2** Screen-level semantics tests:
  - `test/accessibility/auth_semantics_test.dart`
  - `test/accessibility/home_semantics_test.dart`
  - `test/accessibility/password_semantics_test.dart`
  - `test/accessibility/notes_semantics_test.dart`
  - `test/accessibility/otp_semantics_test.dart`

---

## Dependency graph

```
Phase 0 (module) ─┬─ Phase 1 (IconButton tooltips)
                   ├─ Phase 2 (GestureDetector keyboard)
                   ├─ Phase 3 (TextField labels)
                   ├─ Phase 4 (Images semantics)
                   ├─ Phase 5 (ExcludeSemantics decorative)
                   ├─ Phase 6 (Reduced motion)
                   ├─ Phase 7 (FAB/expansion button)
                   ├─ Phase 8 (Screen semantics) ── depends on 1-5
                   ├─ Phase 9 (Focus + keyboard) ── depends on 0
                   ├─ Phase 10 (Navigation semantics) ── depends on 5, 8
                   ├─ Phase 11 (Error notifications) ── depends on 0
                   ├─ Phase 12 (Contrast) ── independent
                   ├─ Phase 13 (Platform web) ── independent
                   └─ Phase 14 (Tests) ── depends on 1-13
```

Phases 0-7 and 12-13 can run **in parallel** after Phase 0. Phases 8-11 depend on earlier phases. Phase 14 blocks on everything.

## Verification checklist

- [ ] `flutter test` — all 100+ tests pass
- [ ] `flutter analyze` — no new warnings
- [ ] Manual keyboard tab through auth → home → password → notes → OTP → settings
- [ ] Every interactive element reachable with Tab
- [ ] No keyboard traps in dialogs
- [ ] VoiceOver/TalkBack reads all labels correctly
- [ ] All 48 BackdropFilter wrapped in ExcludeSemantics
- [ ] All 7 images have semanticsLabel or excludeFromSemantics
- [ ] All 56+ IconButtons have tooltips
- [ ] All 32 GestureDetectors have keyboard alternatives
- [ ] All 13 TextFields have labels
- [ ] Animations respect `prefers-reduced-motion`
- [ ] 200% zoom (web) — content still usable
