import 'package:flutter/material.dart';
import '../../theme/mokkoji_colors.dart';

class FieldCard extends StatelessWidget {
  const FieldCard({
    super.key,
    required this.child,
    this.label,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final String? label;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor ?? MokkojiColors.aqua50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor ?? MokkojiColors.aqua200,
              width: 1,
            ),
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ],
    );
  }
}