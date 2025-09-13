import 'package:flutter/material.dart';
import '../../../theme/mokkoji_colors.dart';

/// Time display block with date line, range line, and optional timezone note
class TimeBlock extends StatelessWidget {
  final String dateLine;
  final String rangeLine;
  final String? tzNote;
  final bool isCrossDay;
  final VoidCallback? onTap;

  const TimeBlock({
    super.key,
    required this.dateLine,
    required this.rangeLine,
    this.tzNote,
    this.isCrossDay = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCrossDay
              ? (isDark ? MokkojiColors.darkOrange50.withOpacity(0.5) : MokkojiColors.orange50.withOpacity(0.3))
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCrossDay
                ? (isDark ? MokkojiColors.orange300.withOpacity(0.7) : MokkojiColors.orange300)
                : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date line with cross-day indicator
            Row(
              children: [
                Expanded(
                  child: Text(
                    dateLine,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isCrossDay) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? MokkojiColors.darkOrange100 : MokkojiColors.orange100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '자정 넘김',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? MokkojiColors.orange300 : MokkojiColors.orange800,
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            
            // Range line
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  rangeLine,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            // Optional timezone note
            if (tzNote != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? MokkojiColors.darkBlue50.withOpacity(0.7)
                      : MokkojiColors.blue50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tzNote!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? MokkojiColors.blue300 : MokkojiColors.blue700,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}