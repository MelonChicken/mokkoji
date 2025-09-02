import 'package:flutter/material.dart';

class OffsetDropdown extends StatelessWidget {
  const OffsetDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value; // minutes
  final ValueChanged<int> onChanged;

  static const List<int> options = [5, 10, 15, 30, 60, 1440];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<int>(
        value: options.contains(value) ? value : 15,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          isDense: true,
        ),
        items: options.map((minutes) {
          return DropdownMenuItem<int>(
            value: minutes,
            child: Text(_formatOffset(minutes)),
          );
        }).toList(),
        onChanged: (int? newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }

  String _formatOffset(int minutes) {
    if (minutes == 1440) return '1일 전';
    if (minutes >= 60) return '${minutes ~/ 60}시간 전';
    return '$minutes분 전';
  }
}