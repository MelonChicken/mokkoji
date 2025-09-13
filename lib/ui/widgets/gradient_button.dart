import 'package:flutter/material.dart';
import '../../theme/mokkoji_colors.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderRadius = 28.0,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool enabled;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && onPressed != null;
    
    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? MokkojiColors.aqua600 : MokkojiColors.aqua200,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding,
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: MokkojiColors.onAqua,
                fontWeight: FontWeight.bold,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}