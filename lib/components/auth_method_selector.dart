import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/i18n/translations.dart';

class AuthMethodSelector extends StatelessWidget {
  final VoidCallback? onLdapTap;
  final VoidCallback onRegularTap;
  final VoidCallback? onSamlTap;
  final VoidCallback? onGoogleTap;
  final VoidCallback? onMicrosoftTap;

  const AuthMethodSelector({
    super.key,
    this.onLdapTap,
    required this.onRegularTap,
    this.onSamlTap,
    this.onGoogleTap,
    this.onMicrosoftTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Text(
            'Select how you want to sign in'.i18n,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (onSamlTap != null) ...[
            _buildOption(
              context: context,
              onTap: onSamlTap!,
              icon: Icons.shield_outlined,
              title: 'Enterprise SSO'.i18n,
              subtitle: 'SAML / Azure AD'.i18n,
              accentColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (onLdapTap != null)
                Expanded(
                  child: _buildOption(
                    context: context,
                    onTap: onLdapTap!,
                    icon: Icons.business,
                    title: 'Corporate LDAP'.i18n,
                    subtitle: 'Enterprise account'.i18n,
                    accentColor: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              if (onLdapTap != null) const SizedBox(width: 12),
              Expanded(
                child: _buildOption(
                  context: context,
                  onTap: onRegularTap,
                  icon: Icons.person,
                  title: 'Regular Account'.i18n,
                  subtitle: 'Email and password'.i18n,
                  accentColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          if (onGoogleTap != null) const SizedBox(height: 12),
          if (onGoogleTap != null)
          GestureDetector(
              onTap: onGoogleTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (Theme.of(context).brightness == Brightness.light ? Colors.white : const Color(0xFF2A2A2A)).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Semantics(
                            label: 'Google',
                            child: Image.asset(
                              'assets/google_logo.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google'.i18n,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
          if (onMicrosoftTap != null) const SizedBox(height: 12),
          if (onMicrosoftTap != null)
          GestureDetector(
              onTap: onMicrosoftTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (Theme.of(context).brightness == Brightness.light ? Colors.white : const Color(0xFF2A2A2A)).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.window,
                            size: 24,
                            color: Color(0xFF00A4EF),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Microsoft'.i18n,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ))
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
  }) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: (Theme.of(context).brightness == Brightness.light ? Colors.white : const Color(0xFF2A2A2A)).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
