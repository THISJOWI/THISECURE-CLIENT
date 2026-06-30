# WCAG A Accessibility Implementation — Design Spec

## Overview

Achieve WCAG 2.2 Level A compliance for the THiSECURE Flutter client. The app currently has zero accessibility infrastructure: no `Semantics` widgets, 86% of `IconButton` instances lack tooltips, no keyboard shortcuts, no accessibility tests, and confirmed contrast failures.

## Target Conformance Level

**WCAG 2.2 Level A** — minimum accessibility, covering:
- 1.1.1 Non-text Content (icons need accessible names)
- 1.3.1 Info and Relationships (semantic structure)
- 1.4.1 Use of Color (don't rely solely on color)
- 2.1.1 Keyboard (all functionality keyboard-accessible)
- 2.1.2 No Keyboard Trap
- 2.4.1 Bypass Blocks (skip links)
- 2.4.2 Page Titled (screen titles)
- 2.4.3 Focus Order (logical tab order)
- 3.1.1 Language of Page (html lang, MaterialApp locale)
- 3.3.1 Error Identification (form errors announced)
- 3.3.2 Labels or Instructions (every TextField has a label)
- 4.1.2 Name, Role, Value (Semantics tree)

## Approach: Semantics-first with reusable components

Create `lib/accessibility/` module with reusable accessible widgets, then migrate all screens to use them.

---

## Section 1: Accessibility Module — `lib/accessibility/`

### 1.1 `a11y_constants.dart`

- `minTouchTarget = 44.0` (recommended mobile target; WCAG minimum is 24×24)
- `minInteractiveSpacing = 8.0`
- `reducedAnimationDuration = Duration(milliseconds: 1)`
- `defaultTooltipFontSize = 14.0`

### 1.2 `a11y_widgets.dart`

| Widget | Purpose |
|--------|---------|
| `AccessibleIconButton` | Wraps `IconButton`; **requires** `tooltip` parameter; enforces 44×44 via `BoxConstraints` |
| `AccessibleTextField` | Wraps `TextField`; **requires** `label`; auto-sets `semanticsLabel`; integrates error announcement via `Semantics` |
| `AccessibleListTile` | Wraps `ListTile`; auto-sets `semanticsLabel` based on title/subtitle |
| `SemanticsHeading` | Wraps content with `Semantics(header: true, child: ...)` |
| `SemanticsScreenTitle` | Announces screen title on route change via `Semantics(label: ..., liveRegion: true)` as the first focusable element |
| `AccessibleDialog` | Wraps `AlertDialog`; implements focus trap; Tab wraps between first/last element; Escape closes |
| `AccessibleFab` | Replaces raw `FloatingActionButton`; **requires** `tooltip`; 44×44 minimum |

**Principle:** All constructors make `tooltip`/`label` required (non-nullable), so omission is a compile error.

### 1.3 `a11y_theme.dart`

- Validates contrast ratios at build time
- `validateContrast(Color fg, Color bg) → bool` — returns `true` if ≥4.5:1
- Overrides `AppColors` where existing colors fail WCAG AA
- Provides `a11yLightTheme` and `a11yDarkTheme` extending current theme with contrast fixes

### 1.4 `a11y_focus.dart`

- `ExplicitFocusOrder` widget — sets `TraversalOrder` to enforce logical focus flow
- `SkipLink(String label, VoidCallback onTap)` — first focusable element in every screen, triggers scrollTo
- `KeyboardShortcut` — wrapper for `CallbackShortcuts` + `Shortcuts` with i18n-aware key bindings
- `ModalFocusTrap` — ensures focus wraps inside modals, applied in `AccessibleDialog`

### 1.5 `a11y_extensions.dart`

```dart
extension A11yBuildContext on BuildContext {
  bool get isScreenReaderActive => MediaQuery.of(this).accessibleNavigation;
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;
  bool get highContrast => MediaQuery.of(this).highContrast;
}
```

### 1.6 `a11y_test_utils.dart`

```dart
void semanticsExpectButton(WidgetTester tester, {required String label});
void semanticsExpectTextField(WidgetTester tester, {required String label});
void semanticsExpectHeading(WidgetTester tester, {required String label});
void expectContrastRatio(Color fg, Color bg, {double minRatio = 4.5});
void semanticsExpectSemanticsTree(WidgetTester tester, {required List<SemanticsNode> expected});
```

---

## Section 2: Screen Migration

### 2.1 Auth screens

| Screen | Key changes |
|--------|-------------|
| `login.dart`, `loginForm.dart` | Labels on all TextFields, `AccessibleIconButton` for visibility toggle, skip link, SemanticsHeading on title, error announcements |
| `registerForm.dart` | Labels, accessible icon buttons, error announcements on validation |
| `forgotPassword.dart` | Labels, accessible back button |
| `emailVerification.dart` | Accessible resend button, code input labels |
| `passwordResetVerification.dart` | Labels, accessible inputs |

### 2.2 Home screens

| Screen | Key changes |
|--------|-------------|
| `HomeScreen.dart` | Tooltips on all FAB/IconButtons, SemanticsHeading on sections, AccessibleListTile for items, skip link |
| `password_item.dart` | Accessible copy/view/delete buttons, Semantics label for each item |
| `note_item.dart` | Accessible edit/delete buttons |

### 2.3 Password screens

| Screen | Key changes |
|--------|-------------|
| `PasswordScreen.dart` | Tooltips on all actions, search field label, list items with semantic roles |
| `EditPasswordScreen.dart` | Labels on all fields, accessible show-password toggle, keyboard focus chain |
| `SavePasswordDialog.dart` | Accessible dialog, focus trap |

### 2.4 Notes screens

| Screen | Key changes |
|--------|-------------|
| `NotesScreen.dart` | Tooltips, list item semantics |
| `EditNoteScreen.dart` | Labels on title/content editors, accessible save/close buttons |

### 2.5 OTP screens

| Screen | Key changes |
|--------|-------------|
| `TOPT.dart` | Tooltips on all icon buttons, heading semantics, accessible copy/show/hide QR |
| `OtpQrScannerScreen.dart` | Scanner accessible labels, close button tooltip |

### 2.6 Messages screens

| Screen | Key changes |
|--------|-------------|
| `MessagesScreen.dart` | Accessible list items, new message button tooltip |
| `ChatScreen.dart` | Send button tooltip, input label, message bubble semantics |

### 2.7 Settings screens

| Screen | Key changes |
|--------|-------------|
| `SettingScreen.dart` | Labels on all settings, accessible toggle switches, sections as headings |

### 2.8 Other screens

| Screen | Key changes |
|--------|-------------|
| `SplashScreen.dart` | Semantics label on app logo/name |
| Debug/log screens | Tooltips already done; ensure remaining icons are covered |
| Environment screens | List items semantics, tooltips on actions |
| Onboarding screens | All icon buttons accessible, heading semantics |

---

## Section 3: Contrast fixes

Based on UI audit findings:

| Location | Current alpha | Fix |
|----------|--------------|-----|
| `HomeScreen.dart:978` — 0.3 alpha on dark bg | Fails AA | Increase to ≥0.55 (or use `AppColors` with verified ratio) |
| `TOPT.dart:622` — 0.3 alpha | Fails AA | Increase to ≥0.55 |
| `liquid_glass.dart:844` — 0.6 alpha | Borderline | Bump to ≥0.65 |
| `liquid_glass.dart:70` — 0.5 border | Low vis | Bump to ≥0.6 |
| `theme_selector.dart:102` — 0.6 alpha on text | Borderline | Bump to ≥0.7 |

All fixes validated via `validateContrast()` in `a11y_theme.dart`.

---

## Section 4: Keyboard shortcuts

### Flutter-native keyboard support

| Shortcut | Context | Action |
|----------|---------|--------|
| `Ctrl/Cmd + F` | Global | Focus search |
| `Ctrl/Cmd + N` | Home/List screens | New item (password, note) |
| `Escape` | Dialog/Modal | Close/cancel |
| `Enter` | Form | Submit |
| `Tab/Shift+Tab` | Global | Focus traversal (already works with Focus widgets) |

Implementation: `CallbackShortcuts` + `Shortcuts` at `MaterialApp` level for global shortcuts, per-screen for contextual ones.

---

## Section 5: Tests

### Unit tests for a11y utilities

- `a11y_theme_test.dart` — contrast validation, accessible color derivations
- `a11y_constants_test.dart` — constants are correct values
- `a11y_extensions_test.dart` — MediaQuery wrappers

### Widget tests for a11y widgets

- `a11y_widgets_test.dart` — Semantics tree verification for each accessible widget:
  - `AccessibleIconButton` has correct `label`, role `button`, min size
  - `AccessibleTextField` has correct `label`, role `textField`, error announcement
  - `SemanticsHeading` has `header: true`
  - `SemanticsScreenTitle` announces on appear
  - `AccessibleDialog` traps focus

### Integration tests

- `auth_accessibility_test.dart` — Tab through auth flow, verify focus order and announcements
- `password_accessibility_test.dart` — Verify password CRUD semantics

---

## Testing checklist (invariant)

Each screen must pass:
- [ ] All IconButtons have tooltips (compiler-enforced with `AccessibleIconButton`)
- [ ] All TextFields have labels (compiler-enforced with `AccessibleTextField`)
- [ ] Focus order follows visual layout
- [ ] No keyboard traps
- [ ] Skip link present on scrollable screens
- [ ] Screen title announced on focus
- [ ] All dynamic content changes announced (errors, success messages)
- [ ] Contrast ≥4.5:1 for normal text, ≥3:1 for large text
