import 'package:flutter/material.dart';

class AvatarStack extends StatelessWidget {
  final List<String> avatarUrls;
  final int maxVisible;
  final double size;

  const AvatarStack({
    super.key,
    required this.avatarUrls,
    this.maxVisible = 5,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayCount = avatarUrls.length > maxVisible ? maxVisible : avatarUrls.length;
    final remainingCount = avatarUrls.length - maxVisible;
    final overlapOffset = size - 6; // 6px 오버랩
    
    return SizedBox(
      height: size,
      width: displayCount > 0 
          ? (displayCount - 1) * overlapOffset + size + (remainingCount > 0 ? overlapOffset : 0)
          : size,
      child: Stack(
        children: [
          // 일반 아바타들
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * overlapOffset,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: (size - 4) / 2, // 보더 두께 고려
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    avatarUrls[i].substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          
          // +N 배지 (초과 인원)
          if (remainingCount > 0)
            Positioned(
              left: displayCount * overlapOffset,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.secondary,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: TextStyle(
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}