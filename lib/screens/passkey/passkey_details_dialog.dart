import 'package:flutter/material.dart';
import 'package:thisjowi/components/liquid_glass.dart';
import 'package:thisjowi/data/models/passkey_entry.dart';
import 'package:thisjowi/i18n/translations.dart';

class PasskeyDetailsDialog extends StatelessWidget {
  final PasskeyEntry entry;

  const PasskeyDetailsDialog({super.key, required this.entry});

  static Future<bool?> show(BuildContext context, PasskeyEntry entry) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => PasskeyDetailsDialog(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: LiquidGlass.wrap(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.fingerprint,
                        color: Theme.of(context).colorScheme.primary, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (entry.rpName.isNotEmpty)
                  _row(context, 'Relying party'.i18n, entry.rpName),
                if (entry.rpId.isNotEmpty) _row(context, 'rpId', entry.rpId),
                if (entry.credentialType.isNotEmpty)
                  _row(context, 'Type', entry.credentialType),
                if (entry.transports.isNotEmpty)
                  _row(context, 'Transports', entry.transports.join(', ')),
                _row(context, 'Last used'.i18n,
                    entry.signCount == 0 ? 'Never'.i18n : '${entry.signCount}'),
                _row(context, 'Backup'.i18n, entry.backupEligible ? 'Eligible' : 'No'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.delete_outline),
                        label: Text('Delete'.i18n),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Close'.i18n),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            context,
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
