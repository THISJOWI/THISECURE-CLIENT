import 'package:flutter/material.dart';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/services/profile_service.dart';
import 'package:thisjowi/core/exceptions/profile_exceptions.dart';
import 'package:thisjowi/data/models/auth_user.dart';
import 'package:thisjowi/data/models/profile_user.dart';
import 'package:thisjowi/i18n/translations.dart';

class ProfileCard extends StatefulWidget {
  final AuthService authService;
  final ProfileService profileService;

  const ProfileCard({
    super.key,
    required this.authService,
    required this.profileService,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  AuthUser? _currentAuthUser;
  ProfileUser? _currentProfile;
  int _avatarCacheBuster = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authUser = await widget.authService.getCurrentAuthUser();
    try {
      final profile = await widget.profileService.getCurrentProfile();
      if (mounted) setState(() => _currentProfile = profile);
    } on ProfileException {
      // Profile loading is non-critical
    }
    if (mounted) setState(() => _currentAuthUser = authUser);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                width: 2,
              ),
              image: (_currentProfile?.avatarUrl != null && _currentProfile!.avatarUrl!.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(
                        '${_currentProfile!.avatarUrl!.startsWith('http') ? '' : ApiConfig.baseUrl}${_currentProfile!.avatarUrl!}${_currentProfile!.avatarUrl!.contains('?') ? '&' : '?'}cb=$_avatarCacheBuster',
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _currentProfile?.avatarUrl == null
                ? Center(
                    child: Text(
                      _currentProfile?.initials ?? 'U',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentProfile?.fullName ?? 'User'.i18n,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentAuthUser?.email ?? '',
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
