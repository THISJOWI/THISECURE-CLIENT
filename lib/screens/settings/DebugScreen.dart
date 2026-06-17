import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:thisjowi/components/sync_debug_panel.dart';
import 'package:thisjowi/data/local/database.dart';
import 'package:thisjowi/i18n/translations.dart';

/// Pantalla de configuración y debugging
class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Debug & Sync'.i18n),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SyncDebugPanel(),
            const SizedBox(height: 24),
            _buildDangerZone(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danger Zone'.i18n,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _confirmDeleteDatabase(context),
              icon: const Icon(Icons.delete_forever),
              label: Text('Delete Local Database'.i18n),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDatabase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Database?'.i18n),
        content: Text(
          'This will delete all local data. This action cannot be undone.'.i18n,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.i18n),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Yes, Delete All'.i18n),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final db = AppDatabase.instance();
        await db.close();

        final dir = await getApplicationSupportDirectory();
        final file = File('${dir.path}/thisjowi_encrypted.sqlite');
        if (await file.exists()) {
          await file.delete();
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Database deleted. Restart the app.'.i18n),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: %s".i18n.fill([e.toString()])),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
