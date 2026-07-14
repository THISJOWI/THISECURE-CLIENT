import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/i18n/translations.dart';

class ExpandableActionButton extends StatefulWidget {
  final VoidCallback onCreatePassword;
  final VoidCallback onCreateNote;
  final VoidCallback? onCreateOtp;
  final VoidCallback? onCreateMessage;

  const ExpandableActionButton({
    super.key,
    required this.onCreatePassword,
    required this.onCreateNote,
    this.onCreateOtp,
    this.onCreateMessage,
  });

  @override
  State<ExpandableActionButton> createState() => _ExpandableActionButtonState();
}

class _ExpandableActionButtonState extends State<ExpandableActionButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  Animation<double>? _fadeAnimation;
  bool _isExpanded = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController!, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeOut),
    );
    _isInitialized = true;
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController?.forward();
      } else {
        _animationController?.reverse();
      }
    });
  }

  void _handleCreatePassword() {
    setState(() => _isExpanded = false);
    _animationController?.reverse();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) widget.onCreatePassword();
    });
  }

  void _handleCreateNote() {
    setState(() => _isExpanded = false);
    _animationController?.reverse();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) widget.onCreateNote();
    });
  }

  void _handleCreateOtp() {
    setState(() => _isExpanded = false);
    _animationController?.reverse();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && widget.onCreateOtp != null) widget.onCreateOtp!();
    });
  }

  Widget _buildOptionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required double bottomPadding,
  }) {
    if (_fadeAnimation == null || _scaleAnimation == null) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation!,
      child: ScaleTransition(
        scale: _scaleAnimation!,
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ExcludeSemantics(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: (Theme.of(context).brightness == Brightness.light ? Colors.white : const Color(0xFF2A2A2A)).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                                size: 18),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    // Calculate vertical positions
    // Note: Items stack bottom-up. Lowest item (closest to main FAB) is last.
    // 60px height difference typical

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Option: Create OTP
        if (_isExpanded && widget.onCreateOtp != null)
          _buildOptionButton(
            onTap: _handleCreateOtp,
            icon: Icons.security_rounded,
            label: 'OTP'.i18n,
            bottomPadding: 190.0,
          ),
        // Option: Create Password
        if (_isExpanded)
          _buildOptionButton(
            onTap: _handleCreatePassword,
            icon: Icons.key_rounded,
            label: 'Password'.i18n,
            bottomPadding: 135.0,
          ),
        // Option: Create Note
        if (_isExpanded)
          _buildOptionButton(
            onTap: _handleCreateNote,
            icon: Icons.description_outlined,
            label: 'Note'.i18n,
            bottomPadding: 80.0,
          ),
        // Main FAB button - Pill shape
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(28),
            child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _isExpanded ? 1.0 : 0.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: (Theme.of(context).brightness == Brightness.light ? Colors.white : const Color(0xFF2A2A2A)).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: value * 0.785,
                      child: Icon(
                        _isExpanded ? Icons.close_rounded : Icons.add_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 22,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isExpanded ? 0 : 8,
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _isExpanded ? 0 : 1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isExpanded ? 0 : null,
                        child: _isExpanded
                            ? const SizedBox.shrink()
                            : Text(
                                'Create'.i18n,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      ],
    );
  }
}
