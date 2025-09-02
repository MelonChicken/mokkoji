import 'package:flutter/material.dart';

class TimeDropdown extends StatelessWidget {
  const TimeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value; // '08:00' 24h format
  final ValueChanged<String> onChanged;

  static const List<String> presets = [
    '06:00',
    '07:00',
    '08:00',
    '09:00',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: presets.contains(value) ? value : null,
        hint: Text(_formatTime(value)),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          isDense: true,
        ),
        items: presets.map((timeValue) {
          return DropdownMenuItem<String>(
            value: timeValue,
            child: Text(_formatTime(timeValue)),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }

  String _formatTime(String timeValue) {
    final parts = timeValue.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    final isAM = hour < 12;
    final displayHour = ((hour + 11) % 12) + 1;
    final minuteStr = minute.toString().padLeft(2, '0');
    
    final period = isAM ? '오전' : '오후';
    final minuteDisplay = minute == 0 ? '' : ' ${minuteStr}분';
    
    return '$period $displayHour시$minuteDisplay';
  }
}