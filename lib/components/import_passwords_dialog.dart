import 'package:flutter/material.dart';
import '../components/liquid_glass.dart';
import '../i18n/translations.dart';
import '../services/import_export_service.dart';
import '../services/passwordService.dart';

class ImportPasswordsDialog extends StatefulWidget {
  const ImportPasswordsDialog({super.key});

  @override
  State<ImportPasswordsDialog> createState() => _ImportPasswordsDialogState();
}

class _ImportPasswordsDialogState extends State<ImportPasswordsDialog> {
  final _importService = ImportExportService();
  final _passwordService = PasswordService();
  bool _loading = false;
  bool _importing = false;
  ImportExportResult? _result;
  String? _error;

  Future<void> _pickFile() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final file = await _importService.pickFile();
      if (file == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final content = _importService.readFileContent(file);

      ImportExportResult result;
      if (file.extension == 'csv' || file.name.endsWith('.csv')) {
        result = _importService.parseCsv(content);
      } else {
        result = _importService.parseJson(content);
      }

      if (result.items.isEmpty) {
        setState(() {
          _error = 'No passwords found in file'.i18n;
          _loading = false;
        });
        return;
      }

      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to read file: $e';
        _loading = false;
      });
    }
  }

  Future<void> _import() async {
    if (_result == null || _result!.items.isEmpty) return;

    setState(() => _importing = true);

    try {
      final result = await _passwordService.importPasswords(_result!.items);

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        final imported = data?['imported'] ?? 0;
        final skipped = data?['skipped'] ?? 0;
        final errors = data?['errors'] ?? 0;

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import completed'.i18n,
            ),
          ),
        );

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.transparent,
              content: LiquidGlass.wrap(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import Results'.i18n,
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _resultRow(ctx, 'Imported'.i18n, imported.toString(), Colors.green),
                    const SizedBox(height: 8),
                    _resultRow(ctx, 'Skipped (duplicates)'.i18n, skipped.toString(), Colors.orange),
                    const SizedBox(height: 8),
                    _resultRow(ctx, 'Errors'.i18n, errors.toString(), Colors.red),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(ctx).colorScheme.primary,
                          foregroundColor: Theme.of(ctx).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('OK'.i18n),
                      ),
                    ),
                  ],
                ),
                ctx,
                padding: const EdgeInsets.all(24),
              ),
            ),
          );
        }
      } else {
        setState(() {
          _error = result['message'] as String? ?? 'Import failed'.i18n;
          _importing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Import failed: $e';
        _importing = false;
      });
    }
  }

  Widget _resultRow(BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 400,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: LiquidGlass.wrap(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Import Passwords'.i18n,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  )
                else if (_error != null)
                  Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _pickFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Try again'.i18n),
                        ),
                      ),
                    ],
                  )
                else if (_result != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Found %s passwords'.i18n.fill([_result!.totalCount.toString()]),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: _result!.items.length > 20
                              ? 20
                              : _result!.items.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.1),
                          ),
                          itemBuilder: (context, index) {
                            final p = _result!.items[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                p['title'] ?? '',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                p['username'] ?? '',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_result!.items.length > 20)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '...and %s more'.i18n.fill([(_result!.items.length - 20).toString()]),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _importing ? null : _pickFile,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Change file'.i18n,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _importing ? null : _import,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _importing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Import'.i18n,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Icon(
                        Icons.file_upload_outlined,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select a CSV or JSON file'.i18n,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _pickFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Choose file'.i18n,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            context,
            padding: const EdgeInsets.all(24),
          ),
        ),
      ),
    );
  }
}
