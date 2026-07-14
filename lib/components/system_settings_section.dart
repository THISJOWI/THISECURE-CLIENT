import 'package:flutter/material.dart';
import '../i18n/translations.dart';
import '../services/system_settings_service.dart';

class SystemSettingsSection extends StatefulWidget {
  const SystemSettingsSection({super.key});

  @override
  State<SystemSettingsSection> createState() => _SystemSettingsSectionState();
}

class _SystemSettingsSectionState extends State<SystemSettingsSection> {
  final SystemSettingsService _service = SystemSettingsService();
  SystemInfo? _systemInfo;
  bool _loading = true;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final info = await _service.getSystemInfo();
    if (mounted) {
      setState(() {
        _systemInfo = info;
        _loading = false;
      });
    }
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = (isDark ? const Color(0xFF2A2A2A) : Colors.white).withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(color: glassColor),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool collapsible = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          if (collapsible) ...[
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _itemDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 56,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Checking system settings...'.i18n,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final info = _systemInfo;
    if (info == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'System'.i18n,
          collapsible: true,
        ),
        if (!_expanded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'System Settings'.i18n,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_expanded) ...[
          // Platform info
          _buildItem(
            icon: info.isMobile ? Icons.phone_android : Icons.desktop_windows,
            title: 'Platform'.i18n,
            subtitle: '${info.platform} ${info.osVersion}',
          ),
          _itemDivider(),

          // Default Password Manager
          _buildItem(
            icon: Icons.key,
            title: 'Default Password Manager'.i18n,
            subtitle: info.autofillSupported
                ? (info.autofillEnabled
                    ? 'THISECURE is your default password manager'.i18n
                    : 'Enable THISECURE as your autofill provider in system settings'.i18n)
                : 'Autofill not supported on this device'.i18n,
            trailing: info.autofillSupported
                ? _buildStatusChip(
                    info.autofillEnabled ? 'Active'.i18n : 'Inactive'.i18n,
                    info.autofillEnabled ? Colors.green : Colors.orange,
                  )
                : _buildStatusChip('Not available'.i18n, Colors.grey),
            onTap: info.autofillSupported ? () => _service.openAutofillSettings() : null,
            iconColor: info.autofillEnabled ? Colors.green : null,
          ),
          _itemDivider(),

          // Biometric
          _buildItem(
            icon: Icons.fingerprint,
            title: 'Biometric Permission'.i18n,
            subtitle: info.biometricAvailable ? 'Available'.i18n : 'Not available'.i18n,
            trailing: _buildStatusChip(
              info.biometricAvailable ? 'Available'.i18n : 'Not available'.i18n,
              info.biometricAvailable ? Colors.green : Colors.grey,
            ),
          ),
          _itemDivider(),

          // Notification permission
          _buildItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications'.i18n,
            subtitle: info.notificationPermission == PermissionState.granted
                ? 'Granted'.i18n
                : info.notificationPermission == PermissionState.denied
                    ? 'Denied'.i18n
                    : 'Unknown'.i18n,
            trailing: IconButton(
              icon: Icon(
                Icons.open_in_new,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              tooltip: 'Notification settings'.i18n,
              onPressed: () => _service.openNotificationSettings(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ),
          _itemDivider(),

          // Open system settings
          _buildItem(
            icon: Icons.settings_applications,
            title: 'Open System Settings'.i18n,
            subtitle: 'Manage THISECURE permissions in system settings'.i18n,
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            onTap: () => _service.openAppSystemSettings(),
          ),
        ],
      ],
    );
  }
}
