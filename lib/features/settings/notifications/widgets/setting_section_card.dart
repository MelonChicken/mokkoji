import 'package:flutter/material.dart';
import '../../../../theme/tokens.dart';

class SettingSectionCard extends StatelessWidget {
  const SettingSectionCard({
    super.key,
    required this.leadingColor,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    this.child,
  });

  final Color leadingColor;
  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LeadingIcon(color: leadingColor, icon: leadingIcon),
                const SizedBox(width: 12),
                Expanded(child: _Header(title: title, subtitle: subtitle)),
                const SizedBox(width: 8),
                Semantics(
                  label: '$title 스위치, ${enabled ? "켜짐" : "꺼짐"}',
                  child: Switch(
                    value: enabled,
                    onChanged: onToggle,
                  ),
                ),
              ],
            ),
            if (enabled && child != null) ...[
              const SizedBox(height: 12),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({
    required this.color,
    required this.icon,
  });

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        size: 24,
        color: color,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}