import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum SourceType { kakao, naver, google }

class SourceChip extends StatelessWidget {
  final SourceType type;
  const SourceChip({super.key, required this.type});

  String get _label => switch (type) {
        SourceType.kakao => 'Kakao',
        SourceType.naver => 'Naver',
        SourceType.google => 'Google',
      };

  Color get _color => switch (type) {
        SourceType.kakao => const Color(0xFFFFDC00), // Kakao yellow
        SourceType.naver => const Color(0xFF22C55E), // Naver green
        SourceType.google => const Color(0xFF3B82F6), // Google blue
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withOpacity(0.6)),
      ),
      child: Text(
        _label, 
        style: TextStyle(
          color: type == SourceType.kakao ? AppTokens.neutral900 : _color,
          fontSize: 12, 
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
