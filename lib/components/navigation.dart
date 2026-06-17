import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/screens/otp/TOPT.dart';
import 'package:thisjowi/screens/home/HomeScreen.dart';
import 'package:thisjowi/screens/settings/SettingScreen.dart';
import 'package:thisjowi/screens/messages/MessagesScreen.dart';
import 'package:thisjowi/services/auth_service.dart';
import 'package:thisjowi/services/profile_service.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/core/providers/sync_provider.dart';
import 'package:thisjowi/services/autofillSaveHandler.dart';
import 'package:thisjowi/services/passwordService.dart';

final GlobalKey<Navigation> bottomNavigationKey = GlobalKey<Navigation>();

class MyBottomNavigation extends StatefulWidget {
  const MyBottomNavigation({super.key});

  @override
  State<MyBottomNavigation> createState() => Navigation();
}

class Navigation extends State<MyBottomNavigation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final AutofillSaveHandler _autofillHandler = AutofillSaveHandler();
  bool _isBusinessAccount = false;
  List<Widget> _pages = [];
  List<_NavItem> _navItems = [];
  String? _profilePhotoUrl;
  String _profileInitials = 'U';
  int _avatarCacheBuster = 0;
  DateTime? _lastProfileCheck;
  SyncProvider? _syncProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initNavigation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncProvider = context.read<SyncProvider>();
        _syncProvider?.addListener(_onSyncProviderChanged);
      }
    });
  }

  @override
  void dispose() {
    _syncProvider?.removeListener(_onSyncProviderChanged);
    WidgetsBinding.instance.removeObserver(this);
    _autofillHandler.stopMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      _autofillHandler.checkNow(context);
      context.read<SyncProvider>().start();
    } else if (state == AppLifecycleState.paused) {
      context.read<SyncProvider>().stop();
    }
  }

  Future<void> _initNavigation() async {
    final cachedType = await _authService.getCachedAccountType();
    final user = await _authService.getCurrentUser();

    if (mounted) {
      setState(() {
        final aspect = user?.accountType ?? cachedType;
        _isBusinessAccount = aspect?.toLowerCase() == 'business';
        _buildPages();
        _buildNavItems();
      });
      _autofillHandler.startMonitoring(context);
      // Sync passwords with iOS autofill extension after login
      PasswordService().syncWithAutofill();

      // Start real-time SSE sync connection
      if (mounted) {
        context.read<SyncProvider>().start();
      }

      // Load profile photo for the navbar avatar
      _loadProfilePhoto();
    }
  }

  void _onSyncProviderChanged() {
    if (!mounted) return;
    final syncProvider = context.read<SyncProvider>();

    final profileStamp = syncProvider.profileLastUpdated;
    final accountStamp = syncProvider.accountLastUpdated;
    final latest = _latestOf([profileStamp, accountStamp]);

    if (latest != null && (_lastProfileCheck == null || latest.isAfter(_lastProfileCheck!))) {
      _lastProfileCheck = latest;
      _loadProfilePhoto();
    }
  }

  DateTime? _latestOf(List<DateTime?> stamps) {
    DateTime? latest;
    for (final s in stamps) {
      if (s != null && (latest == null || s.isAfter(latest))) {
        latest = s;
      }
    }
    return latest;
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final profile = await _profileService.getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profilePhotoUrl = profile?.avatarUrl;
        _profileInitials = profile?.initials ?? 'U';
        _avatarCacheBuster++;
      });
    } catch (_) {
      // Non-critical; keep previous avatar state on error
    }
  }

  void _buildPages() {
    _pages = [
      const HomeScreen(),
      if (_isBusinessAccount) const MessagesScreen(),
      const OtpScreen(),
      const SettingScreen(),
    ];
  }

  void _buildNavItems() {
    _navItems = [
      _NavItem(
        icon: Icons.house_rounded,
        label: 'Home'.i18n,
        index: 0,
      ),
      if (_isBusinessAccount)
        _NavItem(
          icon: Icons.chat_bubble_rounded,
          label: 'Messages'.i18n,
          index: 1,
        ),
      _NavItem(
        icon: Icons.shield_rounded,
        label: 'OTP'.i18n,
        index: _isBusinessAccount ? 2 : 1,
      ),
      _NavItem(
        icon: Icons.settings_rounded,
        label: 'Settings'.i18n,
        index: _isBusinessAccount ? 3 : 2,
        isProfileAvatar: true,
      ),
    ];
  }

  void navigateToTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _currentIndex = index);
    }
  }

  void navigateToOtp() {
    final index = _pages.indexWhere((widget) => widget is OtpScreen);
    if (index != -1) {
      navigateToTab(index);
    }
  }

  bool get _isDesktopPlatform {
    try {
      return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  Widget _buildProfileAvatar(bool isSelected) {
    final hasPhoto =
        _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty;
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25);
    final bgColor = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.08);
    final initialsColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

    final imageUrl = hasPhoto
        ? '${_profilePhotoUrl!.startsWith('http') ? '' : ApiConfig.baseUrl}$_profilePhotoUrl${_profilePhotoUrl!.contains('?') ? '&' : '?'}cb=$_avatarCacheBuster'
        : null;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: borderColor, width: 1.5),
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: hasPhoto
          ? null
          : Center(
              child: Text(
                _profileInitials,
                style: TextStyle(
                  color: initialsColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) _buildPages();
    if (_navItems.isEmpty) _buildNavItems();

    return LayoutBuilder(
      builder: (context, _) {
        final useSidebar =
            MediaQuery.of(context).size.width >= 600 || _isDesktopPlatform;

        if (useSidebar) {
          return _DesktopLayout(
            currentIndex: _currentIndex,
            navItems: _navItems,
            pages: _pages,
            onItemSelected: (index) {
              HapticFeedback.lightImpact();
              setState(() => _currentIndex = index);
            },
          );
        }

        return GlassBackdropScope(
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  Theme.of(context).brightness == Brightness.dark
                      ? Brightness.light
                      : Brightness.dark,
              statusBarBrightness:
                  Theme.of(context).brightness == Brightness.dark
                      ? Brightness.dark
                      : Brightness.light,
            ),
            child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            extendBody: true,
            extendBodyBehindAppBar: true,
            body: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            bottomNavigationBar: GlassBottomBar(
              tabs: _navItems
                  .asMap()
                  .entries
                  .map((entry) {
                    final isSelected = _currentIndex == entry.key;
                    final iconColor = isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
                    final labelColor = isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
                    final iconWidget = entry.value.isProfileAvatar
                        ? _buildProfileAvatar(isSelected)
                        : Icon(
                            entry.value.icon,
                            size: 28,
                            color: iconColor,
                          );

                    return GlassBottomBarTab(
                      icon: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          iconWidget,
                          const SizedBox(height: 2),
                          Text(
                            entry.value.label,
                            style: TextStyle(
                              color: labelColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(),
              selectedIndex: _currentIndex,
              onTabSelected: (index) {
                HapticFeedback.lightImpact();
                setState(() => _currentIndex = index);
              },
              barHeight: 64,
              barBorderRadius: 28,
              horizontalPadding: 20,
              spacing: 8,
              glassSettings: LiquidGlassSettings(
                thickness: Theme.of(context).brightness == Brightness.dark ? 30 : 55,
                blur: Theme.of(context).brightness == Brightness.dark ? 90 : 90,
                refractiveIndex: 1.45,
              ),
              showIndicator: true,
            ),
          ),
        ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  final bool isProfileAvatar;

  _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    this.isProfileAvatar = false,
  });
}

class _DesktopLayout extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> navItems;
  final List<Widget> pages;
  final ValueChanged<int> onItemSelected;

  const _DesktopLayout({
    required this.currentIndex,
    required this.navItems,
    required this.pages,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          Container(
            width: 220,
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/empresa.png',
                        height: 40,
                        width: 40,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'THISECURE',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 16),
                ...navItems.map((item) => _SidebarItem(
                      icon: item.icon,
                      label: item.label,
                      isSelected: currentIndex == item.index,
                      onTap: () => onItemSelected(item.index),
                    )),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'v1.0.2'.i18n,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: IndexedStack(
                index: currentIndex,
                children: pages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
