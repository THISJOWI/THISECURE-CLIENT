import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/core/environment_profile.dart';
import 'package:thisjowi/core/environment_profile_manager.dart';
import 'package:thisjowi/i18n/translations.dart';

class EnvironmentModeChip extends StatelessWidget {
  final bool showServerConfig;

  const EnvironmentModeChip({super.key, this.showServerConfig = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnvironmentProfileManager>(
      builder: (context, mgr, _) {
        final isCloud = mgr.activeProfile?.isCloud ?? true;
        final activeName = mgr.activeProfile?.name ?? 'Cloud';
        final serverUrl = mgr.activeProfile?.serverUrl;

        return GestureDetector(
          onTap: () => _showModeDialog(context, showServerConfig),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCloud
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCloud
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCloud ? Icons.cloud : Icons.dns,
                  size: 16,
                  color: isCloud
                    ? Theme.of(context).colorScheme.primary
                    : Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  isCloud ? 'Cloud' : activeName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isCloud
                      ? Theme.of(context).colorScheme.primary
                      : Colors.green,
                  ),
                ),
                if (!isCloud && serverUrl != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    ' • $serverUrl',
                    style: TextStyle(
                      fontSize: 11,
                      color: isCloud
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
                        : Colors.green.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.swap_horiz,
                  size: 14,
                  color: isCloud
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
                    : Colors.green.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showModeDialog(BuildContext context, bool showConfig) {
    final mgr = EnvironmentProfileManager();
    showDialog(
      context: context,
      builder: (ctx) => _EnvironmentModeDialog(showServerConfig: showConfig, manager: mgr),
    );
  }
}

class _EnvironmentModeDialog extends StatefulWidget {
  final bool showServerConfig;
  final EnvironmentProfileManager manager;

  const _EnvironmentModeDialog({
    required this.showServerConfig,
    required this.manager,
  });

  @override
  State<_EnvironmentModeDialog> createState() => _EnvironmentModeDialogState();
}

class _EnvironmentModeDialogState extends State<_EnvironmentModeDialog> {
  late bool _isCloud;
  late final TextEditingController _hostController;
  bool _useSsl = false;

  @override
  void initState() {
    super.initState();
    _isCloud = widget.manager.isCloud;
    final savedUrl = widget.manager.activeProfile?.serverUrl ?? '';
    if (savedUrl.isNotEmpty) {
      final uri = Uri.tryParse(savedUrl);
      if (uri != null) {
        _useSsl = uri.scheme == 'https';
        _hostController = TextEditingController(text: uri.host);
        return;
      }
    }
    _hostController = TextEditingController();
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  void _onSslChanged(bool v) {
    setState(() => _useSsl = v);
  }

  Future<void> _save() async {
    final mgr = widget.manager;
    if (_isCloud) {
      if (mgr.isCloud) {
        Navigator.pop(context);
        return;
      }
      await mgr.switchTo('cloud');
    } else {
      final host = _hostController.text.trim();
      if (host.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter the server host'.i18n)),
        );
        return;
      }
      final port = _useSsl ? 443 : 80;
      final protocol = _useSsl ? 'https' : 'http';
      final url = '$protocol://$host:$port';

      final existing = mgr.profiles.firstWhere(
        (p) => p.isSelfHosted && p.serverUrl == url,
        orElse: () => EnvironmentProfile(
          id: '',
          name: 'Self-Hosted',
          type: EnvironmentType.selfHosted,
          serverUrl: url,
          createdAt: DateTime.now(),
        ),
      );

      if (existing.id.isEmpty) {
        final profile = EnvironmentProfile(
          id: 'self_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Self-Hosted',
          type: EnvironmentType.selfHosted,
          serverUrl: url,
          createdAt: DateTime.now(),
        );
        await mgr.addProfile(profile);
        await mgr.switchTo(profile.id);
      } else if (existing.id != mgr.activeProfile?.id) {
        await mgr.switchTo(existing.id);
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 400,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Server Mode'.i18n,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildModeOption('Cloud', Icons.cloud, true),
                    const SizedBox(height: 12),
                    _buildModeOption('Self-Hosted', Icons.dns, false),
                    if (!_isCloud) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _hostController,
                        decoration: InputDecoration(
                          labelText: 'Host'.i18n,
                          hintText: '192.168.1.100',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          prefixIcon: Icon(Icons.computer_outlined, size: 20,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Secure connection (SSL)'.i18n,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const Spacer(),
                          _buildProtocolToggle(),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Save'.i18n,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolToggle() {
    return Switch(
      value: _useSsl,
      onChanged: _onSslChanged,
      activeThumbColor: Theme.of(context).colorScheme.onSurface,
      activeTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      inactiveThumbColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
    );
  }

  Widget _buildModeOption(String label, IconData icon, bool isCloud) {
    final selected = _isCloud == isCloud;
    return GestureDetector(
      onTap: () {
        if (isCloud == widget.manager.isCloud) {
          Navigator.pop(context);
          return;
        }
        if (isCloud) {
          widget.manager.switchTo('cloud');
          Navigator.pop(context);
        } else {
          setState(() => _isCloud = isCloud);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const Spacer(),
            if (selected)
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
