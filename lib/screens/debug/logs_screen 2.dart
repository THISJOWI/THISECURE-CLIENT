import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:thisjowi/core/app_colors.dart';
import 'package:thisjowi/utils/app_logger.dart';

/// Pantalla para visualizar logs de la aplicación
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<File> _logFiles = [];
  String? _selectedLogContent;
  File? _selectedFile;
  bool _isLoading = true;
  String _filter = '';
  LogLevel? _levelFilter;

  @override
  void initState() {
    super.initState();
    _loadLogFiles();
  }

  Future<void> _loadLogFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await AppLogger.getLogFiles();
      setState(() {
        _logFiles = files..sort((a, b) => b.path.compareTo(a.path));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading logs: $e')),
        );
      }
    }
  }

  Future<void> _loadLogFile(File file) async {
    setState(() => _isLoading = true);
    try {
      final content = await file.readAsString();
      setState(() {
        _selectedLogContent = content;
        _selectedFile = file;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reading log: $e')),
        );
      }
    }
  }

  Future<void> _clearAllLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Clear All Logs?', style: TextStyle(color: AppColors.text)),
        content: const Text(
          'This will delete all log files. This action cannot be undone.',
          style: TextStyle(color: AppColors.text),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppLogger.clearLogs();
      setState(() {
        _logFiles = [];
        _selectedLogContent = null;
        _selectedFile = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All logs cleared')),
        );
      }
    }
  }

  Future<void> _shareLogFile() async {
    if (_selectedLogContent == null) return;

    await Clipboard.setData(ClipboardData(text: _selectedLogContent!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log copied to clipboard')),
      );
    }
  }

  List<String> _getFilteredLines() {
    if (_selectedLogContent == null) return [];

    final lines = _selectedLogContent!.split('\n');
    return lines.where((line) {
      if (line.isEmpty) return false;

      // Filter by text
      if (_filter.isNotEmpty && !line.toLowerCase().contains(_filter.toLowerCase())) {
        return false;
      }

      // Filter by level
      if (_levelFilter != null) {
        final levelName = _levelFilter!.name;
        if (!line.contains('"level":"$levelName"') &&
            !line.contains('[${levelName.toUpperCase()}]')) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Color _getLevelColor(String line) {
    if (line.contains('"level":"FATAL"') || line.contains('[FATAL]')) {
      return Colors.purple;
    } else if (line.contains('"level":"ERROR"') || line.contains('[ERROR]')) {
      return Colors.red;
    } else if (line.contains('"level":"WARNING"') || line.contains('[WARNING]')) {
      return Colors.orange;
    } else if (line.contains('"level":"INFO"') || line.contains('[INFO]')) {
      return Colors.green;
    } else if (line.contains('"level":"DEBUG"') || line.contains('[DEBUG]')) {
      return Colors.cyan;
    } else if (line.contains('"level":"VERBOSE"') || line.contains('[VERBOSE]')) {
      return Colors.grey;
    }
    return AppColors.text;
  }

  String _formatFileName(String path) {
    final fileName = path.split('/').last;
    if (fileName.startsWith('app_')) {
      final timestamp = fileName.substring(4, 19);
      try {
        final date = DateFormat('yyyyMMdd_HHmmss').parse(timestamp);
        return DateFormat('MMM dd, yyyy HH:mm').format(date);
      } catch (_) {
        return fileName;
      }
    }
    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    final filteredLines = _getFilteredLines();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        title: const Text('Application Logs'),
        actions: [
          if (_selectedLogContent != null)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _shareLogFile,
              tooltip: 'Copy to clipboard',
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearAllLogs,
            tooltip: 'Clear all logs',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogFiles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Sidebar with log files
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AppColors.text.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Log Files',
                          style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _logFiles.isEmpty
                            ? Center(
                                child: Text(
                                  'No log files',
                                  style: TextStyle(color: AppColors.text.withValues(alpha: 0.5)),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _logFiles.length,
                                itemBuilder: (context, index) {
                                  final file = _logFiles[index];
                                  final isSelected = file.path == _selectedFile?.path;

                                  return ListTile(
                                    selected: isSelected,
                                    selectedTileColor: AppColors.text.withValues(alpha: 0.1),
                                    title: Text(
                                      _formatFileName(file.path),
                                      style: TextStyle(
                                        color: AppColors.text,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () => _loadLogFile(file),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                // Main content with log viewer
                Expanded(
                  child: Column(
                    children: [
                      // Filter bar
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.text.withValues(alpha: 0.1)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                style: const TextStyle(color: AppColors.text),
                                decoration: InputDecoration(
                                  hintText: 'Filter logs...',
                                  hintStyle: TextStyle(
                                    color: AppColors.text.withValues(alpha: 0.5),
                                  ),
                                  prefixIcon: const Icon(Icons.search, color: AppColors.text),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.text.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.text.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onChanged: (value) => setState(() => _filter = value),
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<LogLevel?>(
                              value: _levelFilter,
                              dropdownColor: AppColors.background,
                              style: const TextStyle(color: AppColors.text),
                              hint: Text(
                                'All Levels',
                                style: TextStyle(color: AppColors.text.withValues(alpha: 0.7)),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All Levels'),
                                ),
                                ...LogLevel.values.map((level) => DropdownMenuItem(
                                      value: level,
                                      child: Text(level.name),
                                    )),
                              ],
                              onChanged: (value) => setState(() => _levelFilter = value),
                            ),
                          ],
                        ),
                      ),
                      // Log content
                      Expanded(
                        child: _selectedLogContent == null
                            ? Center(
                                child: Text(
                                  'Select a log file to view',
                                  style: TextStyle(
                                    color: AppColors.text.withValues(alpha: 0.5),
                                  ),
                                ),
                              )
                            : filteredLines.isEmpty
                                ? Center(
                                    child: Text(
                                      'No matching logs',
                                      style: TextStyle(
                                        color: AppColors.text.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: filteredLines.length,
                                    padding: const EdgeInsets.all(8),
                                    itemBuilder: (context, index) {
                                      final line = filteredLines[index];
                                      return SelectableText(
                                        line,
                                        style: TextStyle(
                                          color: _getLevelColor(line),
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                  ),
                      ),
                      // Status bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.text.withValues(alpha: 0.1)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${filteredLines.length} entries',
                              style: TextStyle(
                                color: AppColors.text.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                            if (_selectedFile != null) ...[
                              const SizedBox(width: 16),
                              Text(
                                'File: ${_selectedFile!.path.split('/').last}',
                                style: TextStyle(
                                  color: AppColors.text.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
