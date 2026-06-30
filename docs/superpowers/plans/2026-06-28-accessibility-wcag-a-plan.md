# WCAG A Accessibility Implementation Plan

## Metadata

- **Spec:** `docs/superpowers/specs/2026-06-28-accessibility-wcag-a-design.md`
- **Target:** WCAG 2.2 Level A
- **Approach:** Semantics-first with reusable `lib/accessibility/` module
- **Total screens to migrate:** ~30 files in `lib/`
- **Tests:** Unit + widget + integration semantics tests

---

## Task breakdown

### Phase 0: Module setup (3 tasks)

| # | Task | Files | Est. time |
|---|------|-------|-----------|
| 0.1 | Create `lib/accessibility/` with all source files and barrel export | `a11y_constants.dart`, `a11y_widgets.dart`, `a11y_theme.dart`, `a11y_focus.dart`, `a11y_extensions.dart`, `a11y_test_utils.dart` | Medium |
| 0.2 | Add `a11y_test_utils.dart` test helpers | `lib/accessibility/a11y_test_utils.dart` | Medium |
| 0.3 | Write unit + widget tests for all a11y widgets | `test/accessibility/a11y_widgets_test.dart`, `test/accessibility/a11y_theme_test.dart`, `test/accessibility/a11y_constants_test.dart` | Medium |

**Checkpoint:** `flutter test test/accessibility/` passes.

---

### Phase 1: Contrast + Theme fixes (1 task)

| # | Task | Files | Est. time |
|---|------|-------|-----------|
| 1.1 | Fix all confirmed contrast failures (HomeScreen, TOPT, liquid_glass, theme_selector) | `lib/core/app_theme.dart`, `lib/core/app_colors.dart`, `lib/core/theme_provider.dart` | Small |

**Checkpoint:** All color values verified ≥4.5:1 ratio.

---

### Phase 2: Auth screens (5 tasks)

| # | Task | Files | Est. time |
|---|------|-------|-----------|
| 2.1 | `login.dart` + `loginForm.dart` — TextField labels, accessible visibility toggle, skip link, error announcements, heading semantics | `lib/screens/auth/login.dart`, `lib/screens/auth/loginForm.dart` | Medium |
| 2.2 | `registerForm.dart` — labels, accessible icon buttons, error validation semantics | `lib/screens/auth/registerForm.dart` | Medium |
| 2.3 | `forgotPassword.dart` — labels, accessible back button | `lib/screens/auth/forgotPassword.dart` | Small |
| 2.4 | `emailVerification.dart`, `passwordResetVerification.dart` — accessible resend, code input labels | `lib/screens/auth/emailVerification.dart`, `lib/screens/auth/passwordResetVerification.dart` | Medium |
| 2.5 | `server_config_screen.dart` — labels, accessible buttons | `lib/screens/auth/server_config_screen.dart` | Small |

**Checkpoint:** Auth flow fully navigable by keyboard + screen reader.

---

### Phase 3: Home screen (2 tasks)

| # | Task | Files | Est. time |
|---|------|-------|-----------|
| 3.1 | `HomeScreen.dart` — tooltips on all FAB/IconButtons, section headings, skip link, list item semantics | `lib/screens/home/HomeScreen.dart` | Medium |
| 3.2 | `password_item.dart`, `note_item.dart` — accessible copy/view/delete/edit buttons | `lib/screens/home/components/password_item.dart`, `lib/screens/home/components/note_item.dart` | Small |

**Checkpoint:** Home screen fully accessible.

---

### Phase 4: Password screens (3 tasks)

| # | Task | Files | Est. time |
|---|------|-------|-----------|
| 4.1 | `PasswordScreen.dart` — tooltips on all actions, search label, list item semantics | `lib/screens/password/PasswordScreen.dart` | Medium |
| 4.2 | `EditPasswordScreen.dart` — field labels, accessible show-password toggle, focus chain | `lib/screens/password/EditPasswordScreen.dart` | Medium |
| 4.3 | `SavePasswordDialog.dart`, `AutofillPickerScreen.dart` — accessible dialog focus trap, list semantics | `lib/screens/password/SavePasswordDialog.dart`, `lib/screens/password/AutofillPickerScreen.dart` | Small |

**Checkpoint:** Password CRUD fully accessible.

---

### Phase 5: Notes screens (2 tasks)

| # | Task | Files | Est. time |
|---|------|-------|-----------|
| 5.1 | `NotesScreen.dart` — tooltips, list item semantics | `lib/screens/notes/NotesScreen.dart` | Small |
| 5.2 | `EditNoteScreen.dart` — labels on title/content, accessible save/close buttons | `lib/screens/notes/EditNoteScreen.dart` | Medium |

**Checkpoint:** Notes CRUD fully accessible.

---

### Phase 6: OTP screens (2 tasks)

| # | Task | Files | Est. time |
|---|------|-------|-----------|
| 6.1 | `TOPT.dart` — tooltips on all icon buttons, heading semantics, accessible copy/show/hide QR | `lib/screens/otp/TOPT.dart` | Medium |
| 6.2 | `OtpQrScannerScreen.dart` — scanner accessible labels, close button tooltip | `lib/screens/otp/OtpQrScannerScreen.dart` | Small |

**Checkpoint:** OTP screens fully accessible.

---

### Phase 7: Messages screens (2 tasks)

| # | Task | Files | Est. time |
|---|------|-------|-----------|
| 7.1 | `MessagesScreen.dart` — accessible list items, new message button tooltip | `lib/screens/messages/MessagesScreen.dart` | Small |
| 7.2 | `ChatScreen.dart` — send button tooltip, input label, message bubble semantics | `lib/screens/messages/ChatScreen.dart` | Medium |

**Checkpoint:** Messages screens fully accessible.

---

### Phase 8: Settings screens (1 task)

| # | Task | Files | Est. time |
|---|------|-------|-----------|
| 8.1 | `SettingScreen.dart` — labels on all settings, accessible toggle switches, section headings | `lib/screens/settings/SettingScreen.dart` | Medium |

**Checkpoint:** Settings screen fully accessible.

---

### Phase 9: Other screens (2 tasks)

| # | Task | Files | Est. time |
|---|------|-------|-----------|
| 9.1 | `SplashScreen.dart`, onboarding screens, environment screens — Semantics labels, tooltips, headings | `lib/screens/splash/splashscreen.dart`, `lib/screens/onboarding/`, `lib/screens/environments/` | Medium |
| 9.2 | Debug screens, components (error_bar, log_console, country_selector, password_generator, system_settings_section, theme_selector, AutofillCard) — ensure all icon tooltips and labels | `lib/screens/debug/`, `lib/components/*` | Medium |

**Checkpoint:** All remaining screens covered.

---

### Phase 10: Keyboard shortcuts (1 task)

| # | Task | Files | Est. time |
|---|------|-------|-----------|
| 10.1 | Add `CallbackShortcuts` at MaterialApp level, per-screen contextual shortcuts; wire Escape → close, Ctrl+N → new item, etc. | `lib/main.dart`, `lib/accessibility/a11y_focus.dart` | Medium |

**Checkpoint:** Global + per-screen keyboard shortcuts working.

---

### Phase 11: Integration tests (1 task)

| # | Task | Files | Est. time |
|---|------|-------|-----------|
| 11.1 | Write integration tests for auth flow and password CRUD verifying semantics tree | `test/accessibility/auth_accessibility_test.dart`, `test/accessibility/password_accessibility_test.dart` | Medium |

**Checkpoint:** `flutter test` passes at 100%.

---

## Summary

| Phase | Tasks | Estimate |
|-------|-------|----------|
| 0 — Module setup | 3 | Medium |
| 1 — Contrast fixes | 1 | Small |
| 2 — Auth | 5 | Medium |
| 3 — Home | 2 | Medium |
| 4 — Password | 3 | Medium |
| 5 — Notes | 2 | Medium |
| 6 — OTP | 2 | Medium |
| 7 — Messages | 2 | Medium |
| 8 — Settings | 1 | Medium |
| 9 — Other | 2 | Medium |
| 10 — Keyboard | 1 | Medium |
| 11 — Tests | 1 | Medium |
| **Total** | **25 tasks** | |

## Dependencies

- Phase 0 must precede all others (widgets need to exist first)
- Phase 1 can run in parallel with Phase 0
- Phases 2–9 are independent of each other; any order works
- Phase 10 depends on Phase 0 (a11y_focus.dart)
- Phase 11 depends on Phases 2–4 being complete

## Verification

After all phases are complete:

1. `flutter test` — all existing + new tests pass
2. `flutter analyze` — no new warnings
3. Manual keyboard tab through entire auth → home → password → notes flow
4. Screen reader test: VoiceOver (macOS/iOS) or TalkBack (Android) reads all elements correctly
