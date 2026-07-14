import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String? imagePath;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;

  const SocialLoginButton({
    super.key,
    this.imagePath,
    this.icon,
    this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: imagePath != null
              ? Semantics(
                  label: imagePath?.contains('google') == true ? 'Google' : '',
                  child: Image.asset(imagePath!, width: 28, height: 28),
                )
              : Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}
