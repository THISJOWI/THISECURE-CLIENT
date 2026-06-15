import 'package:flutter/material.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/utils/app_logger.dart';

/// Overlay flotante para mostrar logs en tiempo real durante desarrollo
class LogConsoleOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const LogConsoleOverlay({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<LogConsoleOverlay> createState() => _LogConsoleOverlayState();
}

class _LogConsoleOverlayState extends State<LogConsoleOverlay> {
  bool _isVisible = false;
  bool _isMinimized = false;
final List<LogEntry> _logs = [];
final ScrollController _scrollController = ScrollController();
  LogLevel _minLevel = LogLevel.debug;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    // Aquí podríamos suscribirnos a un stream de logs si lo implementamos
  }

  @override
void dispose() {
  _scrollController.dispose();
  super.dispose();
}

void _clearLogs() {
    setState(() => _logs.clear());
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.fatal:
        return Colors.purple;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.debug:
        return Colors.cyan;
      case LogLevel.verbose:
        return Colors.grey;
    }
  }

  List<LogEntry> _getFilteredLogs() {
    return _logs.where((log) {
      if (log.level.value < _minLevel.value) return false;
      if (_filter.isNotEmpty &&
          !log.message.toLowerCase().contains(_filter.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        // Botón flotante para mostrar/ocultar consola
        Positioned(
          bottom: 80,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            onPressed: () => setState(() => _isVisible = !_isVisible),
            child: Icon(
              _isVisible ? Icons.close : Icons.bug_report,
              color: Theme.of(context).scaffoldBackgroundColor,
              size: 20,
            ),
          ),
        ),
        // Consola de logs
        if (_isVisible)
          Positioned(
            bottom: 140,
            right: 16,
            left: 16,
            height: _isMinimized ? 50 : 300,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.terminal,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Debug Console',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        // Level filter
                        DropdownButton<LogLevel>(
                          value: _minLevel,
                          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 10),
                          underline: const SizedBox(),
                          icon: Icon(Icons.filter_list, size: 16, color: Theme.of(context).colorScheme.onSurface),
                          items: LogLevel.values.map((level) {
                            return DropdownMenuItem(
                              value: level,
                              child: Text(level.name, style: const TextStyle(fontSize: 10)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _minLevel = value);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        // Minimize button
                        IconButton(
                          icon: Icon(
                            _isMinimized ? Icons.expand_less : Icons.expand_more,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () => setState(() => _isMinimized = !_isMinimized),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        ),
                        // Clear button
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: _clearLogs,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        ),
                        // Close button
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () => setState(() => _isVisible = false),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        ),
                      ],
                    ),
                  ),
                  // Filter input
                  if (!_isMinimized)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: TextField(
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 11),
                        decoration: InputDecoration(
                          hintText: 'Filter...',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        onChanged: (value) => setState(() => _filter = value),
                      ),
                    ),
                  // Log list
                  if (!_isMinimized)
                    Expanded(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: _logs.isEmpty
                            ? Center(
                                child: Text(
                                  'No logs yet',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                    fontSize: 11,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(8),
                                itemCount: _getFilteredLogs().length,
                                itemBuilder: (context, index) {
                                  final log = _getFilteredLogs()[index];
                                  return _LogEntryWidget(
                                    entry: log,
                                    color: _getLevelColor(log.level),
                                  );
                                },
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _LogEntryWidget extends StatelessWidget {
  final LogEntry entry;
  final Color color;

  const _LogEntryWidget({
    required this.entry,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final time = '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            height: 1.2,
          ),
          children: [
            TextSpan(
              text: '[$time] ',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            TextSpan(
              text: '[${entry.level.name}] ',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: entry.message,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para mostrar logs de forma simple en cualquier pantalla
class SimpleLogView extends StatelessWidget {
  final List<String> logs;
  final int maxLines;

  const SimpleLogView({
    super.key,
    required this.logs,
    this.maxLines = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: logs.take(maxLines).map((log) {
          return Text(
            log,
            style: const TextStyle(
              color: Colors.green,
              fontFamily: 'monospace',
              fontSize: 10,
            ),
          );
        }).toList(),
      ),
    );
  }
}
