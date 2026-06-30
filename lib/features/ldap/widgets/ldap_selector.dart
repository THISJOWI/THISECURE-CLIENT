import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thisjowi/i18n/translations.dart';

class LdapSelector extends StatefulWidget {
  final Function(bool) onLdapSelected;

  const LdapSelector({
    super.key,
    required this.onLdapSelected,
  });

  @override
  State<LdapSelector> createState() => _LdapSelectorState();
}

class _LdapSelectorState extends State<LdapSelector>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  late AnimationController _controller;

  final List<_AuthOption> _options = [
    _AuthOption(
      icon: Icons.account_tree_outlined,
      title: 'LDAP Corporativo',
      subtitle: 'Servidor LDAP propio',
      useLdap: true,
      gradient: [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
    ),
    _AuthOption(
      icon: Icons.person_outline,
      title: 'Registro tradicional',
      subtitle: 'Crear cuenta con email y contraseña',
      useLdap: false,
      gradient: [const Color(0xFF7A5C3A), const Color(0xFF9A7C5A)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxWidth: 340,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildTitle(),
                  const SizedBox(height: 48),
                  ..._options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    return _buildOptionCard(index, option);
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          Icons.security_outlined,
          size: 36,
          color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4)),
        );
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 20),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4, curve: Curves.easeOut)),
        );
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Text(
            'Authentication Settings'.i18n,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How do you want to authenticate users?'.i18n,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: textColor.withValues(alpha: 0.5),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int index, _AuthOption option) {
    final isHovered = _hoveredIndex == index;
    final delay = 0.2 + (index * 0.15);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(delay, delay + 0.3, curve: Curves.easeOut),
          ),
        );
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 30),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(delay, delay + 0.3, curve: Curves.easeOutCubic),
          ),
        );
        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: Builder(
              builder: (context) => _buildOptionCardContent(
                index: index,
                option: option,
                isHovered: isHovered,
                isDark: isDark,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCardContent({
    required int index,
    required _AuthOption option,
    required bool isHovered,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final baseAlpha = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onLdapSelected(option.useLdap);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..translate(0.0, isHovered ? -4.0 : 0.0, 0.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? baseAlpha.withValues(alpha: isDark ? 0.12 : 0.1)
                        : baseAlpha.withValues(alpha: isDark ? 0.06 : 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isHovered
                          ? baseAlpha.withValues(alpha: isDark ? 0.25 : 0.2)
                          : baseAlpha.withValues(alpha: isDark ? 0.1 : 0.08),
                      width: isHovered ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: option.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: isHovered
                              ? [
                                  BoxShadow(
                                    color: option.gradient[0].withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          option.icon,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option.subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isHovered
                              ? baseAlpha.withValues(alpha: isDark ? 0.15 : 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: isHovered
                              ? textColor
                              : textColor.withValues(alpha: 0.4),
                        ),
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

class _AuthOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool useLdap;
  final List<Color> gradient;

  _AuthOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.useLdap = false,
    required this.gradient,
  });
}