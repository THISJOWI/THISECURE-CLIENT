import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thisjowi/i18n/translations.dart';

class DeploymentModeSelector extends StatefulWidget {
  final Function(String) onDeploymentModeSelected;

  const DeploymentModeSelector({
    super.key,
    required this.onDeploymentModeSelected,
  });

  @override
  State<DeploymentModeSelector> createState() => _DeploymentModeSelectorState();
}

class _DeploymentModeSelectorState extends State<DeploymentModeSelector>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  late AnimationController _controller;

  final List<_DeploymentOption> _options = [
    _DeploymentOption(
      icon: Icons.cloud_outlined,
      title: 'Cloud',
      subtitle: 'Servicio gestionado en la nube',
      type: 'Cloud',
      features: ['Automático', 'Escalable'],
      gradient: [const Color(0xFF7A5C3A), const Color(0xFF9A7C5A)],
    ),
    _DeploymentOption(
      icon: Icons.computer_outlined,
      title: 'Self-Hosted',
      subtitle: 'En tu propia infraestructura',
      type: 'SelfHosted',
      features: ['Privado', 'Control total'],
      gradient: [const Color(0xFF81C784), const Color(0xFFA5D6A7)],
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
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          Icons.dns_outlined,
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
            'Deployment Mode'.i18n,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how to host your data'.i18n,
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

  Widget _buildOptionCard(int index, _DeploymentOption option) {
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
    required _DeploymentOption option,
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
            widget.onDeploymentModeSelected(option.type);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..translate(0.0, isHovered ? -4.0 : 0.0),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                          const SizedBox(width: 16),
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
                      const SizedBox(height: 16),
                      Row(
                        children: option.features.map((feature) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: option.gradient[0].withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: option.gradient[0].withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                feature,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: option.gradient[0].withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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

class _DeploymentOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final String type;
  final List<String> features;
  final List<Color> gradient;

  _DeploymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.features,
    required this.gradient,
  });
}
