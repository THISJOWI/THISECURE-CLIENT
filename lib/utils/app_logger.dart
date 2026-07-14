import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/// Niveles de log personalizados con colores para consola
enum LogLevel {
  verbose(0, 'VERBOSE', '\x1B[37m'), // Blanco
  debug(1, 'DEBUG', '\x1B[36m'), // Cyan
  info(2, 'INFO', '\x1B[32m'), // Verde
  warning(3, 'WARNING', '\x1B[33m'), // Amarillo
  error(4, 'ERROR', '\x1B[31m'), // Rojo
  fatal(5, 'FATAL', '\x1B[35m'); // Magenta

  final int value;
  final String name;
  final String color;

  const LogLevel(this.value, this.name, this.color);

  static const String resetColor = '\x1B[0m';
}

/// Configuración del logger
class LoggerConfig {
  /// Nivel mínimo de log (incluye este y superiores)
  final LogLevel minLevel;

  /// Si debe mostrar colores en consola
  final bool useColors;

  /// Si debe incluir timestamps
  final bool includeTimestamp;

  /// Si debe incluir el nombre del logger
  final bool includeLoggerName;

  /// Si debe guardar logs en archivo
  final bool saveToFile;

  /// Máximo número de archivos de log a mantener
  final int maxLogFiles;

  /// Tamaño máximo de archivo de log en bytes
  final int maxFileSize;

  const LoggerConfig({
    this.minLevel = LogLevel.debug,
    this.useColors = true,
    this.includeTimestamp = true,
    this.includeLoggerName = true,
    this.saveToFile = false,
    this.maxLogFiles = 5,
    this.maxFileSize = 5 * 1024 * 1024, // 5MB
  });

  /// Configuración para desarrollo
  static const LoggerConfig development = LoggerConfig(
    minLevel: LogLevel.info,
    includeTimestamp: false,
    includeLoggerName: false,
  );

  /// Configuración para producción
  static const LoggerConfig production = LoggerConfig(
    minLevel: LogLevel.warning,
    useColors: false,
    saveToFile: true,
  );

  /// Configuración para testing
  static const LoggerConfig testing = LoggerConfig(
    minLevel: LogLevel.warning,
    useColors: false,
    includeTimestamp: false,
    includeLoggerName: false,
  );
}

/// Entrada de log estructurada
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String loggerName;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.loggerName,
    required this.message,
    this.error,
    this.stackTrace,
    this.context,
  });

  /// Convierte la entrada a formato JSON
  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'logger': loggerName,
        'message': message,
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
        if (context != null) 'context': context,
      };

  /// Formatea la entrada para consola
  String formatConsole(LoggerConfig config) {
    final buffer = StringBuffer();

    if (config.includeTimestamp) {
      buffer.write('[${_formatTimestamp(timestamp)}] ');
    }

    if (config.includeLoggerName) {
      buffer.write('[$loggerName] ');
    }

    buffer.write('[${level.name}] $message');

    if (error != null) {
      buffer.write('\n  Error: $error');
    }

    if (stackTrace != null) {
      buffer.write('\n  StackTrace:\n$stackTrace');
    }

    return buffer.toString();
  }

  /// Formatea la entrada para archivo
  String formatFile() {
    return '${toJson()}\n';
  }

  String _formatTimestamp(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(dt);
  }
}

/// Logger de archivo para persistencia
class FileLogger {
  final LoggerConfig _config;
  File? _currentFile;
  int _currentFileSize = 0;
  final _lock = Object();

  FileLogger(this._config);

  Future<void> initialize() async {
    if (!_config.saveToFile) return;

    await _rotateLogFile();
  }

  Future<void> write(LogEntry entry) async {
    if (!_config.saveToFile) return;

    synchronized(_lock, () async {
      final line = entry.formatFile();
      final bytes = line.length;

      if (_currentFileSize + bytes > _config.maxFileSize) {
        await _rotateLogFile();
      }

      await _currentFile?.writeAsString(line, mode: FileMode.append);
      _currentFileSize += bytes;
    });
  }

  Future<void> _rotateLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // Rotar archivos existentes
      await _rotateExistingFiles(logDir);

      // Crear nuevo archivo
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      _currentFile = File('${logDir.path}/app_$timestamp.log');
      _currentFileSize = 0;

      // Escribir header
      await _currentFile!.writeAsString(
        '# Log iniciado: ${DateTime.now().toIso8601String()}\n',
      );
    } catch (e) {
      debugPrint('Error rotating log file: $e');
    }
  }

  Future<void> _rotateExistingFiles(Directory logDir) async {
    final files = await logDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.log'))
        .map((entity) => entity as File)
        .toList();

    files.sort((a, b) => b.path.compareTo(a.path));

    // Eliminar archivos antiguos
    if (files.length >= _config.maxLogFiles) {
      for (var i = _config.maxLogFiles - 1; i < files.length; i++) {
        await files[i].delete();
      }
    }
  }

  Future<List<File>> getLogFiles() async {
    if (!_config.saveToFile) return [];

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (!await logDir.exists()) return [];

      return await logDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .map((entity) => entity as File)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearLogs() async {
    if (!_config.saveToFile) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');

      if (await logDir.exists()) {
        await logDir.delete(recursive: true);
      }

      _currentFile = null;
      _currentFileSize = 0;
    } catch (e) {
      debugPrint('Error clearing logs: $e');
    }
  }
}

/// Logger principal de la aplicación
class AppLogger {
  static AppLogger? _instance;
  static LoggerConfig _config = LoggerConfig.development;
  static FileLogger? _fileLogger;
  static final Map<String, Logger> _loggers = {};

  /// Inicializa el sistema de logging
  static Future<void> initialize({LoggerConfig? config}) async {
    _config = config ??
        (kReleaseMode ? LoggerConfig.production : LoggerConfig.development);

    _fileLogger = FileLogger(_config);
    await _fileLogger?.initialize();

    // Configurar el logger de la librería 'logging'
    Logger.root.level = _mapToLibraryLevel(_config.minLevel);
    Logger.root.onRecord.listen(_onLogRecord);

    _instance = AppLogger._internal();
  }

  /// Obtiene una instancia del logger
  factory AppLogger(String name) {
    _instance ??= AppLogger._internal();
    return _instance!;
  }

  AppLogger._internal();

  /// Obtiene o crea un logger con el nombre especificado
  Logger _getLogger(String name) {
    return _loggers.putIfAbsent(name, () => Logger(name));
  }

  /// Log verbose (más detallado)
  void v(String message, {String? name, Map<String, dynamic>? context}) {
    _log(LogLevel.verbose, message, name: name, context: context);
  }

  /// Log debug
  void d(String message, {String? name, Map<String, dynamic>? context}) {
    _log(LogLevel.debug, message, name: name, context: context);
  }

  /// Log info
  void i(String message, {String? name, Map<String, dynamic>? context}) {
    _log(LogLevel.info, message, name: name, context: context);
  }

  /// Log warning
  void w(String message,
      {dynamic error, String? name, Map<String, dynamic>? context}) {
    _log(LogLevel.warning, message, error: error, name: name, context: context);
  }

  /// Log error
  void e(String message,
      {dynamic error,
      StackTrace? stackTrace,
      String? name,
      Map<String, dynamic>? context}) {
    _log(LogLevel.error, message,
        error: error, stackTrace: stackTrace, name: name, context: context);
  }

  /// Log fatal (error crítico)
  void f(String message,
      {dynamic error,
      StackTrace? stackTrace,
      String? name,
      Map<String, dynamic>? context}) {
    _log(LogLevel.fatal, message,
        error: error, stackTrace: stackTrace, name: name, context: context);
  }

  void _log(LogLevel level, String message,
      {dynamic error,
      StackTrace? stackTrace,
      String? name,
      Map<String, dynamic>? context}) {
    if (level.value < _config.minLevel.value) return;

    final loggerName = name ?? 'App';
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      loggerName: loggerName,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );

    // Imprimir en consola
    _printToConsole(entry);

    // Guardar en archivo
    _fileLogger?.write(entry);

    // También enviar al logger de la librería
    final logger = _getLogger(loggerName);
    logger.log(_mapToLibraryLevel(level), message, error, stackTrace);
  }

  void _printToConsole(LogEntry entry) {
    if (!kDebugMode) return;

    // Simplified format for console - just level and message
    final color = _config.useColors ? entry.level.color : '';
    final reset = _config.useColors ? LogLevel.resetColor : '';
    
    String formattedLevel;
    switch (entry.level) {
      case LogLevel.verbose:
        formattedLevel = 'Verbose';
        break;
      case LogLevel.debug:
        formattedLevel = 'Debug';
        break;
      case LogLevel.info:
        formattedLevel = 'Info';
        break;
      case LogLevel.warning:
        formattedLevel = 'Warning';
        break;
      case LogLevel.error:
        formattedLevel = 'Error';
        break;
      case LogLevel.fatal:
        formattedLevel = 'Fatal';
        break;
    }
    
    String consoleMsg;
    if (entry.error != null && entry.level.value >= LogLevel.warning.value) {
      // Para errores y warnings, mostrar el error brevemente
      consoleMsg = '$formattedLevel: ${entry.message} -> ${_truncateError(entry.error.toString())}';
    } else {
      consoleMsg = '$formattedLevel: ${entry.message}';
    }

    debugPrint('flutter: $color$consoleMsg$reset');
  }

  String _truncateError(String error) {
    // Truncar errores largos
    if (error.length > 100) {
      return '${error.substring(0, 100)}...';
    }
    return error;
  }

  static void _onLogRecord(LogRecord record) {
    // Este callback se usa para integración con otros sistemas si es necesario
  }

  static Level _mapToLibraryLevel(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
      case LogLevel.debug:
        return Level.FINE;
      case LogLevel.info:
        return Level.INFO;
      case LogLevel.warning:
        return Level.WARNING;
      case LogLevel.error:
        return Level.SEVERE;
      case LogLevel.fatal:
        return Level.SHOUT;
    }
  }

  /// Obtiene los archivos de log
  static Future<List<File>> getLogFiles() async {
    return await _fileLogger?.getLogFiles() ?? [];
  }

  /// Limpia todos los logs
  static Future<void> clearLogs() async {
    await _fileLogger?.clearLogs();
  }

  /// Cambia la configuración en tiempo de ejecución
  static void setConfig(LoggerConfig config) {
    _config = config;
    Logger.root.level = _mapToLibraryLevel(config.minLevel);
  }

  /// Obtiene la configuración actual
  static LoggerConfig get config => _config;
}

/// Extensión para facilitar el uso en widgets
extension LoggerExtension on Object {
  /// Obtiene un logger para esta clase
  AppLogger get logger {
    final name = runtimeType.toString();
    return AppLogger(name);
  }
}

/// Helper para sincronización simple
void synchronized(Object lock, FutureOr<void> Function() action) async {
  // En Dart single-threaded, esto es suficiente
  await action();
}

/// Logger global para uso rápido
final appLog = AppLogger('Global');
