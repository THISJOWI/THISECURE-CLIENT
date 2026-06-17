import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:thisjowi/data/models/passkey_entry.dart';
import 'package:thisjowi/i18n/translations.dart';

class PasskeyItem extends StatelessWidget {
  final PasskeyEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PasskeyItem({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: (Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : const Color(0xFF2A2A2A))
                  .withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.fingerprint,
                            color: Theme.of(context).colorScheme.onSurface, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (entry.rpName.isNotEmpty || entry.rpId.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                entry.rpName.isNotEmpty ? entry.rpName : entry.rpId,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (entry.backupEligible)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Tooltip(
                            message: 'Backup'.i18n,
                            child: Icon(Icons.cloud_done_outlined,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                size: 18),
                          ),
                        ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 20),
                        onPressed: onDelete,
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
