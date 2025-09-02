import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'source_chip.dart';

class EventCard extends StatelessWidget {
  final String time;
  final Widget title;
  final String place;
  final SourceType source;
  final VoidCallback? onOpen;
  final VoidCallback? onNavigate;

  const EventCard({
    super.key,
    required this.time,
    required this.title,
    required this.place,
    required this.source,
    this.onOpen,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.s8),
      padding: const EdgeInsets.all(AppTokens.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        boxShadow: Theme.of(context).brightness == Brightness.light ? AppTokens.e1 : null,
        border: Theme.of(context).brightness == Brightness.dark
            ? const Border.fromBorderSide(BorderSide(color: Color(0xFF273244), width: 1))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                time, 
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SourceChip(type: source),
            ],
          ),
          const SizedBox(height: AppTokens.s8),
          DefaultTextStyle(
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ) ?? const TextStyle(),
            child: title,
          ),
          const SizedBox(height: AppTokens.s4),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 18),
              const SizedBox(width: 4),
              Expanded(child: Text(place, style: textTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          Row(
            children: [
              TextButton(
                onPressed: onOpen,
                child: const Text('열기'),
              ),
              const SizedBox(width: AppTokens.s8),
              FilledButton(
                onPressed: onNavigate,
                child: const Text('길찾기'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
