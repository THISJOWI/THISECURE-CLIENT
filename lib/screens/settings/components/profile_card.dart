import 'package:flutter/material.dart';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/data/models/auth_user.dart';
import 'package:thisjowi/data/models/profile_user.dart';
import 'package:thisjowi/i18n/translations.dart';

class ProfileCard extends StatelessWidget {
  final AuthUser? currentAuthUser;
  final ProfileUser? currentProfile;
  final int avatarCacheBuster;
  final VoidCallback? onAvatarTap;

  const ProfileCard({
    super.key,
    required this.currentAuthUser,
    required this.currentProfile,
    this.avatarCacheBuster = 0,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  width: 2,
                ),
                image: (currentProfile?.avatarUrl != null && currentProfile!.avatarUrl!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(
                          '${currentProfile!.avatarUrl!.startsWith('http') ? '' : ApiConfig.baseUrl}${currentProfile!.avatarUrl!}${currentProfile!.avatarUrl!.contains('?') ? '&' : '?'}cb=$avatarCacheBuster',
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: currentProfile?.avatarUrl == null
                  ? Center(
                      child: Text(
                        currentProfile?.initials ?? 'U',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentProfile?.fullName ?? 'User'.i18n,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentAuthUser?.email ?? '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}
