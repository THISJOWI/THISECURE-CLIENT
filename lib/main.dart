import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:i18n_extension/i18n_extension.dart' show Translations, I18n;
import 'package:provider/provider.dart';
import 'package:thisjowi/core/app_theme.dart';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/core/env_loader.dart';
import 'package:thisjowi/core/theme_provider.dart';
import 'package:thisjowi/core/environment_profile_manager.dart';
import 'package:thisjowi/core/providers/otp_provider.dart';
import 'package:thisjowi/core/providers/sync_provider.dart';
import 'package:thisjowi/screens/auth/login.dart';
import 'package:thisjowi/screens/auth/register.dart';
import 'package:thisjowi/screens/auth/authSelection.dart';
import 'package:thisjowi/screens/otp/OtpQrScannerScreen.dart';
import 'package:thisjowi/screens/splash/splash.dart';
import 'package:thisjowi/screens/onboarding/onBoarding.dart';
import 'package:thisjowi/screens/environments/environment_list_screen.dart';
import 'package:thisjowi/screens/environments/environment_add_screen.dart';
import 'package:thisjowi/components/privacy_overlay.dart';
import 'package:thisjowi/data/repository/passwordsRepository.dart';
import 'package:thisjowi/data/repository/notes_repository.dart';
import 'package:thisjowi/data/repository/otp_repository.dart';
import 'package:thisjowi/data/repository/profile_repository.dart';
import 'package:thisjowi/services/telemetry_service.dart';
import 'package:thisjowi/services/token_manager.dart';
import 'package:thisjowi/utils/app_logger.dart';

// Workaround for macOS keyboard event bug
// See: https://github.com/flutter/flutter/issues/148604
class KeyboardEventFix extends StatefulWidget {
  final Widget child;
  const KeyboardEventFix({super.key, required this.child});

  @override
  State<KeyboardEventFix> createState() => _KeyboardEventFixState();
}

class _KeyboardEventFixState extends State<KeyboardEventFix> {
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  @override
  void initState() {
    super.initState();
    // Note: HardwareKeyboard.clearState() is not public API
    // The fix works by intercepting duplicate key events in _handleKeyEvent
  }

  @override
  void dispose() {
    _pressedKeys.clear();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (_pressedKeys.contains(event.logicalKey)) {
        // Key was already pressed, ignore duplicate
        return KeyEventResult.handled;
      }
      _pressedKeys.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    } else if (event is KeyRepeatEvent) {
      if (!_pressedKeys.contains(event.logicalKey)) {
        // Repeat event without prior down event
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      canRequestFocus: true,
      onKeyEvent: (node, event) => _handleKeyEvent(event),
      child: widget.child,
    );
  }
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar sistema de logging
  await AppLogger.initialize();
  appLog.i('🚀 App starting...');

  // Silenciar callbacks de traducciones faltantes
  // Estas configs deben estar ANTES de que se carguen las traducciones
  Translations.missingKeyCallback = (key, locale) {};
  Translations.missingTranslationCallback = ({required key, required locale, required translations, required supportedLocales}) => false;

  await EnvLoader.load();
  await ApiConfig.init();
  await EnvironmentProfileManager().load();

  // Inicializar TokenManager para que cargue el token desde el inicio
  await TokenManager().init();

  ApiConfig.printConfig();

  await TelemetryService.init();

  appLog.i('✅ App initialized successfully');
  runApp(const MainApp());
}

class _SystemUIUpdater extends StatelessWidget {
  final Widget child;
  const _SystemUIUpdater({required this.child});

  @override
  Widget build(BuildContext context) {
    context.read<ThemeProvider>().updateSystemUI(context);
    return child;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.escape): () {},
      },
      child: Focus(
        autofocus: true,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => EnvironmentProfileManager()),
            Provider<PasswordsRepository>(create: (_) => PasswordsRepository()),
            Provider<NotesRepository>(create: (_) => NotesRepository()),
            Provider<OtpRepository>(create: (_) => OtpRepository()),
            Provider<ProfileRepository>(create: (_) => ProfileRepository()),
            ChangeNotifierProvider(create: (_) => OtpProvider()),
            ChangeNotifierProvider(create: (_) => SyncProvider()),
          ],
          child: KeyboardEventFix(
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return I18n(
                  child: _AppCore(themeProvider: themeProvider),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AppCore extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _AppCore({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return _SystemUIUpdater(
      child: MaterialApp(
        locale: I18n.locale,
        debugShowCheckedModeBanner: false,
        title: "THISECURE",
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('es'),
          ...FlutterQuillLocalizations.supportedLocales,
        ],
        builder: (context, child) => PrivacyOverlay(child: child!),
        themeMode: themeProvider.flutterThemeMode,
        theme: AppTheme.getLightTheme(),
        darkTheme: AppTheme.getDarkTheme(),
        routes: {
          '/authSelection': (context) => const AuthSelectionScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/otp/qrscan': (context) => const OtpQrScannerScreen(),
          '/environments': (context) => const EnvironmentListScreen(),
          '/environments/add': (context) => const EnvironmentAddScreen(),
        },
        home: const SplashScreen(),
      ),
    );
  }
}
