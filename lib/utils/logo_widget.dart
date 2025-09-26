import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final double borderRadius;
  final String assetPath;

  const LogoWidget({
    super.key,
    this.size = 80,
    this.backgroundColor,
    this.borderRadius = 20,
    this.assetPath = 'assets/images/logo.png',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xFF10B981),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.15), // 15% padding
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to an icon if image fails to load
          return Icon(Icons.eco, color: Colors.white, size: size * 0.5);
        },
      ),
    );
  }
}
