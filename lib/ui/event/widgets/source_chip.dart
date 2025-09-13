import 'package:flutter/material.dart';
import '../../../theme/mokkoji_colors.dart';

/// Source platform chip with platform-specific styling
class SourceChip extends StatelessWidget {
  final String source;
  final bool isActive;
  final VoidCallback? onTap;

  const SourceChip({
    super.key,
    required this.source,
    this.isActive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (backgroundColor, textColor) = _getSourceColors(source, isActive, colorScheme, context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: backgroundColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSourceIcon(source, textColor),
            const SizedBox(width: 4),
            Text(
              source,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get platform-specific colors
  (Color backgroundColor, Color textColor) _getSourceColors(
    String source,
    bool isActive,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!isActive) {
      return (
        colorScheme.surfaceContainerHigh,
        colorScheme.onSurfaceVariant,
      );
    }

    switch (source.toLowerCase()) {
      case '구글':
      case 'google':
        return isDark
          ? (MokkojiColors.darkBlue100, MokkojiColors.darkGray800)
          : (MokkojiColors.blue100, MokkojiColors.blue800);
      case '네이버':
      case 'naver':
        return isDark
          ? (MokkojiColors.green100.withOpacity(0.3), MokkojiColors.green100)
          : (MokkojiColors.green100, MokkojiColors.green800);
      case '카카오':
      case 'kakao':
        return isDark
          ? (const Color(0xFF4A3B1A), const Color(0xFFF4E17A))
          : (const Color(0xFFFFF3CD), const Color(0xFF7D6608));
      case '내부':
      case 'internal':
        return isDark
          ? (MokkojiColors.darkGray100, MokkojiColors.darkGray800)
          : (MokkojiColors.gray100, MokkojiColors.gray800);
      default:
        return (colorScheme.primaryContainer, colorScheme.onPrimaryContainer);
    }
  }

  /// Build platform-specific icon
  Widget _buildSourceIcon(String source, Color color) {
    IconData iconData;
    
    switch (source.toLowerCase()) {
      case '구글':
      case 'google':
        iconData = Icons.g_mobiledata;
        break;
      case '네이버':
      case 'naver':
        iconData = Icons.circle;
        break;
      case '카카오':
      case 'kakao':
        iconData = Icons.chat;
        break;
      case '내부':
      case 'internal':
        iconData = Icons.smartphone;
        break;
      default:
        iconData = Icons.source;
    }
    
    return Icon(
      iconData,
      size: 14,
      color: color,
    );
  }
}