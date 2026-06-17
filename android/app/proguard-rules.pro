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

# Local auth
-keep class androidx.biometric.** { *; }
