import 'package:flutter/material.dart';

/// TodaySummaryCard의 높이 계산 유틸리티
class TodaySummaryLayout {
  /// 카드 내용에 따른 필요 높이 계산
  static double computeHeight(
    BuildContext context, {
    required bool hasNext,
    required bool showSyncChip,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaler.scale(1.0).clamp(1.0, 1.3);
    
    double height = 0;
    
    // 상하 패딩
    height += 24; // 12 * 2
    
    // 헤더 라인 ("오늘의 일정 N건" + 오프라인 칩)
    final headerLineHeight = (textTheme.titleMedium?.height ?? 1.2) * 
                            (textTheme.titleMedium?.fontSize ?? 16) * 
                            textScaleFactor;
    height += headerLineHeight + 8; // 헤더 + 여백
    
    // 다음 일정 정보 (있을 때)
    if (hasNext) {
      // 시각 라벨 높이
      final timeHeight = (textTheme.titleSmall?.height ?? 1.2) * 
                        (textTheme.titleSmall?.fontSize ?? 14) * 
                        textScaleFactor;
      // 제목 높이  
      final titleHeight = (textTheme.bodyMedium?.height ?? 1.4) * 
                         (textTheme.bodyMedium?.fontSize ?? 14) * 
                         textScaleFactor;
      // 위치 높이 (선택적)
      final locationHeight = (textTheme.bodySmall?.height ?? 1.2) * 
                            (textTheme.bodySmall?.fontSize ?? 12) * 
                            textScaleFactor;
      
      final nextEventHeight = [timeHeight, titleHeight + locationHeight + 4].reduce((a, b) => a > b ? a : b);
      height += nextEventHeight + 12 + 16; // 컨테이너 패딩 + 여백
    }
    
    // 버튼 행 (자세히, 지금으로)
    const buttonHeight = 36.0; // FilledButton 기본 높이
    height += buttonHeight + 16; // 버튼 + 상단 여백
    
    // 마지막 동기화 시각 라벨
    final syncLabelHeight = (textTheme.labelSmall?.height ?? 1.2) * 
                           (textTheme.labelSmall?.fontSize ?? 11) * 
                           textScaleFactor;
    height += syncLabelHeight + 8; // 라벨 + 상단 여백
    
    return height;
  }
}