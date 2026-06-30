import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/core/environment_profile.dart';
import 'package:thisjowi/core/environment_profile_manager.dart';
import 'package:thisjowi/components/liquid_glass.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/screens/environments/environment_add_screen.dart';

class EnvironmentListScreen extends StatelessWidget {
  const EnvironmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Environments'.i18n,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<EnvironmentProfileManager>(
        builder: (context, mgr, _) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: mgr.profiles.length,
                  itemBuilder: (context, index) {
                    final profile = mgr.profiles[index];
                    final isActive = profile.id == mgr.activeProfile?.id;
                    return _ProfileTile(
                      profile: profile,
                      isActive: isActive,
                      onSwitch: isActive ? null : () => _confirmSwitch(context, mgr, profile),
                      onDelete: profile.id == 'cloud' ? null : () => _confirmDelete(context, mgr, profile),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: LiquidGlass.wrap(
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EnvironmentAddScreen()),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text('Add Environment'.i18n, style: const TextStyle(color: Colors.white)),
                ),
                context,
              ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmSwitch(BuildContext context, EnvironmentProfileManager mgr, EnvironmentProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: SizedBox(
          width: 400,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: LiquidGlass.wrap(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Switch Environment'.i18n,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Switching to "${profile.name}". Your current session will end and you will be redirected to login.'.i18n,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel'.i18n),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          mgr.switchTo(profile.id);
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        },
                        child: Text('Switch & Logout'.i18n),
                      ),
                    ],
                  ),
                ],
              ),
              context,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, EnvironmentProfileManager mgr, EnvironmentProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: SizedBox(
          width: 400,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: LiquidGlass.wrap(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Delete Environment'.i18n,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to delete "${profile.name}"? This action cannot be undone.'.i18n,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancel'.i18n),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          mgr.deleteProfile(profile.id);
                        },
                        child: Text('Delete'.i18n),
                      ),
                    ],
                  ),
                ],
              ),
              context,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final EnvironmentProfile profile;
  final bool isActive;
  final VoidCallback? onSwitch;
  final VoidCallback? onDelete;

  const _ProfileTile({
    required this.profile,
    required this.isActive,
    this.onSwitch,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          profile.isCloud ? Icons.cloud : Icons.dns,
          color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        title: Text(
          profile.name,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          profile.isCloud ? 'Cloud hosted by thisuite'.i18n
            : profile.serverUrl ?? 'Not configured'.i18n,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active'.i18n,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (onSwitch != null)
              TextButton(
                onPressed: onSwitch,
                child: Text('Switch'.i18n),
              ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
